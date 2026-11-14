import { STATUS_CODES } from "node:http";
import { z } from "zod";
import {
    isBinaryResponse,
    type ClientSurfaceOperation,
} from "./defineOperation";
import { pathShape } from "./expressPath";

type JsonSchema = Record<string, unknown>;
type JsonRecord = Record<string, unknown>;

/** The OpenAPI fragment produced from a client surface. */
export interface ClientSurfaceDocument {
    paths: Record<string, Record<string, JsonRecord>>;
    components: { schemas: Record<string, JsonSchema> };
}

const COMPONENT_PREFIX = "#/components/schemas/";
const DEFINITION_PREFIX = "#/definitions/";

function isRecord(value: unknown): value is JsonRecord {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}

function rewriteRefs(value: unknown): unknown {
    if (Array.isArray(value)) return value.map(rewriteRefs);
    if (!isRecord(value)) return value;
    const out: JsonRecord = {};
    for (const [key, child] of Object.entries(value)) {
        out[key] =
            key === "$ref" &&
            typeof child === "string" &&
            child.startsWith(DEFINITION_PREFIX)
                ? COMPONENT_PREFIX + child.slice(DEFINITION_PREFIX.length)
                : rewriteRefs(child);
    }
    return out;
}

/**
 * Converts every schema in one zod 4 `toJSONSchema` pass so a component id
 * shared by two different schemas is rejected, and hoists named schemas.
 */
function convertAll(
    schemas: z.ZodType[],
    io: "input" | "output",
    components: Map<string, JsonSchema>,
): JsonSchema[] {
    if (schemas.length === 0) return [];
    const shape: Record<string, z.ZodType> = {};
    schemas.forEach((schema, index) => {
        shape[`s${index}`] = schema;
    });
    const converted = rewriteRefs(
        z.toJSONSchema(z.object(shape), { target: "openapi-3.0", io }),
    ) as JsonRecord;
    const definitions = (converted.definitions ?? {}) as Record<
        string,
        JsonSchema
    >;
    for (const [id, schema] of Object.entries(definitions)) {
        const existing = components.get(id);
        if (existing && JSON.stringify(existing) !== JSON.stringify(schema)) {
            throw new Error(
                `Component "${id}" converts differently as a request and as a response; give each form its own id`,
            );
        }
        components.set(id, schema);
    }
    const properties = converted.properties as Record<string, JsonSchema>;
    return schemas.map((_schema, index) => properties[`s${index}`]);
}

function resolveSchema(
    schema: JsonSchema,
    components: Map<string, JsonSchema>,
): JsonSchema {
    const ref = schema.$ref;
    if (typeof ref === "string" && ref.startsWith(COMPONENT_PREFIX)) {
        return components.get(ref.slice(COMPONENT_PREFIX.length)) ?? schema;
    }
    return schema;
}

function toParameters(
    schema: JsonSchema,
    location: "path" | "query",
    components: Map<string, JsonSchema>,
): JsonRecord[] {
    const resolved = resolveSchema(schema, components);
    const properties = (resolved.properties ?? {}) as Record<
        string,
        JsonSchema
    >;
    const required = (resolved.required ?? []) as string[];
    return Object.entries(properties).map(([name, property]) => ({
        name,
        in: location,
        required: location === "path" || required.includes(name),
        schema: property,
    }));
}

function statusDescription(status: string): string {
    return STATUS_CODES[Number(status)] ?? "Response";
}

/**
 * Builds the OpenAPI path items and component schemas for `operations`.
 * Requests convert in zod's input mode, responses in output mode.
 */
export function buildClientSurfaceDocument(
    operations: readonly ClientSurfaceOperation[],
): ClientSurfaceDocument {
    const components = new Map<string, JsonSchema>();

    const inputSchemas: z.ZodType[] = [];
    const outputSchemas: z.ZodType[] = [];
    const inputIndex = (schema: z.ZodType | undefined) =>
        schema ? inputSchemas.push(schema) - 1 : -1;
    const plans = operations.map((operation) => ({
        params: inputIndex(operation.params),
        query: inputIndex(operation.query),
        body: inputIndex(operation.body),
        responses: Object.entries(operation.responses).map(([status, body]) => {
            if (body instanceof z.ZodType) {
                return { status, body, json: outputSchemas.push(body) - 1 };
            }
            return { status, body, json: -1 };
        }),
    }));
    const inputs = convertAll(inputSchemas, "input", components);
    const outputs = convertAll(outputSchemas, "output", components);

    const paths: ClientSurfaceDocument["paths"] = {};
    operations.forEach((operation, index) => {
        const plan = plans[index];
        const entry: JsonRecord = {
            operationId: operation.operationId,
            tags: [operation.tag],
            summary: operation.summary,
        };
        if (operation.description) entry.description = operation.description;
        if (operation.anonymous) entry.security = [];
        const parameters = [
            ...(plan.params >= 0
                ? toParameters(inputs[plan.params], "path", components)
                : []),
            ...(plan.query >= 0
                ? toParameters(inputs[plan.query], "query", components)
                : []),
        ];
        if (parameters.length > 0) entry.parameters = parameters;
        if (plan.body >= 0) {
            entry.requestBody = {
                required: !operation.body?.safeParse(undefined).success,
                content: { "application/json": { schema: inputs[plan.body] } },
            };
        }
        const responses: JsonRecord = {};
        for (const { status, body, json } of plan.responses) {
            const response: JsonRecord = {
                description: statusDescription(status),
            };
            if (json >= 0) {
                response.content = {
                    "application/json": { schema: outputs[json] },
                };
            } else if (isBinaryResponse(body)) {
                response.content = { [body.binary]: {} };
            }
            responses[status] = response;
        }
        entry.responses = responses;
        paths[operation.path] = {
            ...paths[operation.path],
            [operation.method]: entry,
        };
    });

    const schemas: Record<string, JsonSchema> = {};
    for (const id of [...components.keys()].sort()) {
        schemas[id] = components.get(id) as JsonSchema;
    }
    return { paths, components: { schemas } };
}

/**
 * Returns `document` with the registered operations written over its
 * comment-derived operations and their component schemas added. `document`
 * is not modified.
 */
export function mergeClientSurface<T extends object>(
    document: T,
    operations: readonly ClientSurfaceOperation[],
): T {
    if (operations.length === 0) return document;
    const surface = buildClientSurfaceDocument(operations);
    const source = document as JsonRecord;

    const paths: JsonRecord = {
        ...(isRecord(source.paths) ? source.paths : {}),
    };
    for (const [path, item] of Object.entries(surface.paths)) {
        const existing = isRecord(paths[path]) ? paths[path] : {};
        paths[path] = { ...existing, ...item };
    }

    const components: JsonRecord = {
        ...(isRecord(source.components) ? source.components : {}),
    };
    const schemas: JsonRecord = {
        ...(isRecord(components.schemas) ? components.schemas : {}),
    };
    for (const [id, schema] of Object.entries(surface.components.schemas)) {
        if (
            id in schemas &&
            JSON.stringify(schemas[id]) !== JSON.stringify(schema)
        ) {
            throw new Error(
                `Registered component "${id}" clashes with a comment-described component of the same name`,
            );
        }
        schemas[id] = schema;
    }
    components.schemas = schemas;

    return { ...source, paths, components } as T;
}

/**
 * Lists registered operations (`METHOD /path`) that also have an `@openapi`
 * comment in `commentDocument`, compared by path shape.
 */
export function findDuplicateDescriptions(
    commentDocument: object,
    operations: readonly ClientSurfaceOperation[],
): string[] {
    const paths = (commentDocument as JsonRecord).paths;
    if (!isRecord(paths)) return [];
    return operations
        .filter((operation) =>
            Object.entries(paths).some(
                ([path, item]) =>
                    pathShape(path) === pathShape(operation.path) &&
                    isRecord(item) &&
                    operation.method in item,
            ),
        )
        .map(
            (operation) =>
                `${operation.method.toUpperCase()} ${operation.path}`,
        );
}
