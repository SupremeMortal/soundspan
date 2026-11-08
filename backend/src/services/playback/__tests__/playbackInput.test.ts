const mockTrackFindUnique = jest.fn();
const mockTidalFindUnique = jest.fn();
const mockYtFindUnique = jest.fn();
const mockEnsureRemoteTrack = jest.fn();

jest.mock("../../../utils/db", () => ({
    prisma: {
        track: { findUnique: (...a: unknown[]) => mockTrackFindUnique(...a) },
        trackTidal: {
            findUnique: (...a: unknown[]) => mockTidalFindUnique(...a),
        },
        trackYtMusic: {
            findUnique: (...a: unknown[]) => mockYtFindUnique(...a),
        },
    },
}));
jest.mock("../../trackMappingService", () => ({
    trackMappingService: {
        ensureRemoteTrack: (...a: unknown[]) => mockEnsureRemoteTrack(...a),
    },
}));

import {
    PlaybackInputError,
    playbackTrackInputSchema,
    resolvePlaybackInput,
} from "../playbackInput";

const METADATA = {
    title: "Song",
    artist: "Artist",
    album: "Album",
    durationSec: 215,
    artworkUrl: "https://img.example/a.jpg",
    isrc: "USRC17607839",
};

beforeEach(() => {
    jest.resetAllMocks();
});

async function rejection(promise: Promise<unknown>) {
    try {
        await promise;
    } catch (error) {
        return error as PlaybackInputError;
    }
    throw new Error("expected rejection");
}

describe("playbackTrackInputSchema", () => {
    it("accepts a playbackId with and without metadata", () => {
        expect(
            playbackTrackInputSchema.safeParse({ playbackId: "t.abc" }).success,
        ).toBe(true);
        expect(
            playbackTrackInputSchema.safeParse({
                playbackId: "td.5",
                metadata: METADATA,
            }).success,
        ).toBe(true);
    });

    it("rejects a missing playbackId and incomplete metadata", () => {
        expect(playbackTrackInputSchema.safeParse({}).success).toBe(false);
        expect(
            playbackTrackInputSchema.safeParse({
                playbackId: "td.5",
                metadata: { title: "x" },
            }).success,
        ).toBe(false);
    });
});

describe("resolvePlaybackInput", () => {
    it("resolves a local track to its id", async () => {
        mockTrackFindUnique.mockResolvedValue({ id: "abc" });
        await expect(
            resolvePlaybackInput("u1", { playbackId: "t.abc" }),
        ).resolves.toEqual({
            trackId: "abc",
            trackTidalId: null,
            trackYtMusicId: null,
        });
        expect(mockTrackFindUnique).toHaveBeenCalledWith({
            where: expect.objectContaining({ id: "abc" }),
        });
    });

    it("rejects a missing local track with TRACK_NOT_FOUND (404)", async () => {
        mockTrackFindUnique.mockResolvedValue(null);
        const error = await rejection(
            resolvePlaybackInput("u1", { playbackId: "t.nope" }),
        );
        expect(error).toBeInstanceOf(PlaybackInputError);
        expect(error.code).toBe("TRACK_NOT_FOUND");
        expect(error.status).toBe(404);
    });

    it("rejects an invalid playbackId with INVALID_PLAYBACK_ID (400)", async () => {
        const error = await rejection(
            resolvePlaybackInput("u1", { playbackId: "bogus" }),
        );
        expect(error.code).toBe("INVALID_PLAYBACK_ID");
        expect(error.status).toBe(400);
    });

    it("uses an existing TIDAL row and ignores metadata", async () => {
        mockTidalFindUnique.mockResolvedValue({ id: "row-td" });
        await expect(
            resolvePlaybackInput("u1", {
                playbackId: "td.77",
                metadata: METADATA,
            }),
        ).resolves.toEqual({
            trackId: null,
            trackTidalId: "row-td",
            trackYtMusicId: null,
        });
        expect(mockTidalFindUnique).toHaveBeenCalledWith({
            where: { tidalId: 77 },
            select: { id: true },
        });
        expect(mockEnsureRemoteTrack).not.toHaveBeenCalled();
    });

    it("creates a missing TIDAL row with the shared upsert arguments", async () => {
        mockTidalFindUnique.mockResolvedValue(null);
        mockEnsureRemoteTrack.mockResolvedValue({
            provider: "tidal",
            id: "new-td",
            created: true,
        });
        await expect(
            resolvePlaybackInput("u1", {
                playbackId: "td.77",
                metadata: METADATA,
            }),
        ).resolves.toEqual({
            trackId: null,
            trackTidalId: "new-td",
            trackYtMusicId: null,
        });
        expect(mockEnsureRemoteTrack).toHaveBeenCalledWith({
            provider: "tidal",
            tidalId: 77,
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 215,
            isrc: "USRC17607839",
            thumbnailUrl: "https://img.example/a.jpg",
        });
    });

    it("creates a missing YT Music row with the shared upsert arguments", async () => {
        mockYtFindUnique.mockResolvedValue(null);
        mockEnsureRemoteTrack.mockResolvedValue({
            provider: "youtube",
            id: "new-ym",
            created: true,
        });
        await expect(
            resolvePlaybackInput("u1", {
                playbackId: "ym.vid123",
                metadata: METADATA,
            }),
        ).resolves.toEqual({
            trackId: null,
            trackTidalId: null,
            trackYtMusicId: "new-ym",
        });
        expect(mockEnsureRemoteTrack).toHaveBeenCalledWith({
            provider: "youtube",
            videoId: "vid123",
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 215,
            isrc: "USRC17607839",
            thumbnailUrl: "https://img.example/a.jpg",
        });
    });

    it("uses an existing YT Music row without metadata", async () => {
        mockYtFindUnique.mockResolvedValue({ id: "row-ym" });
        await expect(
            resolvePlaybackInput("u1", { playbackId: "ym.vid123" }),
        ).resolves.toEqual({
            trackId: null,
            trackTidalId: null,
            trackYtMusicId: "row-ym",
        });
        expect(mockEnsureRemoteTrack).not.toHaveBeenCalled();
    });

    it.each(["td.77", "ym.vid123"])(
        "requires metadata to create a row for %s (METADATA_REQUIRED, 400)",
        async (playbackId) => {
            mockTidalFindUnique.mockResolvedValue(null);
            mockYtFindUnique.mockResolvedValue(null);
            const error = await rejection(
                resolvePlaybackInput("u1", { playbackId }),
            );
            expect(error.code).toBe("METADATA_REQUIRED");
            expect(error.status).toBe(400);
            expect(mockEnsureRemoteTrack).not.toHaveBeenCalled();
        },
    );

    it("rejects plain YouTube ids with SOURCE_UNAVAILABLE (409)", async () => {
        const error = await rejection(
            resolvePlaybackInput("u1", {
                playbackId: "yt.vid123",
                metadata: METADATA,
            }),
        );
        expect(error.code).toBe("SOURCE_UNAVAILABLE");
        expect(error.status).toBe(409);
    });
});
