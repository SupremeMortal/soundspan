import { getOperation } from "../../../openapi/clientSurface";
import { checkClientSurfaceResponse } from "../../../openapi/responseValidation";

/** Anything with a status and a body, such as `createMockJsonResponse()`. */
export interface ResponseLike {
    statusCode: number;
    body: unknown;
}

/**
 * Throws a readable error when a response captured from a handler called
 * directly does not match the schema of client-surface operation
 * `operationId` for its status.
 */
export function expectClientSurfaceResponse(
    operationId: string,
    res: ResponseLike,
): void;
export function expectClientSurfaceResponse(
    operationId: string,
    status: number,
    body: unknown,
): void;
export function expectClientSurfaceResponse(
    operationId: string,
    resOrStatus: ResponseLike | number,
    body?: unknown,
): void {
    const status =
        typeof resOrStatus === "number" ? resOrStatus : resOrStatus.statusCode;
    const sent = typeof resOrStatus === "number" ? body : resOrStatus.body;
    const check = checkClientSurfaceResponse(
        getOperation(operationId),
        status,
        sent,
    );
    if (!check.ok) {
        throw new Error(
            `Response of ${operationId} with status ${status} does not match its schema at ${check.path}: ${check.message}`,
        );
    }
}

/** A handler as the route tests call it directly. */
type DirectHandler = (req: any, res: any, next?: any) => unknown;

/**
 * Wraps a handler called directly so every JSON body it sends through a
 * `createRes()`-style mock (`res.json` a `jest.fn`, `res.body` the payload) is
 * checked against the schema of client-surface operation `operationId`.
 */
export function withClientSurfaceValidation(
    operationId: string,
    handler: DirectHandler,
): DirectHandler {
    return async (req, res, next) => {
        const result = await handler(req, res, next ?? (() => undefined));
        if ((res?.json?.mock?.calls?.length ?? 0) > 0) {
            expectClientSurfaceResponse(operationId, res);
        }
        return result;
    };
}
