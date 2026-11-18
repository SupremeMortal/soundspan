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

/** A play heard for less than this many milliseconds is not recorded. */
export const MIN_LISTENED_MS = 5_000;

/** The largest accepted `listenedMs`: 24 hours. */
export const MAX_LISTENED_MS = 86_400_000;

/** Result of {@link parseListenedMs}: `listenedMs` is `undefined` when the field was absent. */
export type ParsedListenedMs =
    | { ok: true; listenedMs: number | undefined }
    | { ok: false };

/**
 * Validates the optional `listenedMs` of a play report: a JSON number that is
 * an integer from 0 to {@link MAX_LISTENED_MS} inclusive. An absent value is
 * valid and yields `undefined`. A value larger than the track's duration is
 * valid, because a passage may have been replayed.
 */
export function parseListenedMs(value: unknown): ParsedListenedMs {
    if (value === undefined) {
        return { ok: true, listenedMs: undefined };
    }
    if (
        typeof value !== "number" ||
        !Number.isInteger(value) ||
        value < 0 ||
        value > MAX_LISTENED_MS
    ) {
        return { ok: false };
    }
    return { ok: true, listenedMs: value };
}
