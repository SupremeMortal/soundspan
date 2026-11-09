import type { NextFunction, Request, Response } from "express";
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
    requireAuth: (req: Request, _res: Response, next: NextFunction) => {
        req.user = { id: "u1", username: "tester", role: "user" };
        next();
    },
}));
jest.mock("../../utils/logger", () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));
jest.mock("../../services/socialPresenceEvents", () => ({
    publishSocialPresenceUpdate: jest.fn(),
}));

const prisma = {
    playbackState: { findUnique: jest.fn(), upsert: jest.fn() },
    track: { findMany: jest.fn() },
};
jest.mock("../../utils/db", () => ({
    prisma,
    Prisma: { DbNull: { __dbNull: true } },
}));

import router from "../playbackState";

function createApp() {
    const app = express();
    app.use(express.json());
    app.use("/", router);
    return app;
}

const libraryTrack = {
    id: "trk1",
    title: "Local Song",
    duration: 200,
    origin: "LOCAL",
    album: {
        id: "alb1",
        title: "Local Album",
        coverUrl: "covers/a.jpg",
        artist: { id: "art1", name: "Local Artist" },
    },
};

/** Echo the stored queue back as a persisted row so GET can read it. */
function storeUpserts() {
    let stored: any = null;
    prisma.playbackState.upsert.mockImplementation(async (args: any) => {
        stored = {
            userId: "u1",
            deviceId: "legacy",
            ...args.create,
        };
        return stored;
    });
    prisma.playbackState.findUnique.mockImplementation(async () => stored);
}

describe("POST /api/playback-state with playbackId", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        prisma.track.findMany.mockResolvedValue([libraryTrack]);
        storeUpserts();
    });

    it("stores playbackId queue items in the legacy format and reads the same playbackIds back", async () => {
        const app = createApp();
        const playbackIds = ["t.trk1", "td.42", "ym.vid1", "yt.vid2"];
        const post = await request(app)
            .post("/")
            .send({
                playbackType: "track",
                currentIndex: 1,
                queue: [
                    { playbackId: "t.trk1" },
                    {
                        playbackId: "td.42",
                        metadata: {
                            title: "Tidal Song",
                            artist: "Tidal Artist",
                            album: "Tidal Album",
                            durationSec: 180,
                            artworkUrl: "https://img/td.jpg",
                        },
                    },
                    {
                        playbackId: "ym.vid1",
                        metadata: {
                            title: "YM Song",
                            artist: "YM Artist",
                            album: "YM Album",
                            durationSec: 90,
                        },
                    },
                    {
                        playbackId: "yt.vid2",
                        metadata: {
                            title: "YT Video",
                            artist: "YT Channel",
                            album: "YouTube",
                            durationSec: 60,
                        },
                    },
                ],
            });
        expect(post.status).toBe(200);

        const stored = prisma.playbackState.upsert.mock.calls[0][0].create
            .queue as any[];
        expect(stored[0]).toMatchObject({
            id: "trk1",
            mediaSource: "local",
            title: "Local Song",
            duration: 200,
            artist: { id: "art1", name: "Local Artist" },
            album: { id: "alb1", title: "Local Album" },
        });
        expect(stored[1]).toMatchObject({
            id: "tidal:42",
            streamSource: "tidal",
            tidalTrackId: 42,
            title: "Tidal Song",
            duration: 180,
            artist: { name: "Tidal Artist" },
            album: { title: "Tidal Album", coverArt: "https://img/td.jpg" },
        });
        expect(stored[2]).toMatchObject({
            streamSource: "youtube",
            youtubeVideoId: "vid1",
            title: "YM Song",
        });
        expect(stored[3]).toMatchObject({
            streamSource: "youtube-direct",
            youtubeVideoId: "vid2",
            title: "YT Video",
        });

        const get = await request(app).get("/");
        expect(get.body.queue.map((i: any) => i.playbackId)).toEqual(
            playbackIds,
        );
    });

    it("stores a federated library track with the peer stream source", async () => {
        prisma.track.findMany.mockResolvedValue([
            { ...libraryTrack, origin: "FEDERATED" },
        ]);
        const res = await request(createApp())
            .post("/")
            .send({ playbackType: "track", queue: [{ playbackId: "t.trk1" }] });
        expect(res.status).toBe(200);
        const stored = prisma.playbackState.upsert.mock.calls[0][0].create
            .queue as any[];
        expect(stored[0]).toMatchObject({ id: "trk1", streamSource: "peer" });
    });

    it("accepts legacy and playbackId items in one request, playbackId winning over legacy fields", async () => {
        const res = await request(createApp())
            .post("/")
            .send({
                playbackType: "track",
                queue: [
                    { id: "legacy1", streamSource: "local", title: "Legacy" },
                    {
                        playbackId: "td.7",
                        streamSource: "local",
                        id: "ignored",
                        metadata: {
                            title: "T",
                            artist: "A",
                            album: "B",
                            durationSec: 1,
                        },
                    },
                ],
            });
        expect(res.status).toBe(200);
        const stored = prisma.playbackState.upsert.mock.calls[0][0].create
            .queue as any[];
        expect(stored[0]).toMatchObject({ id: "legacy1", title: "Legacy" });
        expect(stored[1]).toMatchObject({
            id: "tidal:7",
            streamSource: "tidal",
            tidalTrackId: 7,
        });
    });

    it("rejects an invalid queue playbackId with 400 INVALID_PLAYBACK_ID and stores nothing", async () => {
        const res = await request(createApp())
            .post("/")
            .send({
                playbackType: "track",
                queue: [{ playbackId: "t.trk1" }, { playbackId: "nope" }],
            });
        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYBACK_ID");
        expect(prisma.playbackState.upsert).not.toHaveBeenCalled();
    });

    it("answers 404 TRACK_NOT_FOUND for a library playbackId that is not stored", async () => {
        prisma.track.findMany.mockResolvedValue([]);
        const res = await request(createApp())
            .post("/")
            .send({ playbackType: "track", queue: [{ playbackId: "t.gone" }] });
        expect(res.status).toBe(404);
        expect(res.body.code).toBe("TRACK_NOT_FOUND");
    });

    it("stores a current-item playbackId as trackId and rejects an invalid one", async () => {
        const app = createApp();
        const ok = await request(app)
            .post("/")
            .send({ playbackType: "track", playbackId: "t.trk1" });
        expect(ok.status).toBe(200);
        expect(
            prisma.playbackState.upsert.mock.calls[0][0].create.trackId,
        ).toBe("trk1");

        const bad = await request(app)
            .post("/")
            .send({ playbackType: "track", playbackId: "zz.1" });
        expect(bad.status).toBe(400);
        expect(bad.body.code).toBe("INVALID_PLAYBACK_ID");
    });
});
