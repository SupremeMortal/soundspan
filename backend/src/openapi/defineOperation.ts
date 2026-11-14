import { z } from "zod";

/** Tags of the client surface; each becomes one generated client class. */
export const CLIENT_SURFACE_TAGS = [
    "session",
    "library",
    "playlists",
    "search",
    "playback",
    "offline",
    "podcasts",
    "discovery",
    "listenTogether",
    "social",
] as const;

export type ClientSurfaceTag = (typeof CLIENT_SURFACE_TAGS)[number];

export type HttpMethod = "get" | "post" | "put" | "delete";

/** A non-JSON response declared by media type only (streams, cover art). */
export interface BinaryResponse {
    binary: string;
}

/**
 * The body declared for one status: a zod schema (`application/json`), a
 * binary media type, or `null` for a status with no body.
 */
export type ResponseBody = z.ZodType | BinaryResponse | null;

export type ObjectSchema = z.ZodObject<z.ZodRawShape>;

/** Input to {@link defineOperation}. */
export interface OperationSpec {
    method: HttpMethod;
    /** Mounted path with OpenAPI braces, e.g. `/api/library/albums/{id}`. */
    path: string;
    /** Unique camelCase identifier; becomes the generated method name. */
    operationId: string;
    tag: ClientSurfaceTag;
    /** One line. */
    summary: string;
    /** Rules JSON Schema cannot express (cross-field checks). */
    description?: string;
    /** Emits `security: []`. */
    anonymous?: true;
    params?: ObjectSchema;
    query?: ObjectSchema;
    body?: z.ZodType;
    responses: Partial<Record<number, ResponseBody>>;
}

/** A validated client-surface operation. */
export type ClientSurfaceOperation = Readonly<OperationSpec>;

const OPERATION_ID = /^[a-z][a-zA-Z0-9]*$/;
const PATH_PARAMETER = /\{([^}]+)\}/g;

/** Names of the `{parameters}` in an OpenAPI path, in order. */
export function pathParameterNames(path: string): string[] {
    return Array.from(path.matchAll(PATH_PARAMETER), (match) => match[1]);
}

export function isBinaryResponse(value: unknown): value is BinaryResponse {
    return (
        typeof value === "object" &&
        value !== null &&
        !(value instanceof z.ZodType) &&
        typeof (value as { binary?: unknown }).binary === "string"
    );
}

export function isClientSurfaceTag(value: unknown): value is ClientSurfaceTag {
    return (CLIENT_SURFACE_TAGS as readonly unknown[]).includes(value);
}

function fail(spec: OperationSpec, message: string): never {
    throw new Error(
        `defineOperation(${spec.method.toUpperCase()} ${spec.path}): ${message}`,
    );
}

/**
 * Declares one client-surface operation, rejecting declarations that would
 * produce an incorrect or ambiguous OpenAPI description.
 */
export function defineOperation(spec: OperationSpec): ClientSurfaceOperation {
    if (!isClientSurfaceTag(spec.tag)) {
        fail(
            spec,
            `tag "${String(spec.tag)}" is not one of ${CLIENT_SURFACE_TAGS.join(", ")}`,
        );
    }
    if (!OPERATION_ID.test(spec.operationId)) {
        fail(spec, `operationId "${spec.operationId}" is not camelCase`);
    }
    if (!spec.path.startsWith("/api/")) {
        fail(spec, "path must start with /api/");
    }
    const inPath = pathParameterNames(spec.path);
    const inParams = Object.keys(spec.params?.shape ?? {});
    const missing = inPath.filter((name) => !inParams.includes(name));
    const extra = inParams.filter((name) => !inPath.includes(name));
    if (missing.length > 0) {
        fail(
            spec,
            `path parameters missing from params: ${missing.join(", ")}`,
        );
    }
    if (extra.length > 0) {
        fail(spec, `params not in the path: ${extra.join(", ")}`);
    }
    if (Object.keys(spec.responses).length === 0) {
        fail(spec, "responses must declare at least one status");
    }
    return Object.freeze({ ...spec });
}
