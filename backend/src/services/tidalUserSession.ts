/**
 * Per-user TIDAL OAuth session state: a short-lived cache of whether the
 * sidecar holds the user's session, lazy restore from the stored credential,
 * and the persist, poll and clear operations that keep them consistent.
 * Shared by the TIDAL routes and the TIDAL stream service.
 */

import { prisma } from "../utils/db";
import { encrypt, decrypt } from "../utils/encryption";
import { coalesceInFlightByKey } from "../utils/singleflight";
import { config } from "../config";
import { tidalStreamingService } from "./tidalStreaming";

const OAUTH_CACHE_TTL_MS = config.nodeEnv === "test" ? 0 : 60_000;
const OAUTH_NEGATIVE_CACHE_TTL_MS = config.nodeEnv === "test" ? 0 : 15_000;
const tidalOauthSessionCache = new Map<
    string,
    { authenticated: boolean; expiresAt: number }
>();
const tidalOauthRestoreInFlight = new Map<string, Promise<boolean>>();
const tidalOauthClearInFlight = new Map<string, Promise<void>>();
const tidalOauthCredentialInFlight = new Map<string, Set<Promise<unknown>>>();
const tidalOauthGeneration = new Map<string, number>();
export const setTidalOAuthCache = (
    userId: string,
    authenticated: boolean,
    ttlMs = OAUTH_CACHE_TTL_MS,
) => {
    if (ttlMs <= 0) {
        tidalOauthSessionCache.delete(userId);
        return;
    }
    if (!authenticated) {
        // Cache negative results with a shorter TTL so non-linked users
        // don't hit sidecar/DB on every browse/stream request, while still
        // picking up new OAuth links within a reasonable window.
        tidalOauthSessionCache.set(userId, {
            authenticated: false,
            expiresAt: Date.now() + OAUTH_NEGATIVE_CACHE_TTL_MS,
        });
        return;
    }
    tidalOauthSessionCache.set(userId, {
        authenticated,
        expiresAt: Date.now() + ttlMs,
    });
};

const getCachedTidalOAuth = (userId: string): boolean | null => {
    const entry = tidalOauthSessionCache.get(userId);
    if (!entry) return null;
    if (entry.expiresAt <= Date.now()) {
        tidalOauthSessionCache.delete(userId);
        return null;
    }
    return entry.authenticated;
};

export const invalidateTidalOAuthGeneration = (userId: string): number => {
    const generation = (tidalOauthGeneration.get(userId) ?? 0) + 1;
    tidalOauthGeneration.set(userId, generation);
    tidalOauthSessionCache.delete(userId);
    return generation;
};

export const getTidalOAuthGeneration = (userId: string): number =>
    tidalOauthGeneration.get(userId) ?? 0;

const isCurrentTidalOAuthGeneration = (
    userId: string,
    generation: number,
): boolean => getTidalOAuthGeneration(userId) === generation;

function trackTidalOAuthCredentialOperation<T>(
    userId: string,
    factory: () => Promise<T>,
): Promise<T> {
    const operations =
        tidalOauthCredentialInFlight.get(userId) ?? new Set<Promise<unknown>>();
    tidalOauthCredentialInFlight.set(userId, operations);

    let trackedOperation: Promise<T>;
    trackedOperation = Promise.resolve()
        .then(factory)
        .finally(() => {
            operations.delete(trackedOperation);
            if (operations.size === 0) {
                tidalOauthCredentialInFlight.delete(userId);
            }
        });
    operations.add(trackedOperation);
    return trackedOperation;
}

export async function runTidalOAuthCredentialOperation<T>(
    userId: string,
    factory: (generation: number) => Promise<T>,
): Promise<T> {
    const clearInFlight = tidalOauthClearInFlight.get(userId);
    if (clearInFlight) {
        await clearInFlight;
    }

    const generation = getTidalOAuthGeneration(userId);
    return trackTidalOAuthCredentialOperation(userId, () =>
        factory(generation),
    );
}

// ── Lazy OAuth restore ────────────────────────────────────────────

/**
 * Ensure the user's TIDAL OAuth credentials are loaded into the
 * sidecar. Called before any per-user streaming request.
 */
export async function ensureUserOAuth(userId: string): Promise<boolean> {
    if (await tidalStreamingService.usesInstanceAccount()) {
        return tidalStreamingService.ensureInstanceSession();
    }
    const cached = getCachedTidalOAuth(userId);
    if (cached !== null) {
        return cached;
    }

    return runTidalOAuthCredentialOperation(userId, (generation) =>
        coalesceInFlightByKey(tidalOauthRestoreInFlight, userId, () =>
            restoreTidalUserOAuth(userId, generation),
        ),
    );
}

/** Forget a session the sidecar rejected so the next request re-verifies it. */
export function markTidalSessionStale(userId: string): void {
    setTidalOAuthCache(userId, false);
    tidalStreamingService.invalidateInstanceSession();
}

async function finishTidalOAuthRestore(
    userId: string,
    generation: number,
    authenticated: boolean,
): Promise<boolean> {
    if (isCurrentTidalOAuthGeneration(userId, generation)) {
        setTidalOAuthCache(userId, authenticated);
        return authenticated;
    }

    await tidalStreamingService.clearAuth(userId);
    return false;
}

async function restoreTidalUserOAuth(
    userId: string,
    generation: number,
): Promise<boolean> {
    // This authenticated client carries the internal secret; a bare request
    // would 403 and be misread as a missing sidecar session.
    try {
        const authenticated =
            await tidalStreamingService.checkSidecarAuthStatus(userId);
        if (!isCurrentTidalOAuthGeneration(userId, generation)) {
            return finishTidalOAuthRestore(userId, generation, false);
        }
        if (authenticated) {
            return finishTidalOAuthRestore(userId, generation, true);
        }
    } catch {
        // Sidecar might not have the session, try to restore.
    }

    const userSettings = await prisma.userSettings.findUnique({
        where: { userId },
        select: { tidalOAuthJson: true },
    });
    if (!isCurrentTidalOAuthGeneration(userId, generation)) {
        return finishTidalOAuthRestore(userId, generation, false);
    }
    if (!userSettings?.tidalOAuthJson) {
        return finishTidalOAuthRestore(userId, generation, false);
    }

    let oauthJson: string;
    try {
        oauthJson = decrypt(userSettings.tidalOAuthJson);
    } catch {
        oauthJson = userSettings.tidalOAuthJson;
    }

    const restored = await tidalStreamingService.restoreOAuth(
        userId,
        oauthJson,
    );
    return finishTidalOAuthRestore(userId, generation, restored);
}

export async function clearTidalUserOAuth(userId: string): Promise<void> {
    const existingClear = tidalOauthClearInFlight.get(userId);
    if (existingClear) {
        return existingClear;
    }

    const generation = invalidateTidalOAuthGeneration(userId);
    const pendingCredentials = [
        ...(tidalOauthCredentialInFlight.get(userId) ?? []),
    ];
    const clearOperation = performTidalOAuthClear(
        userId,
        generation,
        pendingCredentials,
    ).finally(() => {
        if (tidalOauthClearInFlight.get(userId) === clearOperation) {
            tidalOauthClearInFlight.delete(userId);
        }
    });
    tidalOauthClearInFlight.set(userId, clearOperation);
    return clearOperation;
}

async function performTidalOAuthClear(
    userId: string,
    generation: number,
    pendingCredentials: ReadonlyArray<Promise<unknown>>,
): Promise<void> {
    await Promise.allSettled(pendingCredentials);
    await prisma.userSettings.update({
        where: { userId },
        data: { tidalOAuthJson: null },
    });
    await tidalStreamingService.clearAuth(userId);
    if (isCurrentTidalOAuthGeneration(userId, generation)) {
        setTidalOAuthCache(userId, false);
    }
}

async function rollbackTidalOAuthCredential(userId: string): Promise<void> {
    await prisma.userSettings.update({
        where: { userId },
        data: { tidalOAuthJson: null },
    });
    await tidalStreamingService.clearAuth(userId);
}

export async function persistTidalOAuthCredential(
    userId: string,
    generation: number,
    oauthJson: string,
): Promise<boolean> {
    const encryptedOAuth = encrypt(oauthJson);
    if (!isCurrentTidalOAuthGeneration(userId, generation)) return false;

    await prisma.userSettings.upsert({
        where: { userId },
        update: { tidalOAuthJson: encryptedOAuth },
        create: { userId, tidalOAuthJson: encryptedOAuth },
    });
    if (!isCurrentTidalOAuthGeneration(userId, generation)) {
        await rollbackTidalOAuthCredential(userId);
        return false;
    }

    await tidalStreamingService.restoreOAuth(userId, oauthJson);
    if (!isCurrentTidalOAuthGeneration(userId, generation)) {
        await rollbackTidalOAuthCredential(userId);
        return false;
    }

    setTidalOAuthCache(userId, true);
    return true;
}

export type TidalOAuthPollResponse =
    | { status: "pending" }
    | {
          status: "success";
          username: string | undefined;
          country_code: string;
      };

export async function pollTidalOAuthCredential(
    userId: string,
    generation: number,
    deviceCode: string,
): Promise<TidalOAuthPollResponse> {
    if (!isCurrentTidalOAuthGeneration(userId, generation)) {
        return { status: "pending" };
    }
    const tokens = await tidalStreamingService.pollDeviceAuth(deviceCode);
    if (!tokens) return { status: "pending" };

    const oauthJson = JSON.stringify({
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        tidal_user_id: tokens.user_id,
        country_code: tokens.country_code,
        username: tokens.username,
    });
    const persisted = await persistTidalOAuthCredential(
        userId,
        generation,
        oauthJson,
    );
    if (!persisted) return { status: "pending" };

    return {
        status: "success",
        username: tokens.username,
        country_code: tokens.country_code,
    };
}
