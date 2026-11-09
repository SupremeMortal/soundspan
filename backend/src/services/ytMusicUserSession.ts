/**
 * Per-user YouTube Music OAuth session state: a short-lived cache of whether
 * the sidecar holds the user's session, lazy restore from the stored
 * credential, and the persist, poll and clear operations that keep them
 * consistent. Shared by the YouTube Music routes and the YT Music stream
 * service.
 */

import { prisma } from "../utils/db";
import { encrypt, decrypt } from "../utils/encryption";
import { coalesceInFlightByKey } from "../utils/singleflight";
import { config } from "../config";
import { logger } from "../utils/logger";
import { getSystemSettings } from "../utils/systemSettings";
import { ytMusicService } from "./youtubeMusic";
import type { YtMusicDeviceCodePollResult } from "./youtubeMusic";

const OAUTH_CACHE_TTL_MS = config.nodeEnv === "test" ? 0 : 60_000;
const OAUTH_NEGATIVE_CACHE_TTL_MS = config.nodeEnv === "test" ? 0 : 15_000;

export function getHttpErrorStatus(error: unknown): number | undefined {
    if (typeof error !== "object" || error === null || !("response" in error)) {
        return undefined;
    }
    const response = error.response;
    if (
        typeof response !== "object" ||
        response === null ||
        !("status" in response)
    ) {
        return undefined;
    }
    return typeof response.status === "number" ? response.status : undefined;
}
const ytOauthSessionCache = new Map<
    string,
    { authenticated: boolean; expiresAt: number }
>();
const ytOauthRestoreInFlight = new Map<string, Promise<boolean>>();
const ytOauthClearInFlight = new Map<string, Promise<void>>();
const ytOauthCredentialInFlight = new Map<string, Set<Promise<unknown>>>();
const ytOauthGeneration = new Map<string, number>();

export const setYtOAuthCache = (
    userId: string,
    authenticated: boolean,
    ttlMs = OAUTH_CACHE_TTL_MS,
) => {
    if (ttlMs <= 0) {
        ytOauthSessionCache.delete(userId);
        return;
    }
    if (!authenticated) {
        // Cache negative results with a shorter TTL so non-linked users
        // don't hit sidecar/DB on every browse/stream request, while still
        // picking up new OAuth links within a reasonable window.
        ytOauthSessionCache.set(userId, {
            authenticated: false,
            expiresAt: Date.now() + OAUTH_NEGATIVE_CACHE_TTL_MS,
        });
        return;
    }
    ytOauthSessionCache.set(userId, {
        authenticated,
        expiresAt: Date.now() + ttlMs,
    });
};

const getCachedYtOAuth = (userId: string): boolean | null => {
    const entry = ytOauthSessionCache.get(userId);
    if (!entry) return null;
    if (entry.expiresAt <= Date.now()) {
        ytOauthSessionCache.delete(userId);
        return null;
    }
    return entry.authenticated;
};

const invalidateYtOAuthGeneration = (userId: string): number => {
    const generation = (ytOauthGeneration.get(userId) ?? 0) + 1;
    ytOauthGeneration.set(userId, generation);
    ytOauthSessionCache.delete(userId);
    return generation;
};

const getYtOAuthGeneration = (userId: string): number =>
    ytOauthGeneration.get(userId) ?? 0;

const isCurrentYtOAuthGeneration = (
    userId: string,
    generation: number,
): boolean => getYtOAuthGeneration(userId) === generation;

function trackYtOAuthCredentialOperation<T>(
    userId: string,
    factory: () => Promise<T>,
): Promise<T> {
    const operations =
        ytOauthCredentialInFlight.get(userId) ?? new Set<Promise<unknown>>();
    ytOauthCredentialInFlight.set(userId, operations);

    let trackedOperation: Promise<T>;
    trackedOperation = Promise.resolve()
        .then(factory)
        .finally(() => {
            operations.delete(trackedOperation);
            if (operations.size === 0) {
                ytOauthCredentialInFlight.delete(userId);
            }
        });
    operations.add(trackedOperation);
    return trackedOperation;
}

export async function runYtOAuthCredentialOperation<T>(
    userId: string,
    factory: (generation: number) => Promise<T>,
): Promise<T> {
    const clearInFlight = ytOauthClearInFlight.get(userId);
    if (clearInFlight) {
        await clearInFlight;
    }

    const generation = getYtOAuthGeneration(userId);
    return trackYtOAuthCredentialOperation(userId, () => factory(generation));
}

/**
 * Ensure the user's OAuth credentials from the DB are synced to the
 * sidecar. Called lazily on each request so we don't need a startup
 * restore block. The sidecar caches instances, so this is a no-op
 * if already restored.
 */
export async function ensureUserOAuth(userId: string): Promise<boolean> {
    const cached = getCachedYtOAuth(userId);
    if (cached !== null) {
        return cached;
    }

    return runYtOAuthCredentialOperation(userId, (generation) =>
        coalesceInFlightByKey(ytOauthRestoreInFlight, userId, () =>
            restoreYtUserOAuth(userId, generation),
        ),
    );
}

async function finishYtOAuthRestore(
    userId: string,
    generation: number,
    authenticated: boolean,
): Promise<boolean> {
    if (isCurrentYtOAuthGeneration(userId, generation)) {
        setYtOAuthCache(userId, authenticated);
        return authenticated;
    }

    await ytMusicService.clearAuth(userId);
    return false;
}

async function restoreYtUserOAuth(
    userId: string,
    generation: number,
): Promise<boolean> {
    try {
        const status = await ytMusicService.getAuthStatus(userId);
        if (!isCurrentYtOAuthGeneration(userId, generation)) {
            return finishYtOAuthRestore(userId, generation, false);
        }
        if (status.authenticated) {
            return finishYtOAuthRestore(userId, generation, true);
        }
        const userSettings = await prisma.userSettings.findUnique({
            where: { userId },
            select: { ytMusicOAuthJson: true },
        });
        if (!isCurrentYtOAuthGeneration(userId, generation)) {
            return finishYtOAuthRestore(userId, generation, false);
        }
        if (!userSettings?.ytMusicOAuthJson) {
            return finishYtOAuthRestore(userId, generation, false);
        }
        const oauthJson = decrypt(userSettings.ytMusicOAuthJson);
        if (!oauthJson) {
            return finishYtOAuthRestore(userId, generation, false);
        }
        const systemSettings = await getSystemSettings();
        if (!isCurrentYtOAuthGeneration(userId, generation)) {
            return finishYtOAuthRestore(userId, generation, false);
        }
        await ytMusicService.restoreOAuthWithCredentials(
            userId,
            oauthJson,
            systemSettings?.ytMusicClientId || undefined,
            systemSettings?.ytMusicClientSecret || undefined,
        );
        logger.info(`[YTMusic] Restored OAuth credentials for user ${userId}`);
        return finishYtOAuthRestore(userId, generation, true);
    } catch (err) {
        logger.debug(`[YTMusic] OAuth restore failed for user ${userId}:`, err);
        if (isCurrentYtOAuthGeneration(userId, generation)) {
            setYtOAuthCache(userId, false);
        }
        return false;
    }
}

export async function clearYtUserOAuth(userId: string): Promise<void> {
    const existingClear = ytOauthClearInFlight.get(userId);
    if (existingClear) {
        return existingClear;
    }

    const generation = invalidateYtOAuthGeneration(userId);
    const pendingCredentials = [
        ...(ytOauthCredentialInFlight.get(userId) ?? []),
    ];
    const clearOperation = performYtOAuthClear(
        userId,
        generation,
        pendingCredentials,
    ).finally(() => {
        if (ytOauthClearInFlight.get(userId) === clearOperation) {
            ytOauthClearInFlight.delete(userId);
        }
    });
    ytOauthClearInFlight.set(userId, clearOperation);
    return clearOperation;
}

async function performYtOAuthClear(
    userId: string,
    generation: number,
    pendingCredentials: ReadonlyArray<Promise<unknown>>,
): Promise<void> {
    await Promise.allSettled(pendingCredentials);
    await ytMusicService.clearAuth(userId);
    await prisma.userSettings.upsert({
        where: { userId },
        create: { userId, ytMusicOAuthJson: null },
        update: { ytMusicOAuthJson: null },
    });
    if (isCurrentYtOAuthGeneration(userId, generation)) {
        setYtOAuthCache(userId, false);
    }
}

async function rollbackYtOAuthCredential(userId: string): Promise<void> {
    await ytMusicService.clearAuth(userId);
    await prisma.userSettings.upsert({
        where: { userId },
        create: { userId, ytMusicOAuthJson: null },
        update: { ytMusicOAuthJson: null },
    });
}

async function persistYtPolledOAuthCredential(
    userId: string,
    generation: number,
    oauthJson: string,
): Promise<boolean> {
    if (!isCurrentYtOAuthGeneration(userId, generation)) {
        await ytMusicService.clearAuth(userId);
        return false;
    }

    const encryptedOAuth = encrypt(oauthJson);
    if (!isCurrentYtOAuthGeneration(userId, generation)) return false;
    await prisma.userSettings.upsert({
        where: { userId },
        create: { userId, ytMusicOAuthJson: encryptedOAuth },
        update: { ytMusicOAuthJson: encryptedOAuth },
    });
    if (!isCurrentYtOAuthGeneration(userId, generation)) {
        await rollbackYtOAuthCredential(userId);
        return false;
    }

    setYtOAuthCache(userId, true);
    return true;
}

export async function persistYtManualOAuthCredential(
    userId: string,
    generation: number,
    oauthJson: string,
): Promise<boolean> {
    if (!isCurrentYtOAuthGeneration(userId, generation)) return false;
    const settings = await getSystemSettings();
    const encryptedOAuth = encrypt(oauthJson);
    if (!isCurrentYtOAuthGeneration(userId, generation)) return false;

    await prisma.userSettings.upsert({
        where: { userId },
        create: { userId, ytMusicOAuthJson: encryptedOAuth },
        update: { ytMusicOAuthJson: encryptedOAuth },
    });
    if (!isCurrentYtOAuthGeneration(userId, generation)) {
        await rollbackYtOAuthCredential(userId);
        return false;
    }

    await ytMusicService.restoreOAuthWithCredentials(
        userId,
        oauthJson,
        settings?.ytMusicClientId || undefined,
        settings?.ytMusicClientSecret || undefined,
    );
    if (!isCurrentYtOAuthGeneration(userId, generation)) {
        await rollbackYtOAuthCredential(userId);
        return false;
    }

    setYtOAuthCache(userId, true);
    return true;
}

export type YtOAuthPollOperationResult =
    | { credentialsConfigured: false }
    | {
          credentialsConfigured: true;
          response: YtMusicDeviceCodePollResult;
      };

function sanitizeDevicePollError(
    result: YtMusicDeviceCodePollResult,
): string | null | undefined {
    if (result.status === "error") return "Device authorization failed";
    const rawError = (result as unknown as Record<string, unknown>)["error"];
    return rawError === null ? null : undefined;
}

export async function pollYtOAuthCredential(
    userId: string,
    generation: number,
    deviceCode: string,
): Promise<YtOAuthPollOperationResult> {
    const settings = await getSystemSettings();
    if (!settings?.ytMusicClientId || !settings?.ytMusicClientSecret) {
        return { credentialsConfigured: false };
    }
    if (!isCurrentYtOAuthGeneration(userId, generation)) {
        return { credentialsConfigured: true, response: { status: "pending" } };
    }

    const result = await ytMusicService.pollDeviceAuth(
        userId,
        settings.ytMusicClientId,
        settings.ytMusicClientSecret,
        deviceCode,
    );
    if (!isCurrentYtOAuthGeneration(userId, generation)) {
        if (result.status === "success") await ytMusicService.clearAuth(userId);
        return { credentialsConfigured: true, response: { status: "pending" } };
    }

    if (result.status === "success" && result.oauth_json) {
        const persisted = await persistYtPolledOAuthCredential(
            userId,
            generation,
            result.oauth_json,
        );
        if (!persisted) {
            return {
                credentialsConfigured: true,
                response: { status: "pending" },
            };
        }
        logger.info(`[YTMusic] Device code auth completed for user ${userId}`);
    }

    return {
        credentialsConfigured: true,
        response: {
            status: result.status,
            error: sanitizeDevicePollError(result),
        },
    };
}

/**
 * Returns the user's ID if they have valid OAuth, otherwise "__public__".
 * Used for content endpoints that work without auth (album, artist, song,
 * stream-info, stream) so the admin toggle alone unlocks all core YT Music
 * functionality.
 */
export async function getUserIdOrPublic(userId: string): Promise<string> {
    const hasOAuth = await ensureUserOAuth(userId);
    return hasOAuth ? userId : "__public__";
}

/** Drops every cached OAuth session and in-flight restore, for all users. */
export function invalidateAllYtOAuthSessions(): void {
    ytOauthSessionCache.clear();
    ytOauthRestoreInFlight.clear();
}
