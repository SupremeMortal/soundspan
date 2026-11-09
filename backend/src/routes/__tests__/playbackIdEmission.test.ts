/**
 * Emission guard for `playbackId`.
 *
 * Every entry in `EMISSION_CASES` drives one track-returning route through
 * supertest with mocked collaborators and asserts that each returned track item
 * carries a parseable `playbackId` that agrees with the item's legacy
 * identifier fields (`id`, `streamSource`, `tidalTrackId`, `youtubeVideoId`).
 *
 * To cover a new track-returning route:
 *   1. Mock its collaborators at the top of this file (or extend the existing
 *      mocks) so the route returns at least one track of each source it can emit.
 *   2. Add an `EmissionCase` with the method, mounted path, a `prepare` hook
 *      that seeds the mocks, and an `extractItems` function that returns the
 *      response's track items.
 * The OpenAPI schema side of the guard lives in
 * `config/__tests__/openapiPlaybackIdCoverage.test.ts`.
 */
import express from "express";
import request from "supertest";

jest.mock("../../middleware/rateLimitStore", () => {
    const { MemoryStore } = jest.requireActual("express-rate-limit");
    return {
        createRedisRateLimitOptions: () => ({
            store: new MemoryStore(),
            passOnStoreError: true,
        }),
    };
});

jest.mock("../../middleware/auth", () => ({
    requireAuth: (req: any, _res: any, next: () => void) => {
        req.user ??= { id: "u1" };
        next();
    },
    requireAuthOrToken: (req: any, _res: any, next: () => void) => {
        req.user ??= { id: "u1" };
        next();
    },
    requireAdmin: (_req: any, _res: any, next: () => void) => next(),
}));

jest.mock("../../utils/logger", () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
        child: jest.fn().mockReturnThis(),
    },
}));

const prisma = {
    playbackState: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
    },
};
jest.mock("../../utils/db", () => ({
    prisma,
    Prisma: { DbNull: { __dbNull: true } },
}));

jest.mock("../../services/youtubeDownload", () => ({
    youtubeDownloadService: {
        getVideoInfo: jest.fn(),
        getPlaylistInfo: jest.fn(),
        getStreamProxy: jest.fn(),
        startDownload: jest.fn(),
        getDownloadJobStatus: jest.fn(),
        listDownloads: jest.fn(),
        cancelDownload: jest.fn(),
    },
    watchYouTubeDownloadJobUntilTerminal: jest.fn(),
}));

jest.mock("../../services/coalescedLibraryScan", () => ({
    requestCoalescedLibraryScan: jest.fn(),
}));

import playbackStateRouter from "../playbackState";
import youtubeRouter from "../youtube";
import { parsePlaybackId } from "../../services/playback/playbackId";
import { youtubeDownloadService } from "../../services/youtubeDownload";

type TrackItem = Record<string, any>;

interface EmissionCase {
    name: string;
    method: "get";
    basePath: string;
    router: express.Router;
    path: string;
    headers?: Record<string, string>;
    prepare: () => void;
    extractItems: (body: any) => TrackItem[];
}

const EMISSION_CASES: EmissionCase[] = [
    {
        name: "GET /api/playback-state (queue)",
        method: "get",
        basePath: "/api/playback-state",
        router: playbackStateRouter,
        path: "/",
        headers: { "X-Playback-Device-Id": "device-A" },
        prepare: () => {
            prisma.playbackState.findUnique.mockResolvedValue({
                id: "state-1",
                userId: "u1",
                deviceId: "device-A",
                playbackType: "track",
                queue: [
                    { id: "ckLocal1", title: "Local" },
                    { id: "ckPeer1", streamSource: "peer", title: "Peer" },
                    {
                        id: "tidal:42",
                        streamSource: "tidal",
                        tidalTrackId: 42,
                        title: "Tidal",
                    },
                    {
                        id: "yt:vid1",
                        streamSource: "youtube",
                        youtubeVideoId: "vid1",
                        title: "YT Music",
                    },
                    {
                        id: "yt:vid2",
                        streamSource: "youtube-direct",
                        youtubeVideoId: "vid2",
                        title: "YouTube",
                    },
                ],
            });
        },
        extractItems: (body) => body.queue,
    },
    {
        name: "GET /api/youtube/info",
        method: "get",
        basePath: "/api/youtube",
        router: youtubeRouter,
        path: "/info?url=https%3A%2F%2Fyoutu.be%2FdQw4w9WgXcQ",
        prepare: () => {
            (
                youtubeDownloadService.getVideoInfo as jest.Mock
            ).mockResolvedValue({
                videoId: "dQw4w9WgXcQ",
                title: "Song",
                uploader: "Up",
                duration: 212,
                thumbnail: null,
                uploadDate: "20200101",
            });
        },
        extractItems: (body) => [body],
    },
];

/** Asserts the playbackId names the same track as the item's legacy fields. */
function expectConsistentWithLegacyFields(item: TrackItem) {
    const parsed = parsePlaybackId(item.playbackId);
    expect(parsed).not.toBeNull();
    switch (parsed!.kind) {
        case "td":
            expect(item.tidalTrackId).toBe(parsed!.tidalId);
            break;
        case "ym":
            expect(item.streamSource).toBe("youtube");
            expect(item.youtubeVideoId).toBe(parsed!.videoId);
            break;
        case "yt":
            expect(item.youtubeVideoId ?? item.videoId).toBe(parsed!.videoId);
            break;
        case "t":
            expect(item.id).toBe(parsed!.trackId);
            break;
    }
}

describe("playbackId emission across track-returning routes", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test.each(EMISSION_CASES.map((c) => [c.name, c] as const))(
        "%s emits a consistent playbackId on every track",
        async (_name, testCase) => {
            testCase.prepare();
            const app = express();
            app.use(express.json());
            app.use(testCase.basePath, testCase.router);

            let req = request(app).get(testCase.basePath + testCase.path);
            for (const [key, value] of Object.entries(testCase.headers ?? {})) {
                req = req.set(key, value);
            }
            const res = await req;

            expect(res.status).toBe(200);
            const items = testCase.extractItems(res.body);
            expect(items.length).toBeGreaterThan(0);
            for (const item of items) {
                expectConsistentWithLegacyFields(item);
            }
        },
    );
});
