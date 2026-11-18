import { Request, Response } from "express";

jest.mock("../../middleware/auth", () => ({
    requireAuth: (_req: Request, _res: Response, next: () => void) => next(),
}));

jest.mock("../../utils/logger", () => {
    const scoped = {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    };
    return { logger: { ...scoped, child: jest.fn(() => scoped) } };
});

jest.mock("../../utils/db", () => ({ prisma: {} }));

jest.mock("../../utils/redis", () => ({
    redisClient: { get: jest.fn(), setEx: jest.fn() },
}));

jest.mock("../../services/searchCacheVersion", () => ({
    getSearchCacheVersion: jest.fn(async () => 7),
}));

jest.mock("../../services/lastfm", () => ({ lastFmService: {} }));

jest.mock("axios", () => ({ __esModule: true, default: { get: jest.fn() } }));

jest.mock("../../utils/systemSettings", () => ({
    getSystemSettings: jest.fn(async () => ({})),
}));

jest.mock("../../services/discoverMusicSearch", () => ({
    resolveUsableSearchProviders: jest.fn(),
    searchDiscoverMusic: jest.fn(),
}));

jest.mock("../../services/search", () => ({
    searchService: {
        searchAll: jest.fn(),
        searchByType: jest.fn(),
        searchArtists: jest.fn(),
        searchAlbums: jest.fn(),
        searchTracks: jest.fn(),
        searchPodcastsFTS: jest.fn(),
    },
    normalizeCacheQuery: (query: string) => query.trim().toLowerCase(),
}));

jest.mock("../../services/remoteLibrary/remoteLibrarySearch", () => ({
    searchRemoteLibrary: jest.fn(),
}));

jest.mock("../../services/playlistSearch", () => ({
    searchPlaylists: jest.fn(),
}));

import axios from "axios";
import router from "../search";
import { redisClient } from "../../utils/redis";
import { searchService } from "../../services/search";
import { searchRemoteLibrary } from "../../services/remoteLibrary/remoteLibrarySearch";
import { searchPlaylists } from "../../services/playlistSearch";
import {
    resolveUsableSearchProviders,
    searchDiscoverMusic,
} from "../../services/discoverMusicSearch";
import { getSearchCacheVersion } from "../../services/searchCacheVersion";
import { withClientSurfaceValidation } from "./helpers/expectClientSurfaceResponse";

const mocks = {
    redisGet: redisClient.get as jest.Mock,
    redisSetEx: redisClient.setEx as jest.Mock,
    artists: searchService.searchArtists as jest.Mock,
    albums: searchService.searchAlbums as jest.Mock,
    tracks: searchService.searchTracks as jest.Mock,
    podcasts: searchService.searchPodcastsFTS as jest.Mock,
    searchAll: searchService.searchAll as jest.Mock,
    remote: searchRemoteLibrary as jest.Mock,
    playlists: searchPlaylists as jest.Mock,
    providers: resolveUsableSearchProviders as jest.Mock,
    discover: searchDiscoverMusic as jest.Mock,
    axiosGet: (axios as any).get as jest.Mock,
};

function getGetHandler(path: string) {
    const layer = (router as any).stack.find(
        (entry: any) => entry.route?.path === path && entry.route?.methods?.get,
    );
    if (!layer) throw new Error(`Route not found: ${path}`);
    return layer.route.stack[layer.route.stack.length - 1].handle;
}

function createRes() {
    const res: any = {
        statusCode: 200,
        body: undefined as unknown,
        status: jest.fn((code: number) => {
            res.statusCode = code;
            return res;
        }),
        json: jest.fn((payload: unknown) => {
            res.body = payload;
            return res;
        }),
    };
    return res;
}

const unified = withClientSurfaceValidation(
    "searchUnified",
    getGetHandler("/unified"),
);

async function search(query: Record<string, unknown>, userId = "user-1") {
    const res = createRes();
    await unified({ query, user: { id: userId } } as any, res);
    return res;
}

function artist(id: string, name: string, rank: number, extra: object = {}) {
    return {
        id,
        name,
        mbid: null,
        heroUrl: null,
        rank,
        source: "local",
        ...extra,
    };
}

function album(id: string, title: string, rank: number) {
    return {
        id,
        title,
        artistId: "ar-radiohead",
        artistName: "Radiohead",
        year: 1997,
        coverUrl: null,
        rank,
        source: "local",
    };
}

function track(id: string, title: string, rank: number) {
    return {
        id,
        title,
        albumId: "al-ok",
        albumTitle: "OK Computer",
        artistId: "ar-radiohead",
        artistName: "Radiohead",
        duration: 240,
        rank,
        source: "local",
    };
}

function playlistHit(id: string, name: string, similarity: number) {
    return {
        similarity,
        playlist: {
            id,
            userId: "user-1",
            name,
            isPublic: false,
            createdAt: "2026-11-01T00:00:00.000Z",
            updatedAt: "2026-11-01T00:00:00.000Z",
            user: { username: "owner" },
            isOwner: true,
            isHidden: false,
            trackCount: 3,
            items: [],
        },
    };
}

function itunesResponse(names: string[]) {
    return {
        data: {
            results: names.map((name, index) => ({
                collectionId: 1000 + index,
                collectionName: name,
                artistName: "Host",
                description: "",
                artworkUrl100: "https://example.test/a.jpg",
                feedUrl: "https://example.test/feed",
                genres: [],
                trackCount: 10,
            })),
        },
    };
}

beforeEach(() => {
    jest.clearAllMocks();
    mocks.redisGet.mockResolvedValue(null);
    mocks.redisSetEx.mockResolvedValue("OK");
    mocks.artists.mockResolvedValue([]);
    mocks.albums.mockResolvedValue([]);
    mocks.tracks.mockResolvedValue([]);
    mocks.podcasts.mockResolvedValue([]);
    mocks.remote.mockResolvedValue({ tracks: [], albums: [] });
    mocks.playlists.mockResolvedValue([]);
    mocks.providers.mockImplementation(
        async (providers: string[]) => providers,
    );
    mocks.discover.mockResolvedValue({ artists: [], tracks: [] });
    mocks.axiosGet.mockResolvedValue(itunesResponse([]));
});

describe("GET /api/search/unified", () => {
    it("puts the exact artist first and mixes their albums and tracks by score", async () => {
        mocks.artists.mockResolvedValue([
            artist("ar-radiohead", "Radiohead", 0.1),
        ]);
        mocks.albums.mockResolvedValue([
            album("al-ok", "OK Computer", 0.06),
            album("al-kid", "Kid A", 0.02),
        ]);
        mocks.tracks.mockResolvedValue([track("tr-creep", "Creep", 0.3)]);
        mocks.discover.mockResolvedValue({
            artists: [
                {
                    type: "music",
                    id: "dz-1",
                    name: "Radiohead",
                    source: "deezer",
                },
            ],
            tracks: [],
        });
        mocks.playlists.mockResolvedValue([
            playlistHit("pl-1", "Radiohead Essentials", 0.5),
        ]);

        const res = await search({ q: "radiohead" });

        expect(res.statusCode).toBe(200);
        const { items, hasMore } = res.body;
        expect(items[0]).toMatchObject({
            kind: "artist",
            source: "library",
            artist: { id: "ar-radiohead", name: "Radiohead" },
        });
        expect(items[1]).toMatchObject({
            kind: "playlist",
            playlist: { id: "pl-1" },
        });
        expect(items.slice(2).map((item: any) => item.kind)).toEqual([
            "track",
            "album",
            "album",
        ]);
        expect(
            items.filter((item: any) => item.source === "catalogue"),
        ).toEqual([]);
        const scores = items.map((item: any) => item.score);
        expect(scores).toEqual([...scores].sort((a, b) => b - a));
        expect(items[2].track).toMatchObject({
            id: "tr-creep",
            playbackId: expect.any(String),
        });
        expect(items[0].artist).not.toHaveProperty("matchedBy");
        expect(hasMore).toBe(false);
        expect(mocks.artists).toHaveBeenCalledWith({
            query: "radiohead",
            limit: 60,
            offset: 0,
        });
    });

    it("folds diacritics so a catalogue Björk loses to the library Bjork", async () => {
        mocks.artists.mockResolvedValue([artist("ar-bjork", "Bjork", 0.05)]);
        mocks.discover.mockResolvedValue({
            artists: [
                {
                    type: "music",
                    id: "dz-bjork",
                    name: "Björk",
                    source: "deezer",
                },
            ],
            tracks: [
                {
                    type: "track",
                    id: "td-1",
                    name: "Army of Me",
                    artist: "Björk",
                    album: "Post",
                    source: "tidal",
                    playbackId: "td.1",
                },
            ],
        });

        const res = await search({ q: "Björk" });

        expect(
            res.body.items.map((item: any) => `${item.kind}:${item.source}`),
        ).toEqual(["artist:library", "track:catalogue"]);
        expect(res.body.items[1].catalogue).toMatchObject({
            playbackId: "td.1",
        });
    });

    it("drops a catalogue track that matches a liked streaming track by playbackId", async () => {
        mocks.remote.mockResolvedValue({
            tracks: [
                {
                    id: "rt-1",
                    playbackId: "td.42",
                    title: "Teardrop",
                    duration: 300,
                    trackNo: null,
                    artist: { id: null, name: "Massive Attack" },
                    album: {
                        id: null,
                        title: "Mezzanine",
                        coverArt: null,
                        rgMbid: null,
                        matchedRgMbid: null,
                        matchedInLibrary: false,
                        coverUrl: null,
                        artistId: null,
                        artist: { id: null, name: "Massive Attack" },
                    },
                    streamSource: "tidal",
                    albumId: null,
                    artistId: null,
                    trackNumber: null,
                },
            ],
            albums: [],
        });
        mocks.discover.mockResolvedValue({
            artists: [],
            tracks: [
                {
                    type: "track",
                    id: "td-42",
                    name: "Teardrop (Remastered)",
                    artist: "Massive Attack",
                    album: null,
                    source: "tidal",
                    playbackId: "td.42",
                },
            ],
        });

        const res = await search({ q: "teardrop", type: "tracks" });

        expect(res.body.items).toHaveLength(1);
        expect(res.body.items[0]).toMatchObject({
            kind: "track",
            source: "library",
            remoteTrack: { playbackId: "td.42" },
        });
    });

    it.each([
        ["tracks", "track"],
        ["artists", "artist"],
        ["albums", "album"],
        ["playlists", "playlist"],
        ["podcasts", "podcast"],
    ] as const)("type=%s returns only %s items", async (type, kind) => {
        mocks.artists.mockResolvedValue([artist("ar-1", "Low", 0.1)]);
        mocks.albums.mockResolvedValue([album("al-1", "Low", 0.1)]);
        mocks.tracks.mockResolvedValue([track("tr-1", "Low", 0.1)]);
        mocks.podcasts.mockResolvedValue([
            {
                id: "pod-1",
                title: "Low Tide",
                author: null,
                description: null,
                imageUrl: null,
                episodeCount: 4,
                rank: 0.1,
            },
        ]);
        mocks.playlists.mockResolvedValue([playlistHit("pl-1", "Low", 0.9)]);
        mocks.axiosGet.mockResolvedValue(itunesResponse(["Low Energy"]));

        const res = await search({ q: "low", type });

        expect(res.statusCode).toBe(200);
        expect(res.body.items.length).toBeGreaterThan(0);
        expect(new Set(res.body.items.map((item: any) => item.kind))).toEqual(
            new Set([kind]),
        );
    });

    it("pages a single type by offset and limit and reports hasMore", async () => {
        mocks.tracks.mockResolvedValue([
            track("tr-1", "Song", 0.5),
            track("tr-2", "Song", 0.4),
            track("tr-3", "Song", 0.3),
            track("tr-4", "Song", 0.2),
            track("tr-5", "Song", 0.1),
        ]);

        const page = await search({
            q: "song",
            type: "tracks",
            limit: "2",
            offset: "2",
        });

        expect(page.body.items.map((item: any) => item.track.id)).toEqual([
            "tr-3",
            "tr-4",
        ]);
        expect(page.body.hasMore).toBe(true);
        expect(mocks.tracks).toHaveBeenCalledWith({
            query: "song",
            limit: 5,
            offset: 0,
        });
        expect(mocks.artists).not.toHaveBeenCalled();
        expect(mocks.playlists).not.toHaveBeenCalled();

        const last = await search({
            q: "song",
            type: "tracks",
            limit: "2",
            offset: "4",
        });
        expect(last.body.items.map((item: any) => item.track.id)).toEqual([
            "tr-5",
        ]);
        expect(last.body.hasMore).toBe(false);
    });

    it("cuts type=all to limit, ignores offset and reports hasMore", async () => {
        mocks.tracks.mockResolvedValue([
            track("tr-1", "Song", 0.3),
            track("tr-2", "Song", 0.2),
            track("tr-3", "Song", 0.1),
        ]);

        const res = await search({ q: "song", limit: "2", offset: "40" });

        expect(res.body.items.map((item: any) => item.track.id)).toEqual([
            "tr-1",
            "tr-2",
        ]);
        expect(res.body.hasMore).toBe(true);
        expect(mocks.tracks).toHaveBeenCalledWith({
            query: "song",
            limit: 4,
            offset: 0,
        });
    });

    it.each([
        ["a missing q", {}],
        ["a q over 500 characters", { q: "x".repeat(501) }],
        ["an unknown type", { q: "low", type: "episodes" }],
        ["limit 0", { q: "low", limit: "0" }],
        ["limit 101", { q: "low", limit: "101" }],
        ["a non-numeric limit", { q: "low", limit: "many" }],
        ["a negative offset", { q: "low", offset: "-1" }],
        ["an offset over 1000", { q: "low", type: "tracks", offset: "1001" }],
    ])("answers 400 for %s", async (_label, query) => {
        const res = await search(query);

        expect(res.statusCode).toBe(400);
        expect(res.body).toEqual({ error: "Invalid search query" });
        expect(mocks.tracks).not.toHaveBeenCalled();
    });

    it("returns no items for a blank q without searching", async () => {
        const res = await search({ q: "   " });

        expect(res.body).toEqual({ items: [], hasMore: false });
        expect(mocks.artists).not.toHaveBeenCalled();
        expect(mocks.redisGet).not.toHaveBeenCalled();
    });

    it("degrades to library results when catalogue and remote searches fail", async () => {
        mocks.tracks.mockResolvedValue([track("tr-1", "Creep", 0.2)]);
        mocks.discover.mockRejectedValue(new Error("deezer down"));
        mocks.axiosGet.mockRejectedValue(new Error("itunes down"));
        mocks.remote.mockRejectedValue(new Error("tidal down"));
        mocks.playlists.mockRejectedValue(new Error("db hiccup"));

        const res = await search({ q: "creep" });

        expect(res.statusCode).toBe(200);
        expect(res.body.items.map((item: any) => item.kind)).toEqual(["track"]);
    });

    it("skips the catalogue when no search provider is usable", async () => {
        mocks.providers.mockResolvedValue([]);

        await search({ q: "creep" });

        expect(mocks.discover).not.toHaveBeenCalled();
    });

    it("serves a per-user cache hit without searching", async () => {
        mocks.redisGet.mockResolvedValue(
            JSON.stringify({ items: [], hasMore: false }),
        );

        const res = await search(
            { q: "Creep", type: "tracks", limit: "10", offset: "20" },
            "user-9",
        );

        expect(res.body).toEqual({ items: [], hasMore: false });
        expect(mocks.redisGet).toHaveBeenCalledWith(
            "search:unified:v7:user-9:tracks:10:20:creep",
        );
        expect(mocks.tracks).not.toHaveBeenCalled();
    });

    it("caches a computed page under the user's key", async () => {
        await search({ q: "Creep" }, "user-3");

        expect(mocks.redisSetEx).toHaveBeenCalledWith(
            "search:unified:v7:user-3:all:30:0:creep",
            120,
            JSON.stringify({ items: [], hasMore: false }),
        );
    });

    it("answers 500 when the search cannot run at all", async () => {
        (getSearchCacheVersion as jest.Mock).mockRejectedValueOnce(
            new Error("redis down"),
        );

        const res = await search({ q: "creep" });

        expect(res.statusCode).toBe(500);
        expect(res.body).toEqual({ error: "Search failed" });
    });
});

describe("GET /api/search", () => {
    it("does not expose the trigram marker on artists", async () => {
        mocks.searchAll.mockResolvedValue({
            artists: [
                artist("ar-1", "Radiohead", 0.4, { matchedBy: "trigram" }),
            ],
            albums: [],
            tracks: [],
            podcasts: [],
            audiobooks: [],
            episodes: [],
        });
        const res = createRes();

        await getGetHandler("/")(
            { query: { q: "radiohed" }, user: { id: "user-1" } },
            res,
        );

        expect(res.body.artists[0]).not.toHaveProperty("matchedBy");
        expect(res.body.artists[0]).toMatchObject({ id: "ar-1", rank: 0.4 });
    });
});
