import { z } from "zod";

/** How far a reported `playedAt` may lie ahead of the server clock (clock skew allowance). */
export const PLAYED_AT_MAX_FUTURE_MS = 5 * 60 * 1000;

/** How far a reported `playedAt` may lie behind the server clock. */
export const PLAYED_AT_MAX_AGE_MS = 14 * 24 * 60 * 60 * 1000;

const playedAtSchema = z.iso.datetime();

/** Result of {@link parsePlayedAt}: `playedAt` is `undefined` when the field was absent. */
export type ParsedPlayedAt =
    | { ok: true; playedAt: Date | undefined }
    | { ok: false };

/**
 * Validates the optional `playedAt` of a play report: an ISO-8601 UTC
 * instant (`Z` suffix) within `[now - 14 days, now + 5 minutes]`, both ends
 * inclusive. An absent value is valid and yields `undefined`.
 */
export function parsePlayedAt(value: unknown, now: Date): ParsedPlayedAt {
    if (value === undefined) {
        return { ok: true, playedAt: undefined };
    }
    const parsed = playedAtSchema.safeParse(value);
    if (!parsed.success) {
        return { ok: false };
    }
    const playedAt = new Date(parsed.data);
    const time = playedAt.getTime();
    if (
        Number.isNaN(time) ||
        time > now.getTime() + PLAYED_AT_MAX_FUTURE_MS ||
        time < now.getTime() - PLAYED_AT_MAX_AGE_MS
    ) {
        return { ok: false };
    }
    return { ok: true, playedAt };
}
