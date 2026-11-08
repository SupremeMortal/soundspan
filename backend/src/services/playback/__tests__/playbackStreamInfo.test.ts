const mockTrackFindUnique = jest.fn();
jest.mock("../../../utils/db", () => ({
    prisma: {
        track: { findUnique: (...a: unknown[]) => mockTrackFindUnique(...a) },
    },
}));
jest.mock("../../../utils/librarySorting", () => ({
    TRACK_VISIBLE_WHERE: { removedAt: null },
}));

const mockGetTidalStreamInfo = jest.fn();
jest.mock("../streamTidalTrack", () => ({
    getTidalStreamInfo: (...a: unknown[]) => mockGetTidalStreamInfo(...a),
}));
const mockGetYtMusicStreamInfo = jest.fn();
jest.mock("../streamYtMusicTrack", () => ({
    getYtMusicStreamInfo: (...a: unknown[]) => mockGetYtMusicStreamInfo(...a),
}));
const mockGetVideoInfo = jest.fn();
jest.mock("../../youtubeDownload", () => ({
    youtubeDownloadService: {
        getVideoInfo: (...a: unknown[]) => mockGetVideoInfo(...a),
    },
}));

const mockResolveAbsolutePath = jest.fn();
const mockBuildFederated = jest.fn();
jest.mock("../../../utils/libraryAudioInfo", () => ({
    resolveAudioInfoAbsolutePath: (...a: unknown[]) =>
        mockResolveAbsolutePath(...a),
    buildFederatedAudioInfo: (...a: unknown[]) => mockBuildFederated(...a),
}));
const mockResolvePlaybackPath = jest.fn();
const mockLoadLocal = jest.fn();
jest.mock("../../../routes/library/trackAudioInfo", () => ({
    TRACK_AUDIO_INFO_SELECT: { filePath: true },
    isFederatedAudioInfoTrack: (t: { origin: string }) =>
        t.origin === "FEDERATED",
    resolvePlaybackAudioInfoPath: (...a: unknown[]) =>
        mockResolvePlaybackPath(...a),
    loadLocalAudioInfo: (...a: unknown[]) => mockLoadLocal(...a),
}));
const mockExists = jest.fn();
const mockStat = jest.fn();
jest.mock("fs", () => ({
    existsSync: (...a: unknown[]) => mockExists(...a),
    promises: { stat: (...a: unknown[]) => mockStat(...a) },
}));
jest.mock("../../../utils/logger", () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));

import type { Request, Response } from "express";
import { getPlaybackStreamInfo } from "../playbackStreamInfo";
import type { ResolvedPlayback } from "../resolvePlayback";

const MW = { ytMusicStreamLimiter: false, ytMusicEnabledCheck: false };

function fakeRes() {
    const res: any = { statusCode: 200, body: undefined, headersSent: false };
    res.status = (code: number) => {
        res.statusCode = code;
        return res;
    };
    res.json = (body: unknown) => {
        res.body = body;
        return res;
    };
    return res as Response & { statusCode: number; body: any };
}

const req = { headers: {} } as Request;

async function run(playback: ResolvedPlayback, playbackId: string) {
    const res = fakeRes();
    await getPlaybackStreamInfo({
        playback,
        playbackId,
        userId: "u1",
        req,
        res,
    });
    return res;
}

beforeEach(() => {
    jest.resetAllMocks();
});

describe("getPlaybackStreamInfo", () => {
    describe("td", () => {
        const playback: ResolvedPlayback = {
            kind: "td",
            tidalId: 123456,
            quality: "LOSSLESS",
            libraryQuality: "original",
            middleware: MW,
        };

        it("maps TIDAL stream info to the unified shape", async () => {
            mockGetTidalStreamInfo.mockImplementation(async ({ res }: any) => {
                res.json({
                    trackId: 123456,
                    quality: "LOSSLESS",
                    acodec: "FLAC",
                    content_type: "audio/flac",
                    bit_depth: 16,
                    sample_rate: 44100,
                });
            });
            const res = await run(playback, "td.123456");
            expect(res.statusCode).toBe(200);
            expect(res.body).toEqual({
                playbackId: "td.123456",
                contentType: "audio/flac",
                codec: "flac",
                bitrate: null,
                sampleRate: 44100,
                bitDepth: 16,
                durationMs: null,
                contentLength: null,
                quality: "original",
            });
            expect(mockGetTidalStreamInfo).toHaveBeenCalledWith(
                expect.objectContaining({
                    userId: "u1",
                    trackId: 123456,
                    quality: "LOSSLESS",
                }),
            );
        });

        it("nulls fields TIDAL does not report", async () => {
            mockGetTidalStreamInfo.mockImplementation(async ({ res }: any) => {
                res.json({ trackId: 1, quality: "HIGH", acodec: "AAC" });
            });
            const res = await run(playback, "td.1");
            expect(res.body).toMatchObject({
                contentType: null,
                codec: "aac",
                sampleRate: null,
                bitDepth: null,
            });
        });

        it("passes service errors through untouched", async () => {
            mockGetTidalStreamInfo.mockImplementation(async ({ res }: any) => {
                res.status(401).json({ error: "Not authenticated to TIDAL" });
            });
            const res = await run(playback, "td.1");
            expect(res.statusCode).toBe(401);
            expect(res.body).toEqual({ error: "Not authenticated to TIDAL" });
        });
    });

    describe("ym", () => {
        const playback: ResolvedPlayback = {
            kind: "ym",
            videoId: "dQw4w9WgXcQ",
            mode: "public",
            quality: "high",
            libraryQuality: "high",
            middleware: MW,
        };

        it("maps YT Music stream info to the unified shape", async () => {
            mockGetYtMusicStreamInfo.mockImplementation(
                async ({ res }: any) => {
                    res.json({
                        videoId: "dQw4w9WgXcQ",
                        abr: 128,
                        acodec: "opus",
                        duration: 212,
                        content_type: "audio/webm",
                    });
                },
            );
            const res = await run(playback, "ym.dQw4w9WgXcQ");
            expect(res.body).toEqual({
                playbackId: "ym.dQw4w9WgXcQ",
                contentType: "audio/webm",
                codec: "opus",
                bitrate: 128,
                sampleRate: null,
                bitDepth: null,
                durationMs: 212000,
                contentLength: null,
                quality: "high",
            });
            expect(mockGetYtMusicStreamInfo).toHaveBeenCalledWith(
                expect.objectContaining({
                    mode: "public",
                    videoId: "dQw4w9WgXcQ",
                    quality: "high",
                }),
            );
        });

        it("nulls missing or non-numeric values", async () => {
            mockGetYtMusicStreamInfo.mockImplementation(
                async ({ res }: any) => {
                    res.json({ videoId: "x", abr: 0, duration: "n/a" });
                },
            );
            const res = await run(playback, "ym.dQw4w9WgXcQ");
            expect(res.body).toMatchObject({
                bitrate: null,
                durationMs: null,
                codec: null,
                contentType: null,
            });
        });

        it("passes a 404 through", async () => {
            mockGetYtMusicStreamInfo.mockImplementation(
                async ({ res }: any) => {
                    res.status(404).json({ error: "Stream not found" });
                },
            );
            const res = await run(playback, "ym.dQw4w9WgXcQ");
            expect(res.statusCode).toBe(404);
        });
    });

    describe("yt", () => {
        const playback: ResolvedPlayback = {
            kind: "yt",
            videoId: "dQw4w9WgXcQ",
            quality: "HIGH",
            libraryQuality: "high",
            middleware: MW,
        };

        it("derives container and codec from the video info", async () => {
            mockGetVideoInfo.mockResolvedValue({
                videoId: "dQw4w9WgXcQ",
                duration: 212,
                audioFormat: "webm",
            });
            const res = await run(playback, "yt.dQw4w9WgXcQ");
            expect(mockGetVideoInfo).toHaveBeenCalledWith(
                "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            );
            expect(res.body).toEqual({
                playbackId: "yt.dQw4w9WgXcQ",
                contentType: "audio/webm",
                codec: "opus",
                bitrate: null,
                sampleRate: null,
                bitDepth: null,
                durationMs: 212000,
                contentLength: null,
                quality: "high",
            });
        });

        it("maps an mp4 container to AAC", async () => {
            mockGetVideoInfo.mockResolvedValue({
                duration: 10,
                audioFormat: "mp4",
            });
            const res = await run(playback, "yt.dQw4w9WgXcQ");
            expect(res.body).toMatchObject({
                contentType: "audio/mp4",
                codec: "aac",
            });
        });

        it("reports unknown container and duration as null", async () => {
            mockGetVideoInfo.mockResolvedValue({});
            const res = await run(playback, "yt.dQw4w9WgXcQ");
            expect(res.body).toMatchObject({
                contentType: null,
                codec: null,
                durationMs: null,
            });
        });

        it("answers 502 UPSTREAM_FAILED when the sidecar fails", async () => {
            mockGetVideoInfo.mockRejectedValue(new Error("boom"));
            const res = await run(playback, "yt.dQw4w9WgXcQ");
            expect(res.statusCode).toBe(502);
            expect(res.body).toMatchObject({ code: "UPSTREAM_FAILED" });
        });

        it("answers 404 TRACK_NOT_FOUND when the sidecar says 404", async () => {
            mockGetVideoInfo.mockRejectedValue({ response: { status: 404 } });
            const res = await run(playback, "yt.dQw4w9WgXcQ");
            expect(res.statusCode).toBe(404);
            expect(res.body).toMatchObject({ code: "TRACK_NOT_FOUND" });
        });
    });

    describe("t", () => {
        const playback = (
            quality: "original" | "medium",
        ): ResolvedPlayback => ({
            kind: "t",
            trackId: "trk1",
            quality,
            libraryQuality: quality,
            middleware: MW,
        });
        const localTrack = {
            filePath: "a/b.flac",
            fileModified: new Date("2024-01-01"),
            fileSize: 900,
            duration: 241,
            mime: "audio/flac",
            origin: "LOCAL",
        };

        it("404s TRACK_NOT_FOUND for a missing track", async () => {
            mockTrackFindUnique.mockResolvedValue(null);
            const res = await run(playback("original"), "t.trk1");
            expect(res.statusCode).toBe(404);
            expect(res.body).toMatchObject({ code: "TRACK_NOT_FOUND" });
        });

        it("reads the source file for original quality", async () => {
            mockTrackFindUnique.mockResolvedValue(localTrack);
            mockResolveAbsolutePath.mockReturnValue("/music/a/b.flac");
            mockExists.mockReturnValue(true);
            mockLoadLocal.mockResolvedValue({
                codec: "FLAC",
                bitrate: 800,
                sampleRate: 44100,
                bitDepth: 16,
                lossless: true,
                channels: 2,
            });
            mockStat.mockResolvedValue({ size: 28734112 });
            const res = await run(playback("original"), "t.trk1");
            expect(mockResolvePlaybackPath).not.toHaveBeenCalled();
            expect(res.body).toEqual({
                playbackId: "t.trk1",
                contentType: "audio/flac",
                codec: "flac",
                bitrate: 800,
                sampleRate: 44100,
                bitDepth: 16,
                durationMs: 241000,
                contentLength: 28734112,
                quality: "original",
            });
        });

        it("describes the transcode for a lower quality", async () => {
            mockTrackFindUnique.mockResolvedValue(localTrack);
            mockResolveAbsolutePath.mockReturnValue("/music/a/b.flac");
            mockExists.mockReturnValue(true);
            mockResolvePlaybackPath.mockResolvedValue({
                metadataPath: "/cache/trk1.mp3",
                requestedQuality: "medium",
            });
            mockLoadLocal.mockResolvedValue({
                codec: "MPEG 1 Layer 3",
                bitrate: 192,
                sampleRate: 44100,
                bitDepth: null,
                lossless: false,
                channels: 2,
            });
            mockStat.mockResolvedValue({ size: 5000 });
            const res = await run(playback("medium"), "t.trk1");
            expect(mockResolvePlaybackPath).toHaveBeenCalledWith(
                "trk1",
                localTrack.fileModified,
                "/music/a/b.flac",
                "u1",
                "medium",
            );
            expect(res.body).toMatchObject({
                contentType: "audio/mpeg",
                bitrate: 192,
                bitDepth: null,
                contentLength: 5000,
                quality: "medium",
            });
        });

        it("estimates from synchronized metadata for a federated track", async () => {
            mockTrackFindUnique.mockResolvedValue({
                ...localTrack,
                origin: "FEDERATED",
                filePath: null,
                mime: "audio/mpeg",
            });
            mockBuildFederated.mockReturnValue({
                codec: "MP3",
                bitrate: 320,
                sampleRate: null,
                bitDepth: null,
                lossless: false,
                channels: null,
            });
            const res = await run(playback("original"), "t.trk1");
            expect(res.body).toEqual({
                playbackId: "t.trk1",
                contentType: "audio/mpeg",
                codec: "mp3",
                bitrate: 320,
                sampleRate: null,
                bitDepth: null,
                durationMs: 241000,
                contentLength: 900,
                quality: "original",
            });
        });

        it("404s when the file is missing on disk", async () => {
            mockTrackFindUnique.mockResolvedValue(localTrack);
            mockResolveAbsolutePath.mockReturnValue("/music/a/b.flac");
            mockExists.mockReturnValue(false);
            const res = await run(playback("original"), "t.trk1");
            expect(res.statusCode).toBe(404);
            expect(res.body).toMatchObject({ code: "TRACK_NOT_FOUND" });
        });

        it("answers 502 UPSTREAM_FAILED when metadata cannot be read", async () => {
            mockTrackFindUnique.mockResolvedValue(localTrack);
            mockResolveAbsolutePath.mockReturnValue("/music/a/b.flac");
            mockExists.mockReturnValue(true);
            mockLoadLocal.mockRejectedValue(new Error("corrupt"));
            const res = await run(playback("original"), "t.trk1");
            expect(res.statusCode).toBe(502);
            expect(res.body).toMatchObject({ code: "UPSTREAM_FAILED" });
        });
    });
});
