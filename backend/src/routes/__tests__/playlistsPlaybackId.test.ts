import type { NextFunction, Request, Response } from "express";
import request from "supertest";

jest.mock("../../middleware/auth", () => ({
    requireAuthOrToken: (req: Request, _res: Response, next: NextFunction) => {
        req.user = { id: "u1", username: "tester", role: "user" };
        next();
    },
    requireAdmin: (_req: Request, _res: Response, next: NextFunction) => next(),
}));

const childLogger = {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
};
jest.mock("../../utils/logger", () => ({
    logger: { ...childLogger, child: jest.fn(() => childLogger) },
}));

const prisma = {
    playlist: { findUnique: jest.fn(), update: jest.fn() },
    playlistItem: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        delete: jest.fn(),
        update: jest.fn(),
        aggregate: jest.fn(),
    },
    track: { findUnique: jest.fn() },
    trackTidal: { findUnique: jest.fn() },
    trackYtMusic: { findUnique: jest.fn() },
    $queryRaw: jest.fn(),
    $transaction: jest.fn(),
};
jest.mock("../../utils/db", () => ({ prisma }));

const mockEnsureRemoteTrack = jest.fn();
jest.mock("../../services/trackMappingService", () => ({
    trackMappingService: {
        ensureRemoteTrack: (...a: unknown[]) => mockEnsureRemoteTrack(...a),
    },
}));
jest.mock("../../services/deezer", () => ({ deezerService: {} }));
jest.mock("../../services/spotifyImport", () => ({ spotifyImportService: {} }));
jest.mock("../../services/soulseek", () => ({ soulseekService: {} }));
jest.mock("../../utils/systemSettings", () => ({
    getSystemSettings: jest.fn(),
}));
jest.mock("../../services/coalescedLibraryScan", () => ({
    requestCoalescedLibraryScan: jest.fn(),
}));
jest.mock("../../utils/playlistLogger", () => ({ sessionLog: jest.fn() }));

import router from "../playlists";
import { createRouteTestApp } from "./helpers/createRouteTestApp";

const app = createRouteTestApp("/api/playlists", router);

const METADATA = {
    title: "Song",
    artist: "Artist",
    album: "Album",
    durationSec: 215,
};

function localItem() {
    return {
        id: "pli-1",
        playlistId: "pl-1",
        trackId: "t-1",
        trackTidalId: null,
        trackYtMusicId: null,
        sort: 6,
        track: {
            id: "t-1",
            title: "Track 1",
            duration: 210,
            album: {
                title: "Album 1",
                coverUrl: null,
                artist: { id: "artist-1", name: "Artist 1", mbid: null },
            },
        },
        trackTidal: null,
        trackYtMusic: null,
    };
}

beforeEach(() => {
    jest.resetAllMocks();
    prisma.playlist.findUnique.mockResolvedValue({ id: "pl-1", userId: "u1" });
    prisma.playlist.update.mockResolvedValue({});
    prisma.$queryRaw.mockResolvedValue([
        { id: "pl-1", userId: "u1", mixId: null },
    ]);
    prisma.$transaction.mockImplementation(async (operation: any) =>
        operation(prisma),
    );
    prisma.playlistItem.findFirst.mockResolvedValue(null);
    prisma.playlistItem.aggregate.mockResolvedValue({ _max: { sort: 5 } });
    prisma.playlistItem.create.mockResolvedValue(localItem());
    prisma.playlistItem.delete.mockResolvedValue({});
    prisma.playlistItem.update.mockResolvedValue({});
});

describe("POST /api/playlists/:id/items with playbackId", () => {
    it("adds a library track identically to the trackId request", async () => {
        prisma.track.findUnique.mockResolvedValue({ id: "t-1" });
        const legacy = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ trackId: "t-1" });
        const unified = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "t.t-1" });

        expect(unified.status).toBe(200);
        expect(unified.body).toEqual(legacy.body);
        expect(prisma.playlistItem.create.mock.calls[1][0].data).toEqual(
            prisma.playlistItem.create.mock.calls[0][0].data,
        );
    });

    it("lets playbackId win over legacy identifier fields", async () => {
        prisma.track.findUnique.mockResolvedValue({ id: "t-1" });
        const res = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "t.t-1", trackId: "ignored", tidalTrackId: 9 });

        expect(res.status).toBe(200);
        expect(prisma.playlistItem.create.mock.calls[0][0].data).toMatchObject({
            trackId: "t-1",
            trackTidalId: null,
            trackYtMusicId: null,
        });
    });

    it("creates the TIDAL row from metadata, like the legacy request", async () => {
        prisma.trackTidal.findUnique.mockResolvedValue(null);
        mockEnsureRemoteTrack.mockResolvedValue({
            provider: "tidal",
            id: "tt-1",
        });
        const res = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "td.123", metadata: METADATA });

        expect(res.status).toBe(200);
        expect(mockEnsureRemoteTrack).toHaveBeenCalledWith(
            expect.objectContaining({
                provider: "tidal",
                tidalId: 123,
                title: "Song",
                duration: 215,
            }),
        );
        expect(prisma.playlistItem.create.mock.calls[0][0].data).toMatchObject({
            trackId: null,
            trackTidalId: "tt-1",
            trackYtMusicId: null,
        });
    });

    it("reuses a stored YT Music row without needing metadata", async () => {
        prisma.trackYtMusic.findUnique.mockResolvedValue({ id: "ym-1" });
        const res = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "ym.abc123" });

        expect(res.status).toBe(200);
        expect(mockEnsureRemoteTrack).not.toHaveBeenCalled();
        expect(prisma.playlistItem.create.mock.calls[0][0].data).toMatchObject({
            trackYtMusicId: "ym-1",
        });
    });

    it("answers 404 TRACK_NOT_FOUND for an unknown library playbackId", async () => {
        prisma.track.findUnique.mockResolvedValue(null);
        const res = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "t.missing" });

        expect(res.status).toBe(404);
        expect(res.body).toMatchObject({ code: "TRACK_NOT_FOUND" });
        expect(prisma.playlistItem.create).not.toHaveBeenCalled();
    });

    it("answers 400 INVALID_PLAYBACK_ID and METADATA_REQUIRED", async () => {
        const invalid = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "bogus" });
        expect(invalid.status).toBe(400);
        expect(invalid.body).toMatchObject({ code: "INVALID_PLAYBACK_ID" });

        prisma.trackTidal.findUnique.mockResolvedValue(null);
        const missing = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "td.123" });
        expect(missing.status).toBe(400);
        expect(missing.body).toMatchObject({ code: "METADATA_REQUIRED" });
    });

    it("keeps ownership checks for playbackId requests", async () => {
        prisma.playlist.findUnique.mockResolvedValue({
            id: "pl-1",
            userId: "someone-else",
        });
        const res = await request(app)
            .post("/api/playlists/pl-1/items")
            .send({ playbackId: "t.t-1" });
        expect(res.status).toBe(403);
    });
});

describe("DELETE /api/playlists/:id/items/:trackId with a playbackId", () => {
    it("removes a library item by t. playbackId", async () => {
        prisma.playlistItem.findFirst.mockResolvedValue({ id: "pli-1" });
        const res = await request(app).delete(
            "/api/playlists/pl-1/items/t.t-1",
        );

        expect(res.status).toBe(200);
        expect(prisma.playlistItem.findFirst).toHaveBeenCalledWith(
            expect.objectContaining({
                where: { playlistId: "pl-1", trackId: "t-1" },
            }),
        );
        expect(prisma.playlistItem.delete).toHaveBeenCalledWith({
            where: { id: "pli-1" },
        });
    });

    it("removes a TIDAL item by td. playbackId", async () => {
        prisma.playlistItem.findFirst.mockResolvedValue({ id: "pli-2" });
        const res = await request(app).delete(
            "/api/playlists/pl-1/items/td.123",
        );

        expect(res.status).toBe(200);
        expect(prisma.playlistItem.findFirst).toHaveBeenCalledWith(
            expect.objectContaining({
                where: { playlistId: "pl-1", trackTidal: { tidalId: 123 } },
            }),
        );
        expect(prisma.playlistItem.delete).toHaveBeenCalledWith({
            where: { id: "pli-2" },
        });
    });

    it("removes a YT Music item by ym. playbackId", async () => {
        prisma.playlistItem.findFirst.mockResolvedValue({ id: "pli-3" });
        const res = await request(app).delete(
            "/api/playlists/pl-1/items/ym.abc123",
        );

        expect(res.status).toBe(200);
        expect(prisma.playlistItem.findFirst).toHaveBeenCalledWith(
            expect.objectContaining({
                where: {
                    playlistId: "pl-1",
                    trackYtMusic: { videoId: "abc123" },
                },
            }),
        );
    });

    it("answers 404 when no playlist item matches the playbackId", async () => {
        prisma.playlistItem.findFirst.mockResolvedValue(null);
        const res = await request(app).delete(
            "/api/playlists/pl-1/items/td.999",
        );
        expect(res.status).toBe(404);
        expect(prisma.playlistItem.delete).not.toHaveBeenCalled();
    });

    it("answers 404 for a yt. playbackId, which no playlist can hold", async () => {
        const res = await request(app).delete(
            "/api/playlists/pl-1/items/yt.abc123",
        );
        expect(res.status).toBe(404);
        expect(prisma.playlistItem.delete).not.toHaveBeenCalled();
    });

    it("keeps the legacy playlist item id meaning for non-playbackId segments", async () => {
        prisma.playlistItem.findFirst.mockResolvedValueOnce({ id: "pli-1" });
        const res = await request(app).delete(
            "/api/playlists/pl-1/items/pli-1",
        );
        expect(res.status).toBe(200);
        expect(prisma.playlistItem.findFirst).toHaveBeenCalledWith(
            expect.objectContaining({
                where: { playlistId: "pl-1", id: "pli-1" },
            }),
        );
    });
});

describe("PUT /api/playlists/:id/items/reorder with playbackIds", () => {
    const mixedItems = [
        { id: "pli-a", trackId: "t-1", trackTidal: null, trackYtMusic: null },
        {
            id: "pli-b",
            trackId: null,
            trackTidal: { tidalId: 123 },
            trackYtMusic: null,
        },
        {
            id: "pli-c",
            trackId: null,
            trackTidal: null,
            trackYtMusic: { videoId: "abc123" },
        },
    ];

    it("reorders a mixed-source playlist by playbackId", async () => {
        prisma.playlistItem.findMany.mockResolvedValue(mixedItems);
        const res = await request(app)
            .put("/api/playlists/pl-1/items/reorder")
            .send({ playbackIds: ["ym.abc123", "t.t-1", "td.123"] });

        expect(res.status).toBe(200);
        const updates = prisma.playlistItem.update.mock.calls.map(
            ([arg]: any) => [arg.where.id, arg.data.sort],
        );
        expect(updates).toEqual([
            ["pli-c", 0],
            ["pli-a", 1],
            ["pli-b", 2],
        ]);
    });

    it("answers 404 for a playbackId that is not in the playlist", async () => {
        prisma.playlistItem.findMany.mockResolvedValue(mixedItems);
        const res = await request(app)
            .put("/api/playlists/pl-1/items/reorder")
            .send({ playbackIds: ["td.999", "t.t-1", "td.123"] });

        expect(res.status).toBe(404);
        expect(prisma.playlistItem.update).not.toHaveBeenCalled();
    });

    it("answers 400 for an unparseable playbackId or an incomplete list", async () => {
        prisma.playlistItem.findMany.mockResolvedValue(mixedItems);
        const bad = await request(app)
            .put("/api/playlists/pl-1/items/reorder")
            .send({ playbackIds: ["nope", "t.t-1", "td.123"] });
        expect(bad.status).toBe(400);

        const partial = await request(app)
            .put("/api/playlists/pl-1/items/reorder")
            .send({ playbackIds: ["t.t-1", "td.123"] });
        expect(partial.status).toBe(400);
        expect(prisma.playlistItem.update).not.toHaveBeenCalled();
    });

    it("lets playbackIds win over itemIds and trackIds", async () => {
        prisma.playlistItem.findMany.mockResolvedValue(mixedItems);
        const res = await request(app)
            .put("/api/playlists/pl-1/items/reorder")
            .send({
                playbackIds: ["td.123", "t.t-1", "ym.abc123"],
                itemIds: ["x"],
                trackIds: ["y"],
            });
        expect(res.status).toBe(200);
        expect(prisma.playlistItem.update.mock.calls[0][0].where.id).toBe(
            "pli-b",
        );
    });
});
