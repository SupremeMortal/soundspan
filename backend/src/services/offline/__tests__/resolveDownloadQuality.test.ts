import type { ParsedPlaybackId } from "../../playback/playbackId";
import {
    resolveDownloadQuality,
    type DownloadQuality,
    type DownloadSourceQualities,
} from "../resolveDownloadQuality";

const TIDAL: ParsedPlaybackId = { kind: "td", tidalId: 1 };
const YM: ParsedPlaybackId = { kind: "ym", videoId: "abc" };
const YT: ParsedPlaybackId = { kind: "yt", videoId: "abc" };
const LIB: ParsedPlaybackId = { kind: "t", trackId: "t1" };

const ALL: DownloadQuality[] = ["original", "high", "medium", "low"];

describe("resolveDownloadQuality", () => {
    describe("TIDAL", () => {
        // [admin tidalQuality, source quality in library vocabulary, provider tier]
        const sources: [string, DownloadQuality][] = [
            ["HI_RES_LOSSLESS", "original"],
            ["LOSSLESS", "original"],
            ["HIGH", "high"],
            ["LOW", "low"],
        ];
        const rank: Record<DownloadQuality, number> = {
            original: 3,
            high: 2,
            medium: 1,
            low: 0,
        };

        for (const [tier, source] of sources) {
            for (const requested of ALL) {
                const effective =
                    rank[requested] < rank[source] ? requested : source;
                const transcode = rank[requested] < rank[source];
                it(`admin ${tier}, requested ${requested} -> ${effective}${transcode ? " (transcode)" : ""}`, () => {
                    expect(
                        resolveDownloadQuality(TIDAL, requested, {
                            tidalQuality: tier,
                        }),
                    ).toEqual({
                        quality: effective,
                        providerTier: tier,
                        needsTranscode: transcode,
                    });
                });
            }
        }

        it("defaults to HIGH when no admin quality is set", () => {
            expect(resolveDownloadQuality(TIDAL, "original", {})).toEqual({
                quality: "high",
                providerTier: "HIGH",
                needsTranscode: false,
            });
        });

        it("falls back to HIGH for an unknown admin value", () => {
            expect(
                resolveDownloadQuality(TIDAL, "low", { tidalQuality: "BOGUS" }),
            ).toEqual({
                quality: "low",
                providerTier: "HIGH",
                needsTranscode: true,
            });
        });
    });

    describe("YT Music", () => {
        const sources: [string, DownloadQuality][] = [
            ["LOSSLESS", "original"],
            ["HIGH", "high"],
            ["MEDIUM", "medium"],
            ["LOW", "low"],
        ];
        const rank: Record<DownloadQuality, number> = {
            original: 3,
            high: 2,
            medium: 1,
            low: 0,
        };
        for (const [tier, source] of sources) {
            for (const requested of ALL) {
                const lower = rank[requested] < rank[source];
                it(`admin ${tier}, requested ${requested} -> ${lower ? requested : source}`, () => {
                    const admin: DownloadSourceQualities = {
                        ytMusicQuality: tier,
                    };
                    expect(
                        resolveDownloadQuality(YM, requested, admin),
                    ).toEqual({
                        quality: lower ? requested : source,
                        providerTier: tier,
                        needsTranscode: lower,
                    });
                });
            }
        }

        it("ignores the TIDAL admin quality", () => {
            expect(
                resolveDownloadQuality(YM, "original", {
                    tidalQuality: "LOW",
                    ytMusicQuality: "LOSSLESS",
                }).quality,
            ).toBe("original");
        });

        it("defaults to HIGH when no admin quality is set", () => {
            expect(resolveDownloadQuality(YM, "original", {})).toEqual({
                quality: "high",
                providerTier: "HIGH",
                needsTranscode: false,
            });
        });
    });

    describe("YouTube (no admin source quality)", () => {
        for (const requested of ALL) {
            it(`serves the requested ${requested} as the source quality`, () => {
                expect(
                    resolveDownloadQuality(YT, requested, {
                        tidalQuality: "LOW",
                        ytMusicQuality: "LOW",
                    }),
                ).toEqual({
                    quality: requested,
                    providerTier: null,
                    needsTranscode: false,
                });
            });
        }
    });

    describe("library tracks", () => {
        it("serves original as is", () => {
            expect(resolveDownloadQuality(LIB, "original", {})).toEqual({
                quality: "original",
                providerTier: null,
                needsTranscode: false,
            });
        });
        for (const requested of ["high", "medium", "low"] as const) {
            it(`transcodes for ${requested}`, () => {
                expect(resolveDownloadQuality(LIB, requested, {})).toEqual({
                    quality: requested,
                    providerTier: null,
                    needsTranscode: true,
                });
            });
        }
    });
});
