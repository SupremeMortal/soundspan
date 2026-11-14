import { z } from "zod";
import {
    CLIENT_SURFACE_TAGS,
    isBinaryResponse,
    isClientSurfaceTag,
    type ClientSurfaceOperation,
} from "./defineOperation";
import { buildClientSurfaceDocument } from "./document";
import { sessionOperations } from "./operations/session";

export type { ClientSurfaceOperation } from "./defineOperation";

/** A list of client-surface operations. */
export type ClientSurface = readonly ClientSurfaceOperation[];

/** Builds a surface from `operations`; tests use it for fixture surfaces. */
export function createClientSurface(
    operations: readonly ClientSurfaceOperation[],
): ClientSurface {
    return Object.freeze([...operations]);
}

/** Every registered operation: the arrays exported by `operations/*.ts`. */
export const clientSurfaceOperations: ClientSurface = createClientSurface([
    ...sessionOperations,
]);

/** The registered operation with `operationId`; throws when there is none. */
export function getOperation(operationId: string): ClientSurfaceOperation {
    const operation = clientSurfaceOperations.find(
        (candidate) => candidate.operationId === operationId,
    );
    if (!operation) {
        throw new Error(`No client-surface operation "${operationId}"`);
    }
    return operation;
}

/** operationIds declared more than once. */
export function findDuplicateOperationIds(surface: ClientSurface): string[] {
    const seen = new Set<string>();
    const duplicates = new Set<string>();
    for (const { operationId } of surface) {
        if (seen.has(operationId)) duplicates.add(operationId);
        seen.add(operationId);
    }
    return [...duplicates];
}

/**
 * Operations with a tag outside {@link CLIENT_SURFACE_TAGS}, no statuses, or a
 * status whose value is not a schema, a binary marker or `null`.
 */
export function findInvalidOperations(surface: ClientSurface): string[] {
    const problems: string[] = [];
    for (const operation of surface) {
        const name = operation.operationId;
        if (!isClientSurfaceTag(operation.tag)) {
            problems.push(
                `${name}: tag "${String(operation.tag)}" is not one of ${CLIENT_SURFACE_TAGS.join(", ")}`,
            );
        }
        const entries = Object.entries(operation.responses);
        if (entries.length === 0) problems.push(`${name}: no responses`);
        for (const [status, body] of entries) {
            if (
                body !== null &&
                !(body instanceof z.ZodType) &&
                !isBinaryResponse(body)
            ) {
                problems.push(
                    `${name}: status ${status} has no schema, binary marker or null`,
                );
            }
        }
    }
    return problems;
}

function isUntyped(schema: Record<string, unknown>): boolean {
    if ("$ref" in schema) return false;
    const composite = ["type", "enum", "anyOf", "oneOf", "allOf", "not"];
    if (!composite.some((key) => key in schema)) return true;
    if (schema.type !== "object") return false;
    const properties = schema.properties as Record<string, unknown> | undefined;
    const additional = schema.additionalProperties;
    const typedAdditional =
        typeof additional === "object" &&
        additional !== null &&
        !isUntyped(additional as Record<string, unknown>);
    return (
        (!properties || Object.keys(properties).length === 0) &&
        !typedAdditional
    );
}

function untypedLocations(value: unknown, at: string, out: string[]): void {
    if (Array.isArray(value)) {
        value.forEach((child, index) =>
            untypedLocations(child, `${at}[${index}]`, out),
        );
        return;
    }
    if (typeof value !== "object" || value === null) return;
    const schema = value as Record<string, unknown>;
    if (isUntyped(schema)) {
        out.push(at);
        return;
    }
    for (const key of ["properties", "definitions"]) {
        const children = schema[key];
        if (typeof children === "object" && children !== null) {
            for (const [name, child] of Object.entries(children)) {
                untypedLocations(child, `${at}.${name}`, out);
            }
        }
    }
    for (const key of ["items", "additionalProperties", "not"]) {
        const child = schema[key];
        if (typeof child === "object" && child !== null) {
            untypedLocations(child, `${at}.${key}`, out);
        }
    }
    for (const key of ["anyOf", "oneOf", "allOf"]) {
        if (Array.isArray(schema[key])) {
            untypedLocations(schema[key], `${at}.${key}`, out);
        }
    }
}

/**
 * Locations of untyped schemas (`z.any`, `z.unknown`, an empty object, a
 * record of unknown) in the surface's requests, responses and components.
 */
export function findUntypedSchemas(surface: ClientSurface): string[] {
    const document = buildClientSurfaceDocument(surface);
    const out: string[] = [];
    for (const [id, schema] of Object.entries(document.components.schemas)) {
        untypedLocations(schema, `component ${id}`, out);
    }
    for (const operation of surface) {
        const entry = document.paths[operation.path][operation.method] as {
            parameters?: { name: string; schema: unknown }[];
            requestBody?: { content: Record<string, { schema?: unknown }> };
            responses: Record<
                string,
                { content?: Record<string, { schema?: unknown }> }
            >;
        };
        const name = operation.operationId;
        for (const parameter of entry.parameters ?? []) {
            untypedLocations(
                parameter.schema,
                `${name} parameter ${parameter.name}`,
                out,
            );
        }
        const body = entry.requestBody?.content["application/json"]?.schema;
        if (body) untypedLocations(body, `${name} request body`, out);
        for (const [status, response] of Object.entries(entry.responses)) {
            const schema = response.content?.["application/json"]?.schema;
            if (schema)
                untypedLocations(schema, `${name} ${status} response`, out);
        }
    }
    return out;
}
