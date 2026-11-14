import {
    PLAYED_AT_MAX_AGE_MS,
    PLAYED_AT_MAX_FUTURE_MS,
    parsePlayedAt,
} from "../playReport";

const NOW = new Date("2026-03-15T12:00:00.000Z");
const at = (offsetMs: number) => new Date(NOW.getTime() + offsetMs);

describe("parsePlayedAt", () => {
    it("uses a 5 minute future allowance and a 14 day window", () => {
        expect(PLAYED_AT_MAX_FUTURE_MS).toBe(5 * 60 * 1000);
        expect(PLAYED_AT_MAX_AGE_MS).toBe(14 * 24 * 60 * 60 * 1000);
    });

    it("accepts an absent value as no timestamp", () => {
        expect(parsePlayedAt(undefined, NOW)).toEqual({
            ok: true,
            playedAt: undefined,
        });
    });

    it.each([
        ["one hour ago", at(-60 * 60 * 1000)],
        ["exactly 5 minutes ahead", at(PLAYED_AT_MAX_FUTURE_MS)],
        ["exactly 14 days old", at(-PLAYED_AT_MAX_AGE_MS)],
        ["now", NOW],
    ])("accepts a UTC instant %s", (_label, instant) => {
        expect(parsePlayedAt(instant.toISOString(), NOW)).toEqual({
            ok: true,
            playedAt: instant,
        });
    });

    it.each([
        [
            "one millisecond beyond 5 minutes ahead",
            at(PLAYED_AT_MAX_FUTURE_MS + 1),
        ],
        ["one millisecond older than 14 days", at(-PLAYED_AT_MAX_AGE_MS - 1)],
    ])("rejects a UTC instant %s", (_label, instant) => {
        expect(parsePlayedAt(instant.toISOString(), NOW)).toEqual({
            ok: false,
        });
    });

    it.each([
        ["a date-only string", "2026-03-15"],
        ["an offset", "2026-03-15T10:00:00+02:00"],
        ["prose", "yesterday"],
        ["an empty string", ""],
        ["null", null],
        ["a number", 1700000000000],
        ["an object", {}],
    ])("rejects %s", (_label, value) => {
        expect(parsePlayedAt(value, NOW)).toEqual({ ok: false });
    });
});
