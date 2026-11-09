import { prisma } from "../utils/db";
import { logger } from "../utils/logger";
import { findApiKeyRecord, isApiKeyExpired } from "../utils/apiKeyHash";

const log = logger.child("ListenTogether/ApiKeyAuth");

/** Raw API keys are 64 hex characters; anything far outside that is malformed. */
const MAX_API_KEY_LENGTH = 256;

/** Client-safe handshake rejection; any other error is reported generically. */
export class SocketApiKeyAuthError extends Error {}

/** User and credential identity resolved from a socket handshake API key. */
export interface SocketApiKeyIdentity {
    userId: string;
    username: string;
    apiKeyId: string;
}

/**
 * Resolve `handshake.auth.apiKey` to its owning user, applying the same rules
 * as `X-API-Key` HTTP authentication: hashed lookup via `findApiKeyRecord`,
 * lifetime check via `isApiKeyExpired`, and an async last-used update. Users
 * marked for deletion are rejected, as on the JWT handshake path.
 *
 * Throws `SocketApiKeyAuthError` for rejections; lookup failures propagate as-is.
 */
export async function authenticateSocketApiKey(
    apiKey: unknown,
): Promise<SocketApiKeyIdentity> {
    if (
        typeof apiKey !== "string" ||
        apiKey.length === 0 ||
        apiKey.length > MAX_API_KEY_LENGTH
    ) {
        throw new SocketApiKeyAuthError("Invalid API key");
    }
    const record = await findApiKeyRecord(apiKey, (key) =>
        prisma.apiKey.findUnique({
            where: { key },
            include: {
                user: {
                    select: {
                        id: true,
                        username: true,
                        pendingDeletionAt: true,
                    },
                },
            },
        }),
    );
    if (!record || !record.user || isApiKeyExpired(record.createdAt)) {
        throw new SocketApiKeyAuthError("Invalid API key");
    }
    if (record.user.pendingDeletionAt) {
        throw new SocketApiKeyAuthError("User deletion is pending");
    }
    prisma.apiKey
        .update({ where: { id: record.id }, data: { lastUsed: new Date() } })
        .catch((err: unknown) => {
            log.debug("Failed to update API key lastUsed", err);
        });
    return {
        userId: record.user.id,
        username: record.user.username,
        apiKeyId: record.id,
    };
}

/**
 * Handshake adapter: returns the `socket.data` for an API-key socket, or throws
 * an `Error` whose message is safe to send to the client (unexpected failures
 * such as database errors are reported as `Invalid API key`).
 */
export async function resolveApiKeySocketData(apiKey: unknown): Promise<{
    userId: string;
    username: string;
    groupId: null;
    apiKeyId: string;
}> {
    try {
        const identity = await authenticateSocketApiKey(apiKey);
        return { ...identity, groupId: null };
    } catch (error) {
        if (error instanceof SocketApiKeyAuthError) throw error;
        log.warn("API key socket authentication failed", error);
        throw new Error("Invalid API key");
    }
}
