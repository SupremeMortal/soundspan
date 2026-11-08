const mockAlbumFindFirst = jest.fn();
const mockPlaylistFindUnique = jest.fn();
const mockPolicy = jest.fn();
const mockResolvePlayback = jest.fn();
const mockStreamInfo = jest.fn();

jest.mock("../../../utils/db", () => ({
    prisma: {
        album: { findFirst: (...a: unknown[]) => mockAlbumFindFirst(...a) },
        playlist: {
            findUnique: (...a: unknown[]) => mockPlaylistFindUnique(...a),
        },
    },
    Prisma: { SortOrder: { asc: "asc", desc: "desc" } },
}));
jest.mock("../offlinePolicy", () => ({
    resolveOfflinePolicy: (...a: unknown[]) => mockPolicy(...a),
}));
jest.mock("../../playback/resolvePlayback", () => ({
    PlaybackResolutionError: class PlaybackResolutionError extends Error {
        constructor(
            readonly code: string,
            message: string,
        ) {
            super(message);
        }
    },
    resolvePlayback: (...a: unknown[]) => mockResolvePlayback(...a),
}));
jest.mock("../../playback/playbackStreamInfo", () => ({
    getPlaybackStreamInfo: (...a: unknown[]) => mockStreamInfo(...a),
}));

import { PlaybackResolutionError } from "../../playback/resolvePlayback";
import { OfflineItemsError, resolveOfflineItems } from "../resolveOfflineItems";

const SIZES: Record<string, number | null> = {
    "t.local1": 1000,
    "t.fed1": 2000,
    "td.77": 3000,
    "ym.vid1": 4000,
    "yt.vid2": null,
};

function localTrack(id: string, origin = "LOCAL") {
    return { id, origin, title: id, federationPeer: null };
}

function mixedAlbum() {
    return {
        id: "alb1",
        title: "Album",
        location: "REMOTE",
        coverUrl: null,
        artist: { id: "art", name: "Artist" },
        tracks: [localTrack("local1"), localTrack("fed1", "FEDERATED")],
        tracksTidal: [
            {
                id: "tt",
                tidalId: 77,
                title: "T",
                artist: "A",
                album: "Al",
                duration: 1,
                artistId: null,
                mappings: [],
            },
        ],
        tracksYtMusic: [
            {
                id: "yy",
                videoId: "vid1",
                title: "Y",
                artist: "A",
                album: "Al",
                duration: 1,
                artistId: null,
                thumbnailUrl: null,
                mappings: [],
            },
        ],
    };
}

describe("resolveOfflineItems", () => {
    beforeEach(() => {
        jest.resetAllMocks();
        mockPolicy.mockResolvedValue({ downloadable: true });
        mockResolvePlayback.mockImplementation(
            async (_u: string, { parsed, quality }: any) => ({
                kind: parsed.kind,
                libraryQuality: quality ?? "medium",
            }),
        );
        mockStreamInfo.mockImplementation(async ({ playbackId, res }: any) => {
            res.json({
                playbackId,
                contentType: "audio/mpeg",
                contentLength: SIZES[playbackId],
                quality: "medium",
            });
        });
    });

    it("resolves a track playbackId into one downloadable item", async () => {
        const out = await resolveOfflineItems({
            userId: "u1",
            kind: "track",
            id: "t.local1",
            quality: "high",
        });
        expect(out).toEqual({
            items: [
                {
                    playbackId: "t.local1",
                    downloadable: true,
                    downloadUrl: "/api/playback/stream/t.local1?quality=medium",
                    expectedSize: 1000,
                    quality: "medium",
                    contentType: "audio/mpeg",
                },
            ],
            estimatedTotalBytes: 1000,
        });
        expect(mockResolvePlayback).toHaveBeenCalledWith("u1", {
            parsed: { kind: "t", trackId: "local1" },
            quality: "high",
        });
    });

    it("rejects an invalid playbackId for kind track", async () => {
        await expect(
            resolveOfflineItems({ userId: "u1", kind: "track", id: "nope" }),
        ).rejects.toMatchObject({ status: 400, code: "INVALID_PLAYBACK_ID" });
    });

    it("returns a mixed-source album in order with one source disabled", async () => {
        mockAlbumFindFirst.mockResolvedValue(mixedAlbum());
        mockPolicy.mockImplementation(async (_u: string, parsed: any) =>
            parsed.kind === "td"
                ? { downloadable: false, reason: "SOURCE_DOWNLOADS_DISABLED" }
                : { downloadable: true },
        );
        const out = await resolveOfflineItems({
            userId: "u1",
            kind: "album",
            id: "alb1",
        });
        expect(out.items.map((i) => i.playbackId)).toEqual([
            "t.local1",
            "t.fed1",
            "td.77",
            "ym.vid1",
        ]);
        expect(out.items[2]).toEqual({
            playbackId: "td.77",
            downloadable: false,
            reason: "SOURCE_DOWNLOADS_DISABLED",
        });
        expect(out.estimatedTotalBytes).toBe(1000 + 2000 + 4000);
        expect(mockStreamInfo).not.toHaveBeenCalledWith(
            expect.objectContaining({ playbackId: "td.77" }),
        );
    });

    it("throws a 404 for a missing album", async () => {
        mockAlbumFindFirst.mockResolvedValue(null);
        await expect(
            resolveOfflineItems({ userId: "u1", kind: "album", id: "x" }),
        ).rejects.toMatchObject({ status: 404, code: "ALBUM_NOT_FOUND" });
    });

    it("returns a mixed-source playlist in sort order", async () => {
        mockPlaylistFindUnique.mockResolvedValue({
            userId: "u1",
            isPublic: false,
            items: [
                {
                    trackId: null,
                    trackTidal: { tidalId: 77 },
                    trackYtMusic: null,
                },
                { trackId: "local1", trackTidal: null, trackYtMusic: null },
                {
                    trackId: null,
                    trackTidal: null,
                    trackYtMusic: { videoId: "vid1" },
                },
            ],
        });
        const out = await resolveOfflineItems({
            userId: "u1",
            kind: "playlist",
            id: "pl1",
        });
        expect(out.items.map((i) => i.playbackId)).toEqual([
            "td.77",
            "t.local1",
            "ym.vid1",
        ]);
        expect(out.estimatedTotalBytes).toBe(3000 + 1000 + 4000);
    });

    it("hides another user's private playlist as not found", async () => {
        mockPlaylistFindUnique.mockResolvedValue({
            userId: "other",
            isPublic: false,
            items: [],
        });
        await expect(
            resolveOfflineItems({ userId: "u1", kind: "playlist", id: "pl1" }),
        ).rejects.toMatchObject({ status: 404, code: "PLAYLIST_NOT_FOUND" });
    });

    it("throws a 404 for a missing playlist", async () => {
        mockPlaylistFindUnique.mockResolvedValue(null);
        await expect(
            resolveOfflineItems({ userId: "u1", kind: "playlist", id: "x" }),
        ).rejects.toBeInstanceOf(OfflineItemsError);
    });

    it("marks items unavailable when resolution or stream info fails", async () => {
        mockPlaylistFindUnique.mockResolvedValue({
            userId: "u1",
            isPublic: true,
            items: [
                {
                    trackId: null,
                    trackTidal: { tidalId: 77 },
                    trackYtMusic: null,
                },
                { trackId: "local1", trackTidal: null, trackYtMusic: null },
            ],
        });
        mockResolvePlayback.mockImplementation(
            async (_u: string, { parsed }: any) => {
                if (parsed.kind === "td") {
                    throw new PlaybackResolutionError(
                        "SOURCE_UNAVAILABLE",
                        "down",
                    );
                }
                return { kind: "t", libraryQuality: "medium" };
            },
        );
        mockStreamInfo.mockImplementation(async ({ res }: any) => {
            res.status(404).json({ error: "gone", code: "TRACK_NOT_FOUND" });
        });
        const out = await resolveOfflineItems({
            userId: "u1",
            kind: "playlist",
            id: "pl1",
        });
        expect(out.items).toEqual([
            {
                playbackId: "td.77",
                downloadable: false,
                reason: "SOURCE_UNAVAILABLE",
            },
            {
                playbackId: "t.local1",
                downloadable: false,
                reason: "TRACK_UNAVAILABLE",
            },
        ]);
        expect(out.estimatedTotalBytes).toBe(0);
    });
});
