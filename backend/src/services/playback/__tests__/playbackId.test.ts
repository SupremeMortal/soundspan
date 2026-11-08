import {
    encodePlaybackId,
    parsePlaybackId,
    playbackIdSchema,
    type ParsedPlaybackId,
} from "../playbackId";

const ROUND_TRIPS: Array<[string, ParsedPlaybackId]> = [
    [
        "t.ckz1abcd0000qwertyuiop1234",
        { kind: "t", trackId: "ckz1abcd0000qwertyuiop1234" },
    ],
    ["td.123456", { kind: "td", tidalId: 123456 }],
    ["ym.dQw4w9WgXcQ", { kind: "ym", videoId: "dQw4w9WgXcQ" }],
    ["yt.a-b_c-d_e-1", { kind: "yt", videoId: "a-b_c-d_e-1" }],
    ["yt.-_-_-_-_-_-", { kind: "yt", videoId: "-_-_-_-_-_-" }],
];

const INVALID = [
    "",
    "t",
    "t1",
    "xx.1",
    "t.a.b",
    "t.",
    ".abc",
    `t.${"a".repeat(65)}`,
    "t.has space",
    "t.bad/char",
    "t.bad%20",
    "T.abc",
    "td.0",
    "td.-1",
    "td.1e3",
    "td.01",
    "td.abc",
    "td.1.5",
    "td.9007199254740993",
];

describe("playbackId", () => {
    it.each(ROUND_TRIPS)("round-trips %s", (encoded, ref) => {
        expect(parsePlaybackId(encoded)).toEqual(ref);
        expect(encodePlaybackId(ref)).toBe(encoded);
    });

    it("accepts a 64-character key", () => {
        const key = "a".repeat(64);
        expect(parsePlaybackId(`t.${key}`)).toEqual({
            kind: "t",
            trackId: key,
        });
    });

    it.each(INVALID)("rejects %j", (value) => {
        expect(parsePlaybackId(value)).toBeNull();
    });

    it("rejects non-string input", () => {
        expect(parsePlaybackId(undefined as unknown as string)).toBeNull();
        expect(parsePlaybackId(5 as unknown as string)).toBeNull();
    });

    it.each([
        { kind: "t", trackId: "" },
        { kind: "t", trackId: "a.b" },
        { kind: "ym", videoId: "x".repeat(65) },
        { kind: "td", tidalId: 0 },
        { kind: "td", tidalId: -5 },
        { kind: "td", tidalId: 1.5 },
        { kind: "td", tidalId: Number.MAX_SAFE_INTEGER + 2 },
        { kind: "zz", trackId: "a" },
    ])("encode throws for %j", (ref) => {
        expect(() => encodePlaybackId(ref as ParsedPlaybackId)).toThrow();
    });

    it("schema agrees with parsePlaybackId", () => {
        for (const [encoded, ref] of ROUND_TRIPS) {
            const r = playbackIdSchema.safeParse(encoded);
            expect(r.success).toBe(true);
            expect(r.success && r.data).toEqual(ref);
        }
        for (const value of INVALID) {
            expect(playbackIdSchema.safeParse(value).success).toBe(false);
        }
        expect(playbackIdSchema.safeParse(42).success).toBe(false);
    });
});
