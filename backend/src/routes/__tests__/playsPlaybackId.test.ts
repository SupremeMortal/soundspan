import type { NextFunction, Request, Response } from "express";
import request from "supertest";

const mockForwardTrackReferenceIsolated = jest.fn();
const mockForwardScrobbleIsolated = jest.fn();
const mockEnsureRemoteTrack = jest.fn();

const prisma = {
    track: { findUnique: jest.fn() },
    trackTidal: { findUnique: jest.fn() },
    trackYtMusic: { findUnique: jest.fn() },
    play: { create: jest.fn(), findFirst: jest.fn() },
};

jest.mock("../../middleware/auth", () => ({
    requireAuth: (req: Request, _res: Response, next: NextFunction) => {
        req.user = {
            id: req.header("x-test-user") ?? "user-1",
            username: "tester",
            role: "user",
        };
        next();
    },
}));
jest.mock("../../utils/db", () => ({ prisma }));
jest.mock("../../utils/logger", () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));
jest.mock("../../services/trackMappingService", () => ({
    trackMappingService: {
        ensureRemoteTrack: (...a: unknown[]) => mockEnsureRemoteTrack(...a),
    },
}));
jest.mock("../../services/remoteTrackMetadataResolver", () => ({
    resolveRemoteTrackMetadataForRequest: jest.fn(async (input: any) => ({
        ...input.metadata,
    })),
}));
jest.mock("../../services/scrobbleForwarder", () => ({
    forwardTrackReferenceIsolated: (...a: unknown[]) =>
        mockForwardTrackReferenceIsolated(...a),
    forwardScrobbleIsolated: (...a: unknown[]) =>
        mockForwardScrobbleIsolated(...a),
}));

import router from "../plays";
import { createRouteTestApp } from "./helpers/createRouteTestApp";

const app = createRouteTestApp("/api/plays", router);

const METADATA = {
    title: "Song",
    artist: "Artist",
    album: "Album",
    durationSec: 215,
};
const TIDAL_ROW = {
    id: "tt-1",
    title: "Song",
    artist: "Artist",
    album: "Album",
    duration: 215,
};
const YT_ROW = { ...TIDAL_ROW, id: "ym-1" };

beforeEach(() => {
    jest.resetAllMocks();
    prisma.play.create.mockImplementation(async ({ data }: any) => ({
        id: "play-1",
        ...data,
    }));
});

describe("POST /api/plays with playbackId", () => {
    it("records a library play identical to the trackId request", async () => {
        prisma.track.findUnique.mockResolvedValue({ id: "track-1" });
        const legacy = await request(app)
            .post("/api/plays")
            .send({ trackId: "track-1" });
        const unified = await request(app)
            .post("/api/plays")
            .send({ playbackId: "t.track-1" });

        expect(unified.status).toBe(200);
        expect({ ...unified.body, playedAt: null }).toEqual({
            ...legacy.body,
            playedAt: null,
        });
        expect(prisma.play.create).toHaveBeenLastCalledWith({
            data: {
                userId: "user-1",
                trackId: "track-1",
                source: "LIBRARY",
                playedAt: expect.any(Date),
            },
        });
        expect(mockForwardTrackReferenceIsolated).toHaveBeenLastCalledWith(
            expect.objectContaining({
                reference: { source: "local", id: "track-1" },
            }),
        );
    });

    it.each([
        ["a stream already recorded a play in the last 30 seconds", true],
        ["no play exists in the last 30 seconds", false],
    ])(
        "records an explicit library play when %s",
        async (_label, recentPlayExists) => {
            prisma.track.findUnique.mockResolvedValue({ id: "track-1" });
            prisma.play.findFirst.mockResolvedValue(
                recentPlayExists
                    ? {
                          id: "stream-play",
                          userId: "user-1",
                          trackId: "track-1",
                          playedAt: new Date(Date.now() - 5_000),
                      }
                    : null,
            );
            const res = await request(app)
                .post("/api/plays")
                .send({ playbackId: "t.track-1" });
            expect(res.status).toBe(200);
            expect(prisma.play.create).toHaveBeenCalledTimes(1);
            expect(prisma.play.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    data: expect.objectContaining({
                        userId: "user-1",
                        trackId: "track-1",
                    }),
                }),
            );
        },
    );

    it("records a TIDAL play for an existing row without metadata", async () => {
        prisma.trackTidal.findUnique.mockResolvedValue(TIDAL_ROW);
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "td.77" });

        expect(res.status).toBe(200);
        expect(mockEnsureRemoteTrack).not.toHaveBeenCalled();
        expect(prisma.play.create).toHaveBeenCalledWith({
            data: {
                userId: "user-1",
                trackTidalId: "tt-1",
                source: "TIDAL",
                playedAt: expect.any(Date),
            },
        });
        expect(mockForwardScrobbleIsolated).toHaveBeenCalledWith(
            expect.objectContaining({
                track: {
                    title: "Song",
                    artist: "Artist",
                    album: "Album",
                    durationSeconds: 215,
                },
            }),
        );
    });

    it("creates the TIDAL row from metadata when it does not exist", async () => {
        prisma.trackTidal.findUnique
            .mockResolvedValueOnce(null)
            .mockResolvedValue(TIDAL_ROW);
        mockEnsureRemoteTrack.mockResolvedValue({ id: "tt-1" });
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "td.77", metadata: METADATA });

        expect(res.status).toBe(200);
        expect(mockEnsureRemoteTrack).toHaveBeenCalledWith(
            expect.objectContaining({ provider: "tidal", tidalId: 77 }),
        );
        expect(prisma.play.create).toHaveBeenCalledWith({
            data: expect.objectContaining({
                trackTidalId: "tt-1",
                source: "TIDAL",
            }),
        });
    });

    it("records a YouTube Music play", async () => {
        prisma.trackYtMusic.findUnique.mockResolvedValue(YT_ROW);
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "ym.dQw4w9WgXcQ" });

        expect(res.status).toBe(200);
        expect(prisma.play.create).toHaveBeenCalledWith({
            data: expect.objectContaining({
                trackYtMusicId: "ym-1",
                source: "YOUTUBE_MUSIC",
            }),
        });
        expect(mockForwardScrobbleIsolated).toHaveBeenCalledTimes(1);
    });

    it("answers METADATA_REQUIRED when a row must be created without metadata", async () => {
        prisma.trackTidal.findUnique.mockResolvedValue(null);
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "td.77" });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("METADATA_REQUIRED");
        expect(prisma.play.create).not.toHaveBeenCalled();
    });

    it("answers INVALID_PLAYBACK_ID and TRACK_NOT_FOUND", async () => {
        const invalid = await request(app)
            .post("/api/plays")
            .send({ playbackId: "bogus" });
        expect(invalid.status).toBe(400);
        expect(invalid.body.code).toBe("INVALID_PLAYBACK_ID");

        prisma.track.findUnique.mockResolvedValue(null);
        const missing = await request(app)
            .post("/api/plays")
            .send({ playbackId: "t.gone" });
        expect(missing.status).toBe(404);
        expect(missing.body.code).toBe("TRACK_NOT_FOUND");
    });

    it("lets playbackId win over legacy identifier fields", async () => {
        prisma.track.findUnique.mockResolvedValue({ id: "track-1" });
        const res = await request(app).post("/api/plays").send({
            playbackId: "t.track-1",
            tidalTrackId: 5,
            trackId: "other",
        });

        expect(res.status).toBe(200);
        expect(prisma.play.create).toHaveBeenCalledWith({
            data: expect.objectContaining({ trackId: "track-1" }),
        });
    });
});

describe("POST /api/plays with playedAt", () => {
    let rows: Array<Record<string, unknown>>;
    const hourAgo = () => new Date(Date.now() - 60 * 60 * 1000);

    beforeEach(() => {
        rows = [];
        prisma.play.create.mockImplementation(async ({ data }: any) => {
            const row = { id: `play-${rows.length + 1}`, ...data };
            rows.push(row);
            return row;
        });
        prisma.play.findFirst.mockImplementation(
            async ({ where }: any) =>
                rows.find((row) =>
                    Object.entries(where).every(([key, value]) =>
                        value instanceof Date
                            ? row[key] instanceof Date &&
                              (row[key] as Date).getTime() === value.getTime()
                            : row[key] === value,
                    ),
                ) ?? null,
        );
        prisma.track.findUnique.mockResolvedValue({ id: "track-1" });
        prisma.trackTidal.findUnique.mockResolvedValue(TIDAL_ROW);
        prisma.trackYtMusic.findUnique.mockResolvedValue(YT_ROW);
    });

    it("stores a library play at playedAt and scrobbles it at that time", async () => {
        const playedAt = hourAgo();
        const res = await request(app).post("/api/plays").send({
            playbackId: "t.track-1",
            playedAt: playedAt.toISOString(),
        });

        expect(res.status).toBe(200);
        expect(res.body.playedAt).toBe(playedAt.toISOString());
        expect(prisma.play.create).toHaveBeenCalledWith({
            data: {
                userId: "user-1",
                trackId: "track-1",
                source: "LIBRARY",
                playedAt,
            },
        });
        expect(mockForwardTrackReferenceIsolated).toHaveBeenCalledWith(
            expect.objectContaining({ listenedAt: playedAt }),
        );
    });

    it.each([
        ["TIDAL", "td.77", { trackTidalId: "tt-1", source: "TIDAL" }],
        [
            "YouTube Music",
            "ym.dQw4w9WgXcQ",
            { trackYtMusicId: "ym-1", source: "YOUTUBE_MUSIC" },
        ],
    ])(
        "stores a %s play at playedAt and scrobbles it at that time",
        async (_label, playbackId, expected) => {
            const playedAt = hourAgo();
            const res = await request(app)
                .post("/api/plays")
                .send({ playbackId, playedAt: playedAt.toISOString() });

            expect(res.status).toBe(200);
            expect(prisma.play.create).toHaveBeenCalledWith({
                data: { userId: "user-1", ...expected, playedAt },
            });
            expect(mockForwardScrobbleIsolated).toHaveBeenCalledWith(
                expect.objectContaining({ listenedAt: playedAt }),
            );
        },
    );

    it.each([
        ["in the future", () => new Date(Date.now() + 10 * 60 * 1000)],
        ["too old", () => new Date(Date.now() - 15 * 24 * 60 * 60 * 1000)],
    ])("answers INVALID_PLAYED_AT for a value %s", async (_label, instant) => {
        const res = await request(app).post("/api/plays").send({
            playbackId: "t.track-1",
            playedAt: instant().toISOString(),
        });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYED_AT");
        expect(prisma.track.findUnique).not.toHaveBeenCalled();
        expect(prisma.play.create).not.toHaveBeenCalled();
        expect(mockForwardTrackReferenceIsolated).not.toHaveBeenCalled();
    });

    it("answers a repeated play with the first row and records it once", async () => {
        const body = {
            playbackId: "td.77",
            playedAt: hourAgo().toISOString(),
        };
        const first = await request(app).post("/api/plays").send(body);
        const repeat = await request(app).post("/api/plays").send(body);

        expect(first.status).toBe(200);
        expect(repeat.status).toBe(200);
        expect(repeat.body.id).toBe(first.body.id);
        expect(prisma.play.create).toHaveBeenCalledTimes(1);
        expect(mockForwardScrobbleIsolated).toHaveBeenCalledTimes(1);
    });

    it("records the same playedAt again for a different track or user", async () => {
        const playedAt = hourAgo().toISOString();
        const a = await request(app)
            .post("/api/plays")
            .send({ playbackId: "td.77", playedAt });
        const otherTrack = await request(app)
            .post("/api/plays")
            .send({ playbackId: "ym.dQw4w9WgXcQ", playedAt });
        const otherUser = await request(app)
            .post("/api/plays")
            .set("x-test-user", "user-2")
            .send({ playbackId: "td.77", playedAt });

        expect(
            new Set([a.body.id, otherTrack.body.id, otherUser.body.id]).size,
        ).toBe(3);
        expect(prisma.play.create).toHaveBeenCalledTimes(3);
        expect(mockForwardScrobbleIsolated).toHaveBeenCalledTimes(3);
    });

    it("records every request without playedAt at the current time", async () => {
        const before = Date.now();
        const first = await request(app)
            .post("/api/plays")
            .send({ playbackId: "t.track-1" });
        const second = await request(app)
            .post("/api/plays")
            .send({ playbackId: "t.track-1" });
        const after = Date.now();

        expect(second.body.id).not.toBe(first.body.id);
        expect(prisma.play.create).toHaveBeenCalledTimes(2);
        expect(prisma.play.findFirst).not.toHaveBeenCalled();
        for (const row of rows) {
            const time = (row.playedAt as Date).getTime();
            expect(time).toBeGreaterThanOrEqual(before);
            expect(time).toBeLessThanOrEqual(after);
        }
    });
});

describe("POST /api/plays with listenedMs", () => {
    beforeEach(() => {
        prisma.play.findFirst.mockResolvedValue(null);
        prisma.track.findUnique.mockResolvedValue({ id: "track-1" });
        prisma.trackTidal.findUnique.mockResolvedValue(TIDAL_ROW);
        prisma.trackYtMusic.findUnique.mockResolvedValue(YT_ROW);
    });

    it.each([
        ["library", "t.track-1", { trackId: "track-1", source: "LIBRARY" }],
        ["TIDAL", "td.77", { trackTidalId: "tt-1", source: "TIDAL" }],
        [
            "YouTube Music",
            "ym.dQw4w9WgXcQ",
            { trackYtMusicId: "ym-1", source: "YOUTUBE_MUSIC" },
        ],
    ])(
        "stores and returns listenedMs for a %s playbackId",
        async (_label, playbackId, expected) => {
            const res = await request(app)
                .post("/api/plays")
                .send({ playbackId, listenedMs: 42_000 });

            expect(res.status).toBe(200);
            expect(res.body.listenedMs).toBe(42_000);
            expect(prisma.play.create).toHaveBeenCalledWith({
                data: {
                    userId: "user-1",
                    ...expected,
                    playedAt: expect.any(Date),
                    listenedMs: 42_000,
                },
            });
        },
    );

    it("accepts a value larger than the track's duration", async () => {
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "td.77", listenedMs: 3 * 215 * 1000 });

        expect(res.status).toBe(200);
        expect(res.body.listenedMs).toBe(645_000);
    });

    it.each([
        ["a negative value", -1],
        ["a fractional value", 6_000.5],
        ["a value over the limit", 86_400_001],
        ["a numeric string", "42000"],
    ])(
        "answers INVALID_LISTENED_MS for %s and writes nothing",
        async (_label, listenedMs) => {
            const res = await request(app)
                .post("/api/plays")
                .send({ playbackId: "t.track-1", listenedMs });

            expect(res.status).toBe(400);
            expect(res.body).toEqual({
                error: "Invalid listenedMs",
                code: "INVALID_LISTENED_MS",
            });
            expect(prisma.track.findUnique).not.toHaveBeenCalled();
            expect(prisma.play.create).not.toHaveBeenCalled();
        },
    );

    it.each([
        ["library", "t.track-1", {}],
        ["TIDAL row to create", "td.77", { metadata: METADATA }],
    ])(
        "answers recorded false below the minimum listen for a %s without any lookup or write",
        async (_label, playbackId, extra) => {
            const res = await request(app)
                .post("/api/plays")
                .send({ playbackId, listenedMs: 4_999, ...extra });

            expect(res.status).toBe(200);
            expect(res.body).toEqual({ recorded: false });
            expect(prisma.track.findUnique).not.toHaveBeenCalled();
            expect(prisma.trackTidal.findUnique).not.toHaveBeenCalled();
            expect(prisma.play.findFirst).not.toHaveBeenCalled();
            expect(mockEnsureRemoteTrack).not.toHaveBeenCalled();
            expect(prisma.play.create).not.toHaveBeenCalled();
            expect(mockForwardTrackReferenceIsolated).not.toHaveBeenCalled();
            expect(mockForwardScrobbleIsolated).not.toHaveBeenCalled();
        },
    );

    it("records a play of exactly the minimum listen", async () => {
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "t.track-1", listenedMs: 5_000 });

        expect(res.status).toBe(200);
        expect(res.body.listenedMs).toBe(5_000);
        expect(prisma.play.create).toHaveBeenCalledTimes(1);
        expect(mockForwardTrackReferenceIsolated).toHaveBeenCalledTimes(1);
    });

    it("answers INVALID_PLAYED_AT when a short listenedMs comes with an invalid playedAt", async () => {
        const res = await request(app).post("/api/plays").send({
            playbackId: "t.track-1",
            listenedMs: 100,
            playedAt: "yesterday",
        });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYED_AT");
    });

    it("answers INVALID_PLAYBACK_ID for a malformed request with a short listenedMs", async () => {
        const res = await request(app)
            .post("/api/plays")
            .send({ playbackId: "bogus", listenedMs: 100 });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYBACK_ID");
    });

    it("returns a repeated play as it is without updating listenedMs", async () => {
        const playedAt = new Date(Date.now() - 60 * 60 * 1000);
        const existing = {
            id: "play-existing",
            userId: "user-1",
            trackId: "track-1",
            playedAt,
            listenedMs: 30_000,
        };
        prisma.play.findFirst.mockResolvedValue(existing);
        const res = await request(app).post("/api/plays").send({
            playbackId: "t.track-1",
            playedAt: playedAt.toISOString(),
            listenedMs: 90_000,
        });

        expect(res.status).toBe(200);
        expect(res.body.id).toBe("play-existing");
        expect(res.body.listenedMs).toBe(30_000);
        expect(prisma.play.create).not.toHaveBeenCalled();
    });

    it("stores no listenedMs when the field is absent", async () => {
        await request(app).post("/api/plays").send({ playbackId: "td.77" });

        const [{ data }] = prisma.play.create.mock.calls[0];
        expect(data.listenedMs).toBeUndefined();
    });
});
