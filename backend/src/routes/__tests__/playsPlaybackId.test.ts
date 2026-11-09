import type { NextFunction, Request, Response } from "express";
import request from "supertest";

const mockForwardTrackReferenceIsolated = jest.fn();
const mockForwardScrobbleIsolated = jest.fn();
const mockEnsureRemoteTrack = jest.fn();

const prisma = {
    track: { findUnique: jest.fn() },
    trackTidal: { findUnique: jest.fn() },
    trackYtMusic: { findUnique: jest.fn() },
    play: { create: jest.fn() },
};

jest.mock("../../middleware/auth", () => ({
    requireAuth: (req: Request, _res: Response, next: NextFunction) => {
        req.user = { id: "user-1", username: "tester", role: "user" };
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
