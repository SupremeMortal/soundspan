const mockTrackFindUnique = jest.fn();
const mockUserSettingsFindUnique = jest.fn();
const mockGetSystemSettings = jest.fn();
const mockYtIsAvailable = jest.fn();
const mockEnsureUserOAuth = jest.fn();
const mockTidalIsEnabled = jest.fn();
const mockTidalIsAvailable = jest.fn();
const mockTidalAuthStatus = jest.fn();

jest.mock("../../../utils/db", () => ({
    prisma: {
        track: { findUnique: (...a: unknown[]) => mockTrackFindUnique(...a) },
        userSettings: {
            findUnique: (...a: unknown[]) => mockUserSettingsFindUnique(...a),
        },
    },
}));
jest.mock("../../../utils/systemSettings", () => ({
    getSystemSettings: (...a: unknown[]) => mockGetSystemSettings(...a),
}));
jest.mock("../../youtubeMusic", () => ({
    ytMusicService: {
        isAvailable: (...a: unknown[]) => mockYtIsAvailable(...a),
    },
}));
jest.mock("../../ytMusicUserSession", () => ({
    ensureUserOAuth: (...a: unknown[]) => mockEnsureUserOAuth(...a),
}));
jest.mock("../../tidalStreaming", () => ({
    tidalStreamingService: {
        isEnabled: (...a: unknown[]) => mockTidalIsEnabled(...a),
        isAvailable: (...a: unknown[]) => mockTidalIsAvailable(...a),
        getAuthStatus: (...a: unknown[]) => mockTidalAuthStatus(...a),
    },
}));

import {
    PlaybackResolutionError,
    resolvePlayback,
    type PlaybackQuality,
} from "../resolvePlayback";

const USER = "user-1";

beforeEach(() => {
    jest.resetAllMocks();
    mockTrackFindUnique.mockResolvedValue({ id: "trk1" });
    mockUserSettingsFindUnique.mockResolvedValue({ playbackQuality: "high" });
    mockGetSystemSettings.mockResolvedValue({ ytMusicEnabled: true });
    mockYtIsAvailable.mockResolvedValue(true);
    mockEnsureUserOAuth.mockResolvedValue(true);
    mockTidalIsEnabled.mockResolvedValue(true);
    mockTidalIsAvailable.mockResolvedValue(true);
    mockTidalAuthStatus.mockResolvedValue({
        authenticated: true,
        credentialsConfigured: true,
    });
});

async function codeOf(p: Promise<unknown>): Promise<string> {
    try {
        await p;
    } catch (err) {
        expect(err).toBeInstanceOf(PlaybackResolutionError);
        return (err as PlaybackResolutionError).code;
    }
    throw new Error("expected rejection");
}

const NO_MIDDLEWARE = {
    ytMusicStreamLimiter: false,
    ytMusicEnabledCheck: false,
};

describe("resolvePlayback", () => {
    describe("t (library track)", () => {
        it("routes to the library stream with the requested quality", async () => {
            const out = await resolvePlayback(USER, {
                parsed: { kind: "t", trackId: "trk1" },
                quality: "low",
            });
            expect(out).toEqual({
                kind: "t",
                trackId: "trk1",
                quality: "low",
                libraryQuality: "low",
                middleware: NO_MIDDLEWARE,
                recordPlay: true,
            });
            expect(mockTrackFindUnique).toHaveBeenCalledWith(
                expect.objectContaining({
                    where: expect.objectContaining({
                        id: "trk1",
                        removedAt: null,
                    }),
                }),
            );
        });

        it("carries recordPlay false through to the library stream", async () => {
            const out = await resolvePlayback(USER, {
                parsed: { kind: "t", trackId: "trk1" },
                recordPlay: false,
            });
            expect(out).toMatchObject({ kind: "t", recordPlay: false });
        });

        it("records plays when recordPlay is true", async () => {
            const out = await resolvePlayback(USER, {
                parsed: { kind: "t", trackId: "trk1" },
                recordPlay: true,
            });
            expect(out).toMatchObject({ kind: "t", recordPlay: true });
        });

        it("uses the saved playback quality when none is requested", async () => {
            const out = await resolvePlayback(USER, {
                parsed: { kind: "t", trackId: "trk1" },
            });
            expect(out).toMatchObject({ kind: "t", quality: "high" });
        });

        it("falls back to medium when the user has no saved quality", async () => {
            mockUserSettingsFindUnique.mockResolvedValue(null);
            const out = await resolvePlayback(USER, {
                parsed: { kind: "t", trackId: "trk1" },
            });
            expect(out).toMatchObject({ quality: "medium" });
        });

        it("falls back to medium when the saved quality is unrecognised", async () => {
            mockUserSettingsFindUnique.mockResolvedValue({
                playbackQuality: "weird",
            });
            const out = await resolvePlayback(USER, {
                parsed: { kind: "t", trackId: "trk1" },
            });
            expect(out).toMatchObject({ quality: "medium" });
        });

        it("rejects a missing or removed track with TRACK_NOT_FOUND", async () => {
            mockTrackFindUnique.mockResolvedValue(null);
            expect(
                await codeOf(
                    resolvePlayback(USER, {
                        parsed: { kind: "t", trackId: "gone" },
                    }),
                ),
            ).toBe("TRACK_NOT_FOUND");
        });
    });

    describe("td (TIDAL)", () => {
        const parsed = { kind: "td", tidalId: 123 } as const;

        it("maps library qualities to TIDAL qualities", async () => {
            const table: Record<PlaybackQuality, string> = {
                original: "HI_RES_LOSSLESS",
                high: "HIGH",
                medium: "HIGH",
                low: "LOW",
            };
            for (const [lib, native] of Object.entries(table)) {
                const out = await resolvePlayback(USER, {
                    parsed,
                    quality: lib as PlaybackQuality,
                });
                expect(out).toEqual({
                    kind: "td",
                    tidalId: 123,
                    quality: native,
                    libraryQuality: lib,
                    middleware: NO_MIDDLEWARE,
                });
            }
        });

        it("maps the saved playback quality when none is requested", async () => {
            mockUserSettingsFindUnique.mockResolvedValue({
                playbackQuality: "original",
            });
            const out = await resolvePlayback(USER, { parsed });
            expect(out).toMatchObject({ quality: "HI_RES_LOSSLESS" });
        });

        it("is SOURCE_UNAVAILABLE when TIDAL is disabled", async () => {
            mockTidalIsEnabled.mockResolvedValue(false);
            expect(await codeOf(resolvePlayback(USER, { parsed }))).toBe(
                "SOURCE_UNAVAILABLE",
            );
        });

        it("is SOURCE_UNAVAILABLE when the TIDAL sidecar is unavailable", async () => {
            mockTidalIsAvailable.mockResolvedValue(false);
            expect(await codeOf(resolvePlayback(USER, { parsed }))).toBe(
                "SOURCE_UNAVAILABLE",
            );
        });

        it("is SOURCE_UNAVAILABLE when the user has no TIDAL link", async () => {
            mockTidalAuthStatus.mockResolvedValue({
                authenticated: false,
                credentialsConfigured: false,
            });
            expect(await codeOf(resolvePlayback(USER, { parsed }))).toBe(
                "SOURCE_UNAVAILABLE",
            );
            expect(mockTidalAuthStatus).toHaveBeenCalledWith(USER);
        });
    });

    describe("ym (YouTube Music)", () => {
        const parsed = { kind: "ym", videoId: "dQw4w9WgXcQ" } as const;
        const YM_MIDDLEWARE = {
            ytMusicStreamLimiter: true,
            ytMusicEnabledCheck: true,
        };

        it("uses authenticated mode when the user has linked YT Music", async () => {
            const out = await resolvePlayback(USER, {
                parsed,
                quality: "medium",
            });
            expect(out).toEqual({
                kind: "ym",
                videoId: "dQw4w9WgXcQ",
                mode: "authenticated",
                quality: "medium",
                libraryQuality: "medium",
                middleware: YM_MIDDLEWARE,
            });
            expect(mockEnsureUserOAuth).toHaveBeenCalledWith(USER);
        });

        it("uses public mode when the user has not linked YT Music", async () => {
            mockEnsureUserOAuth.mockResolvedValue(false);
            const out = await resolvePlayback(USER, { parsed });
            expect(out).toMatchObject({ mode: "public", quality: "high" });
        });

        it("uses public mode when the YT Music sidecar is unavailable", async () => {
            mockYtIsAvailable.mockResolvedValue(false);
            const out = await resolvePlayback(USER, { parsed });
            expect(out).toMatchObject({ mode: "public" });
            expect(mockEnsureUserOAuth).not.toHaveBeenCalled();
        });

        it("maps library qualities to YT Music qualities", async () => {
            const table: Record<PlaybackQuality, string> = {
                original: "lossless",
                high: "high",
                medium: "medium",
                low: "low",
            };
            for (const [lib, native] of Object.entries(table)) {
                const out = await resolvePlayback(USER, {
                    parsed,
                    quality: lib as PlaybackQuality,
                });
                expect(out).toMatchObject({ kind: "ym", quality: native });
            }
        });

        it("maps the saved playback quality when none is requested", async () => {
            mockUserSettingsFindUnique.mockResolvedValue({
                playbackQuality: "original",
            });
            const out = await resolvePlayback(USER, { parsed });
            expect(out).toMatchObject({ quality: "lossless" });
        });

        it("is SOURCE_UNAVAILABLE on a fresh install with no system settings row", async () => {
            mockGetSystemSettings.mockResolvedValue(null);
            expect(await codeOf(resolvePlayback(USER, { parsed }))).toBe(
                "SOURCE_UNAVAILABLE",
            );
        });

        it("is SOURCE_UNAVAILABLE when YT Music is disabled on the server", async () => {
            mockGetSystemSettings.mockResolvedValue({ ytMusicEnabled: false });
            expect(await codeOf(resolvePlayback(USER, { parsed }))).toBe(
                "SOURCE_UNAVAILABLE",
            );
        });
    });

    describe("yt (YouTube)", () => {
        const parsed = { kind: "yt", videoId: "dQw4w9WgXcQ" } as const;

        it("maps library qualities to YouTube qualities", async () => {
            const table: Record<PlaybackQuality, string> = {
                original: "LOSSLESS",
                high: "HIGH",
                medium: "MEDIUM",
                low: "LOW",
            };
            for (const [lib, native] of Object.entries(table)) {
                const out = await resolvePlayback(USER, {
                    parsed,
                    quality: lib as PlaybackQuality,
                });
                expect(out).toEqual({
                    kind: "yt",
                    videoId: "dQw4w9WgXcQ",
                    quality: native,
                    libraryQuality: lib,
                    middleware: NO_MIDDLEWARE,
                });
            }
        });

        it("maps the saved playback quality when none is requested", async () => {
            const out = await resolvePlayback(USER, { parsed });
            expect(out).toMatchObject({
                quality: "HIGH",
                libraryQuality: "high",
            });
        });
    });
});
