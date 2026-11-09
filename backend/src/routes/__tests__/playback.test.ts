import express from "express";
import request from "supertest";

jest.mock("../../utils/logger", () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
        child: jest.fn().mockReturnThis(),
    },
}));

const mockAuth = jest.fn();
jest.mock("../../middleware/auth", () => ({
    requireAuthOrToken: (req: any, res: any, next: () => void) =>
        mockAuth(req, res, next),
}));

const mockStreamingLimiter = jest.fn();
const mockYtMusicLimiter = jest.fn();
jest.mock("../../middleware/rateLimiter", () => ({
    streamingLimiter: (req: any, res: any, next: () => void) =>
        mockStreamingLimiter(req, res, next),
    ytMusicStreamLimiter: (req: any, res: any, next: () => void) =>
        mockYtMusicLimiter(req, res, next),
}));

const mockResolvePlayback = jest.fn();
jest.mock("../../services/playback/resolvePlayback", () => {
    class PlaybackResolutionError extends Error {
        constructor(
            readonly code: string,
            message: string,
        ) {
            super(message);
        }
    }
    return {
        PlaybackResolutionError,
        resolvePlayback: (...args: unknown[]) => mockResolvePlayback(...args),
    };
});

const mockStreamLibraryTrack = jest.fn();
const mockStreamTidalTrack = jest.fn();
const mockStreamYtMusicTrack = jest.fn();
const mockStreamYouTubeVideo = jest.fn();
jest.mock("../../services/playback/streamLibraryTrack", () => ({
    streamLibraryTrack: (...a: unknown[]) => mockStreamLibraryTrack(...a),
}));
jest.mock("../../services/playback/streamTidalTrack", () => ({
    streamTidalTrack: (...a: unknown[]) => mockStreamTidalTrack(...a),
}));
jest.mock("../../services/playback/streamYtMusicTrack", () => ({
    streamYtMusicTrack: (...a: unknown[]) => mockStreamYtMusicTrack(...a),
}));
jest.mock("../../services/playback/streamYouTubeVideo", () => ({
    streamYouTubeVideo: (...a: unknown[]) => mockStreamYouTubeVideo(...a),
}));

const mockGetPlaybackStreamInfo = jest.fn();
jest.mock("../../services/playback/playbackStreamInfo", () => ({
    getPlaybackStreamInfo: (...a: unknown[]) => mockGetPlaybackStreamInfo(...a),
}));

import router from "../playback";
import { PlaybackResolutionError } from "../../services/playback/resolvePlayback";

const NO_MW = { ytMusicStreamLimiter: false, ytMusicEnabledCheck: false };
const YM_MW = { ytMusicStreamLimiter: true, ytMusicEnabledCheck: true };

function makeApp() {
    const app = express();
    app.use("/api/playback", router);
    return app;
}

beforeEach(() => {
    jest.clearAllMocks();
    mockAuth.mockImplementation((req: any, _res: any, next: () => void) => {
        req.user = { id: "user-1" };
        next();
    });
    mockStreamingLimiter.mockImplementation(
        (_req: any, _res: any, next: () => void) => next(),
    );
    mockYtMusicLimiter.mockImplementation(
        (_req: any, _res: any, next: () => void) => next(),
    );
});

describe("GET /api/playback/stream/:playbackId", () => {
    it("rejects an invalid playbackId with 400 INVALID_PLAYBACK_ID", async () => {
        const res = await request(makeApp()).get("/api/playback/stream/nope");
        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYBACK_ID");
        expect(mockResolvePlayback).not.toHaveBeenCalled();
    });

    it("rejects an invalid quality with 400", async () => {
        const res = await request(makeApp()).get(
            "/api/playback/stream/t.abc?quality=ultra",
        );
        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_QUALITY");
    });

    it("rejects unauthenticated requests before resolving", async () => {
        mockAuth.mockImplementation((_req: any, res: any) =>
            res.status(401).json({ error: "Unauthorized" }),
        );
        const res = await request(makeApp()).get("/api/playback/stream/t.abc");
        expect(res.status).toBe(401);
        expect(mockResolvePlayback).not.toHaveBeenCalled();
    });

    it("authenticates with an X-API-Key, Bearer or ?token= credential via requireAuthOrToken", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "medium",
            middleware: NO_MW,
        });
        mockStreamLibraryTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        const app = makeApp();
        await request(app)
            .get("/api/playback/stream/t.abc")
            .set("X-API-Key", "k");
        await request(app)
            .get("/api/playback/stream/t.abc")
            .set("Authorization", "Bearer tok");
        await request(app).get("/api/playback/stream/t.abc?token=tok");
        expect(mockAuth).toHaveBeenCalledTimes(3);
        expect(mockAuth.mock.calls[0][0].headers["x-api-key"]).toBe("k");
        expect(mockAuth.mock.calls[1][0].headers.authorization).toBe(
            "Bearer tok",
        );
        expect(mockAuth.mock.calls[2][0].query.token).toBe("tok");
    });

    it("streams a library track via streamLibraryTrack", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "high",
            middleware: NO_MW,
        });
        mockStreamLibraryTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        const res = await request(makeApp()).get(
            "/api/playback/stream/t.abc?quality=high",
        );
        expect(res.status).toBe(200);
        expect(mockResolvePlayback).toHaveBeenCalledWith("user-1", {
            parsed: { kind: "t", trackId: "abc" },
            quality: "high",
        });
        expect(mockStreamLibraryTrack).toHaveBeenCalledWith(
            expect.objectContaining({
                userId: "user-1",
                trackId: "abc",
                quality: "high",
                playbackId: "t.abc",
            }),
        );
    });

    it("streams a TIDAL track via streamTidalTrack with the provider quality", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "td",
            tidalId: 123,
            quality: "LOSSLESS",
            middleware: NO_MW,
        });
        mockStreamTidalTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        const res = await request(makeApp()).get("/api/playback/stream/td.123");
        expect(res.status).toBe(200);
        expect(mockStreamTidalTrack).toHaveBeenCalledWith(
            expect.objectContaining({
                userId: "user-1",
                trackId: 123,
                quality: "LOSSLESS",
            }),
        );
        expect(mockStreamLibraryTrack).not.toHaveBeenCalled();
    });

    it("streams a YT Music track via streamYtMusicTrack through the YT Music limiter", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "ym",
            videoId: "dQw4w9WgXcQ",
            mode: "public",
            quality: "high",
            middleware: YM_MW,
        });
        mockStreamYtMusicTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        const res = await request(makeApp()).get(
            "/api/playback/stream/ym.dQw4w9WgXcQ",
        );
        expect(res.status).toBe(200);
        expect(mockYtMusicLimiter).toHaveBeenCalledTimes(1);
        expect(mockStreamYtMusicTrack).toHaveBeenCalledWith(
            expect.objectContaining({
                videoId: "dQw4w9WgXcQ",
                mode: "public",
                quality: "high",
                userId: "user-1",
            }),
        );
    });

    it("does not run the YT Music limiter for other kinds", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "td",
            tidalId: 1,
            quality: "HIGH",
            middleware: NO_MW,
        });
        mockStreamTidalTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("a");
        });
        await request(makeApp()).get("/api/playback/stream/td.1");
        expect(mockYtMusicLimiter).not.toHaveBeenCalled();
    });

    it("answers 429 RATE_LIMITED with Retry-After when the YT Music limiter trips", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "ym",
            videoId: "dQw4w9WgXcQ",
            mode: "authenticated",
            quality: "high",
            middleware: YM_MW,
        });
        mockYtMusicLimiter.mockImplementation((_req: any, res: any) => {
            res.setHeader("Retry-After", "30");
            res.status(429).send("Too many YouTube Music stream requests.");
        });
        const res = await request(makeApp()).get(
            "/api/playback/stream/ym.dQw4w9WgXcQ",
        );
        expect(res.status).toBe(429);
        expect(res.headers["retry-after"]).toBe("30");
        expect(res.body.code).toBe("RATE_LIMITED");
        expect(mockStreamYtMusicTrack).not.toHaveBeenCalled();
    });

    it("streams a YouTube video via streamYouTubeVideo with the Range header", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "yt",
            videoId: "dQw4w9WgXcQ",
            quality: "HIGH",
            middleware: NO_MW,
        });
        mockStreamYouTubeVideo.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        await request(makeApp())
            .get("/api/playback/stream/yt.dQw4w9WgXcQ")
            .set("Range", "bytes=0-9");
        expect(mockStreamYouTubeVideo).toHaveBeenCalledWith(
            expect.objectContaining({
                videoId: "dQw4w9WgXcQ",
                quality: "HIGH",
                range: "bytes=0-9",
            }),
        );
    });

    it("drops Range when If-Range is sent for a remote source, so the client gets the full body", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "td",
            tidalId: 123,
            quality: "LOSSLESS",
            middleware: NO_MW,
        });
        mockStreamTidalTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        await request(makeApp())
            .get("/api/playback/stream/td.123")
            .set("Range", "bytes=10-")
            .set("If-Range", '"some-etag"');
        const { req } = mockStreamTidalTrack.mock.calls[0][0];
        expect(req.headers.range).toBeUndefined();
    });

    it("drops Range on If-Range for a YouTube video too", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "yt",
            videoId: "dQw4w9WgXcQ",
            quality: "HIGH",
            middleware: NO_MW,
        });
        mockStreamYouTubeVideo.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        await request(makeApp())
            .get("/api/playback/stream/yt.dQw4w9WgXcQ")
            .set("Range", "bytes=10-")
            .set("If-Range", '"some-etag"');
        expect(mockStreamYouTubeVideo).toHaveBeenCalledWith(
            expect.objectContaining({ range: undefined }),
        );
    });

    it("keeps Range with If-Range for library tracks, which validate their ETag", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "high",
            middleware: NO_MW,
        });
        mockStreamLibraryTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        await request(makeApp())
            .get("/api/playback/stream/t.abc")
            .set("Range", "bytes=10-")
            .set("If-Range", '"some-etag"');
        const { req } = mockStreamLibraryTrack.mock.calls[0][0];
        expect(req.headers.range).toBe("bytes=10-");
    });

    it("keeps Range without If-Range for a remote source", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "td",
            tidalId: 123,
            quality: "LOSSLESS",
            middleware: NO_MW,
        });
        mockStreamTidalTrack.mockImplementation(async ({ res }: any) => {
            res.status(200).end("audio");
        });
        await request(makeApp())
            .get("/api/playback/stream/td.123")
            .set("Range", "bytes=10-");
        const { req } = mockStreamTidalTrack.mock.calls[0][0];
        expect(req.headers.range).toBe("bytes=10-");
    });

    it("passes a 206 with Content-Range from the stream service through", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "medium",
            middleware: NO_MW,
        });
        mockStreamLibraryTrack.mockImplementation(async ({ res }: any) => {
            res.status(206)
                .set({
                    "Content-Range": "bytes 0-4/10",
                    "Accept-Ranges": "bytes",
                    "Content-Length": "5",
                    "Content-Type": "audio/mpeg",
                })
                .end("audio");
        });
        const res = await request(makeApp())
            .get("/api/playback/stream/t.abc")
            .set("Range", "bytes=0-4");
        expect(res.status).toBe(206);
        expect(res.headers["content-range"]).toBe("bytes 0-4/10");
        expect(res.headers["accept-ranges"]).toBe("bytes");
    });

    it.each([
        ["TRACK_NOT_FOUND", 404],
        ["SOURCE_UNAVAILABLE", 409],
    ])("maps a resolver %s error to %i", async (code, status) => {
        mockResolvePlayback.mockRejectedValue(
            new PlaybackResolutionError(code as any, "nope"),
        );
        const res = await request(makeApp()).get("/api/playback/stream/t.abc");
        expect(res.status).toBe(status);
        expect(res.body.code).toBe(code);
    });

    it("adds a code to error bodies the stream services write", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "medium",
            middleware: NO_MW,
        });
        const cases: Array<[number, string]> = [
            [404, "TRACK_NOT_FOUND"],
            [409, "SOURCE_UNAVAILABLE"],
            [429, "RATE_LIMITED"],
            [502, "UPSTREAM_FAILED"],
            [503, "UPSTREAM_FAILED"],
            [504, "UPSTREAM_FAILED"],
        ];
        for (const [status, code] of cases) {
            mockStreamLibraryTrack.mockImplementationOnce(
                async ({ res }: any) => {
                    res.status(status).json({ error: "service message" });
                },
            );
            const res = await request(makeApp()).get(
                "/api/playback/stream/t.abc",
            );
            expect(res.status).toBe(status);
            expect(res.body).toEqual({ error: "service message", code });
        }
    });

    it("answers 502 UPSTREAM_FAILED when a stream service throws", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "medium",
            middleware: NO_MW,
        });
        mockStreamLibraryTrack.mockRejectedValue(new Error("boom"));
        const res = await request(makeApp()).get("/api/playback/stream/t.abc");
        expect(res.status).toBe(502);
        expect(res.body.code).toBe("UPSTREAM_FAILED");
    });

    it("applies the streaming limiter before authentication", async () => {
        const order: string[] = [];
        mockStreamingLimiter.mockImplementation(
            (_r: any, _s: any, next: () => void) => {
                order.push("limiter");
                next();
            },
        );
        mockAuth.mockImplementation((req: any, res: any, next: () => void) => {
            order.push("auth");
            res.status(401).json({ error: "Unauthorized" });
        });
        await request(makeApp()).get("/api/playback/stream/t.abc");
        expect(order).toEqual(["limiter", "auth"]);
    });
});

describe("GET /api/playback/stream-info/:playbackId", () => {
    const url = "/api/playback/stream-info";

    it("rejects an invalid playbackId with 400 INVALID_PLAYBACK_ID", async () => {
        const res = await request(makeApp()).get(`${url}/nope`);
        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYBACK_ID");
        expect(mockResolvePlayback).not.toHaveBeenCalled();
    });

    it("rejects an invalid quality with 400 INVALID_QUALITY", async () => {
        const res = await request(makeApp()).get(`${url}/t.abc?quality=ultra`);
        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_QUALITY");
    });

    it("rejects unauthenticated requests before resolving", async () => {
        mockAuth.mockImplementation((_req: any, res: any) =>
            res.status(401).json({ error: "Unauthorized" }),
        );
        const res = await request(makeApp()).get(`${url}/t.abc`);
        expect(res.status).toBe(401);
        expect(mockResolvePlayback).not.toHaveBeenCalled();
    });

    it("maps resolution errors to 404 and 409 with a code", async () => {
        mockResolvePlayback.mockRejectedValueOnce(
            new PlaybackResolutionError("TRACK_NOT_FOUND", "Track not found"),
        );
        const notFound = await request(makeApp()).get(`${url}/t.abc`);
        expect(notFound.status).toBe(404);
        expect(notFound.body.code).toBe("TRACK_NOT_FOUND");

        mockResolvePlayback.mockRejectedValueOnce(
            new PlaybackResolutionError("SOURCE_UNAVAILABLE", "Disabled"),
        );
        const unavailable = await request(makeApp()).get(`${url}/td.1`);
        expect(unavailable.status).toBe(409);
        expect(unavailable.body.code).toBe("SOURCE_UNAVAILABLE");
    });

    it("resolves with the requested quality and answers with the service's body", async () => {
        const playback = {
            kind: "t",
            trackId: "abc",
            quality: "high",
            libraryQuality: "high",
            middleware: NO_MW,
        };
        mockResolvePlayback.mockResolvedValue(playback);
        mockGetPlaybackStreamInfo.mockImplementation(async ({ res }: any) => {
            res.json({ playbackId: "t.abc", quality: "high" });
        });
        const res = await request(makeApp()).get(`${url}/t.abc?quality=high`);
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ playbackId: "t.abc", quality: "high" });
        expect(mockResolvePlayback).toHaveBeenCalledWith("user-1", {
            parsed: { kind: "t", trackId: "abc" },
            quality: "high",
        });
        expect(mockGetPlaybackStreamInfo).toHaveBeenCalledWith(
            expect.objectContaining({
                playback,
                playbackId: "t.abc",
                userId: "user-1",
            }),
        );
    });

    it("adds a code to error bodies the info service writes", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "td",
            tidalId: 1,
            quality: "HIGH",
            libraryQuality: "medium",
            middleware: NO_MW,
        });
        mockGetPlaybackStreamInfo.mockImplementation(async ({ res }: any) => {
            res.status(404).json({ error: "Stream not found" });
        });
        const res = await request(makeApp()).get(`${url}/td.1`);
        expect(res.status).toBe(404);
        expect(res.body.code).toBe("TRACK_NOT_FOUND");
    });

    it("applies the YT Music limiter when the id resolves to ym", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "ym",
            videoId: "dQw4w9WgXcQ",
            mode: "public",
            quality: "high",
            libraryQuality: "high",
            middleware: YM_MW,
        });
        mockYtMusicLimiter.mockImplementation((_req: any, res: any) =>
            res.status(429).send("Slow down"),
        );
        const res = await request(makeApp()).get(`${url}/ym.dQw4w9WgXcQ`);
        expect(res.status).toBe(429);
        expect(res.body.code).toBe("RATE_LIMITED");
        expect(mockGetPlaybackStreamInfo).not.toHaveBeenCalled();
    });

    it("answers 502 UPSTREAM_FAILED when the info service throws", async () => {
        mockResolvePlayback.mockResolvedValue({
            kind: "t",
            trackId: "abc",
            quality: "high",
            libraryQuality: "high",
            middleware: NO_MW,
        });
        mockGetPlaybackStreamInfo.mockRejectedValue(new Error("boom"));
        const res = await request(makeApp()).get(`${url}/t.abc`);
        expect(res.status).toBe(502);
        expect(res.body.code).toBe("UPSTREAM_FAILED");
    });

    it("applies the streaming limiter", async () => {
        mockStreamingLimiter.mockImplementation((_req: any, res: any) =>
            res.status(429).json({ error: "Too many" }),
        );
        const res = await request(makeApp()).get(`${url}/t.abc`);
        expect(res.status).toBe(429);
        expect(mockAuth).not.toHaveBeenCalled();
    });
});
