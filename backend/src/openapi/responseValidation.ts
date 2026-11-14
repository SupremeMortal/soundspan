import type { Request, RequestHandler, Response } from "express";
import { z } from "zod";
import {
    isBinaryResponse,
    pathParameterNames,
    type ClientSurfaceOperation,
} from "./defineOperation";
import { pathShape, toOpenApiPaths } from "./expressPath";

/** The result of checking one response body against its operation. */
export type ResponseCheck =
    | { ok: true }
    | { ok: false; path: string; message: string };

/** Thrown by the `throw` mode of {@link validateClientSurfaceResponses}. */
export class ResponseSchemaMismatchError extends Error {
    readonly operationId: string;
    readonly status: number;
    readonly path: string;

    constructor(
        operationId: string,
        status: number,
        path: string,
        detail: string,
    ) {
        super(
            `Response of ${operationId} with status ${status} does not match its schema at ${path}: ${detail}`,
        );
        this.name = "ResponseSchemaMismatchError";
        this.operationId = operationId;
        this.status = status;
        this.path = path;
    }
}

function formatIssuePath(path: readonly PropertyKey[]): string {
    return path.reduce<string>(
        (out, key) =>
            typeof key === "number"
                ? `${out}[${key}]`
                : `${out}.${String(key)}`,
        "$",
    );
}

function serialise(body: unknown): unknown {
    const text = JSON.stringify(body);
    return text === undefined ? undefined : JSON.parse(text);
}

/**
 * Checks `body`, as it would be serialised to JSON, against the schema the
 * operation declares for `status`. An undeclared status fails at `$status`;
 * a status declared as `null` or binary is not checked.
 */
export function checkClientSurfaceResponse(
    operation: ClientSurfaceOperation,
    status: number,
    body: unknown,
): ResponseCheck {
    if (!Object.prototype.hasOwnProperty.call(operation.responses, status)) {
        return {
            ok: false,
            path: "$status",
            message: `status ${status} is not declared`,
        };
    }
    const declared = operation.responses[status];
    if (declared === null || declared === undefined) return { ok: true };
    if (isBinaryResponse(declared)) return { ok: true };
    const result = (declared as z.ZodType).safeParse(serialise(body));
    if (result.success) return { ok: true };
    const issue = result.error.issues[0];
    return {
        ok: false,
        path: formatIssuePath(issue.path),
        message: issue.message,
    };
}

interface Template {
    operation: ClientSurfaceOperation;
    pattern: RegExp;
    parameters: number;
}

function escapeRegExp(text: string): string {
    return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function toTemplate(operation: ClientSurfaceOperation): Template {
    const source = operation.path
        .split(/\{[^}]+\}/)
        .map(escapeRegExp)
        .join("[^/]+");
    return {
        operation,
        pattern: new RegExp(`^${source}/?$`),
        parameters: pathParameterNames(operation.path).length,
    };
}

function createResolver(operations: readonly ClientSurfaceOperation[]) {
    const byShape = new Map<string, ClientSurfaceOperation>();
    for (const operation of operations) {
        byShape.set(
            `${operation.method} ${pathShape(operation.path)}`,
            operation,
        );
    }
    const templates = operations
        .map(toTemplate)
        .sort((a, b) => a.parameters - b.parameters);

    return (req: Request): ClientSurfaceOperation | undefined => {
        const method = req.method.toLowerCase();
        const routePath: unknown = req.route?.path;
        if (req.route) {
            if (typeof routePath !== "string") return undefined;
            for (const path of toOpenApiPaths(req.baseUrl + routePath)) {
                const match = byShape.get(`${method} ${pathShape(path)}`);
                if (match) return match;
            }
            return undefined;
        }
        const requestPath = (req.originalUrl || req.url).split("?")[0];
        return templates.find(
            ({ operation, pattern }) =>
                operation.method === method && pattern.test(requestPath),
        )?.operation;
    };
}

/** Options of {@link validateClientSurfaceResponses}. */
export interface ResponseValidationOptions {
    operations: readonly ClientSurfaceOperation[];
    /**
     * `respond` replaces a mismatching body with a 500
     * `RESPONSE_SCHEMA_MISMATCH` error; `throw` throws
     * {@link ResponseSchemaMismatchError}.
     */
    onMismatch: "respond" | "throw";
}

/**
 * Express middleware that wraps `res.json` and checks each body sent for a
 * registered operation against the schema declared for its status. Requests
 * that match no registered operation, streams and `res.send` text bodies are
 * left untouched.
 */
export function validateClientSurfaceResponses({
    operations,
    onMismatch,
}: ResponseValidationOptions): RequestHandler {
    if (operations.length === 0) {
        return (_req, _res, next) => next();
    }
    const resolve = createResolver(operations);
    return (req, res, next) => {
        const json = res.json.bind(res) as Response["json"];
        res.json = function validatedJson(body?: unknown) {
            const operation = resolve(req);
            if (!operation) return json(body);
            const check = checkClientSurfaceResponse(
                operation,
                res.statusCode,
                body,
            );
            if (check.ok) return json(body);
            if (onMismatch === "throw") {
                throw new ResponseSchemaMismatchError(
                    operation.operationId,
                    res.statusCode,
                    check.path,
                    check.message,
                );
            }
            res.status(500);
            return json({
                error: "Response does not match its schema",
                code: "RESPONSE_SCHEMA_MISMATCH",
                operationId: operation.operationId,
                path: check.path,
            });
        };
        next();
    };
}
