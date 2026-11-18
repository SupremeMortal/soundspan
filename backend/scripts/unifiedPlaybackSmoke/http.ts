import { io, type Socket } from "socket.io-client";
import {
    assertSmoke,
    bearer,
    expectJson,
    fetchBounded,
} from "../backupRestoreSmoke/support";

export function jsonHeaders(
    headers: Record<string, string> = {},
): Record<string, string> {
    return { "Content-Type": "application/json", ...headers };
}

/**
 * Fails the run when the backend's response validation replaced a body with
 * `RESPONSE_SCHEMA_MISMATCH`, naming the request that drifted from its schema.
 */
export async function assertNoSchemaMismatch(
    method: string,
    route: string,
    response: Response,
): Promise<void> {
    const type = response.headers.get("content-type") ?? "";
    if (!type.includes("application/json")) return;
    const body: unknown = await response
        .clone()
        .json()
        .catch(() => null);
    const code =
        body !== null && typeof body === "object"
            ? (body as Record<string, unknown>).code
            : undefined;
    assertSmoke(
        code !== "RESPONSE_SCHEMA_MISMATCH",
        `${method} ${route} failed response validation: ${JSON.stringify(body)}`,
    );
}

export async function send(
    baseUrl: string,
    method: string,
    route: string,
    headers: Record<string, string>,
    body?: unknown,
): Promise<Response> {
    const response = await fetchBounded(`${baseUrl}${route}`, {
        method,
        headers: body === undefined ? headers : jsonHeaders(headers),
        body: body === undefined ? undefined : JSON.stringify(body),
    });
    await assertNoSchemaMismatch(method, route, response);
    return response;
}

export async function sendJson(
    baseUrl: string,
    method: string,
    route: string,
    headers: Record<string, string>,
    body: unknown,
    expectedStatus = 200,
): Promise<Record<string, unknown>> {
    return await expectJson(
        await send(baseUrl, method, route, headers, body),
        expectedStatus,
    );
}

export function asArray(value: unknown, label: string): unknown[] {
    assertSmoke(Array.isArray(value), `${label} is not an array`);
    return value;
}

export function asRecord(
    value: unknown,
    label: string,
): Record<string, unknown> {
    assertSmoke(
        value !== null && typeof value === "object" && !Array.isArray(value),
        `${label} is not an object`,
    );
    return value as Record<string, unknown>;
}

export interface Credentials {
    jwt: string;
    apiKey: string;
    apiKeyId: string;
}

export const bearerHeaders = bearer;

/** Opens a Listen Together socket authenticated with `apiKey`. */
export function connectSocket(
    baseUrl: string,
    apiKey: string,
): Promise<Socket> {
    return new Promise((resolve, reject) => {
        const socket = io(`${baseUrl}/listen-together`, {
            path: "/socket.io/listen-together",
            auth: { apiKey },
            transports: ["websocket"],
            reconnection: false,
            timeout: 15_000,
        });
        socket.once("connect", () => resolve(socket));
        socket.once("connect_error", (error) => {
            socket.close();
            reject(error);
        });
    });
}
