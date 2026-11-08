import { buildPlaybackEtag, ifRangeAllowsRange } from "../playbackEtag";

describe("buildPlaybackEtag", () => {
    const base = { playbackId: "t.abc", variant: "v1", contentLength: 1000 };

    it("is a strong (non-weak) quoted validator", () => {
        expect(buildPlaybackEtag(base)).toMatch(/^"[0-9a-f]{32}"$/);
    });

    it("is stable for identical inputs", () => {
        expect(buildPlaybackEtag(base)).toBe(buildPlaybackEtag({ ...base }));
    });

    it.each([
        ["playbackId", { playbackId: "t.other" }],
        ["variant", { variant: "v2" }],
        ["contentLength", { contentLength: 1001 }],
    ])("changes when %s changes", (_name, change) => {
        expect(buildPlaybackEtag({ ...base, ...change })).not.toBe(
            buildPlaybackEtag(base),
        );
    });

    it("does not confuse field boundaries", () => {
        expect(
            buildPlaybackEtag({
                playbackId: "a",
                variant: "bc",
                contentLength: 1,
            }),
        ).not.toBe(
            buildPlaybackEtag({
                playbackId: "ab",
                variant: "c",
                contentLength: 1,
            }),
        );
    });
});

describe("ifRangeAllowsRange", () => {
    const etag = '"abc"';

    it("allows the range when there is no If-Range header", () => {
        expect(ifRangeAllowsRange(undefined, etag)).toBe(true);
    });

    it("allows the range when If-Range equals the current ETag", () => {
        expect(ifRangeAllowsRange('"abc"', etag)).toBe(true);
    });

    it("rejects the range when If-Range names a different ETag", () => {
        expect(ifRangeAllowsRange('"zzz"', etag)).toBe(false);
    });

    it("rejects a weak validator, which If-Range never matches", () => {
        expect(ifRangeAllowsRange('W/"abc"', etag)).toBe(false);
    });

    it("rejects a date validator, since the server serves no Last-Modified", () => {
        expect(ifRangeAllowsRange("Wed, 21 Oct 2015 07:28:00 GMT", etag)).toBe(
            false,
        );
    });
});
