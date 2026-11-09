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

export async function send(
    baseUrl: string,
    method: string,
    route: string,
    headers: Record<string, string>,
    body?: unknown,
): Promise<Response> {
    return await fetchBounded(`${baseUrl}${route}`, {
        method,
        headers: body === undefined ? headers : jsonHeaders(headers),
        body: body === undefined ? undefined : JSON.stringify(body),
    });
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
