import type { NextFunction, Request, Response } from "express";
import request from "supertest";

const AUTH_HEADER = "x-test-auth";
const AUTH_VALUE = "ok";
const TEST_USER_ID = "user-1";

// ── Auth mock ────────────────────────────────────────────────────

jest.mock("../../middleware/auth", () => ({
    requireAuth: (req: Request, res: Response, next: NextFunction) => {
        if (req.header(AUTH_HEADER) !== AUTH_VALUE) {
            return res.status(401).json({ error: "Not authenticated" });
        }
        req.user = { id: TEST_USER_ID, username: "tester", role: "user" };
        next();
    },
    requireAdmin: (_req: Request, _res: Response, next: NextFunction) => next(),
    requireAuthOrToken: (req: Request, res: Response, next: NextFunction) => {
        if (req.header(AUTH_HEADER) !== AUTH_VALUE) {
            return res.status(401).json({ error: "Not authenticated" });
        }
        req.user = { id: TEST_USER_ID, username: "tester", role: "user" };
        next();
    },
}));

jest.mock("../../middleware/rateLimiter", () => ({
    coverArtLimiter: (_req: Request, _res: Response, next: NextFunction) =>
        next(),
    libraryMetadataLimiter: (
        _req: Request,
        _res: Response,
        next: NextFunction,
    ) => next(),
    streamingLimiter: (_req: Request, _res: Response, next: NextFunction) =>
        next(),
}));

// ── Logging ──────────────────────────────────────────────────────

jest.mock("../../utils/logger", () => {
    const logger = {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
        child: jest.fn(),
    };
    logger.child.mockReturnValue(logger);
    return { logger };
});

// ── Prisma ───────────────────────────────────────────────────────

const mockPrisma = {
    likedRemoteTrack: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
    },
    remoteLikedTrack: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
    },
    // Stubs required by library.ts imports even though not used in these tests
    track: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        delete: jest.fn(),
        deleteMany: jest.fn(),
    },
    trackTidal: { findUnique: jest.fn(), upsert: jest.fn() },
    trackYtMusic: { findUnique: jest.fn(), upsert: jest.fn() },
    likedTrack: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        upsert: jest.fn(),
        createMany: jest.fn(),
        deleteMany: jest.fn(),
    },
    dislikedEntity: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        upsert: jest.fn(),
        createMany: jest.fn(),
        deleteMany: jest.fn(),
    },
    play: {
        findFirst: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        groupBy: jest.fn(),
    },
    userSettings: { findUnique: jest.fn() },
    artist: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        count: jest.fn(),
        updateMany: jest.fn(),
        update: jest.fn(),
        deleteMany: jest.fn(),
        delete: jest.fn(),
    },
    album: {
        findMany: jest.fn(),
        groupBy: jest.fn(),
        count: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        delete: jest.fn(),
        update: jest.fn(),
    },
    audiobookProgress: { findMany: jest.fn() },
    podcastProgress: { findMany: jest.fn() },
    ownedAlbum: {
        groupBy: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        deleteMany: jest.fn(),
    },
    genre: { findMany: jest.fn() },
    similarArtist: { findMany: jest.fn(), deleteMany: jest.fn() },
    $transaction: jest.fn(),
    $queryRaw: jest.fn(),
};

jest.mock("../../utils/db", () => ({
    prisma: mockPrisma,
    Prisma: {
        SortOrder: { asc: "asc", desc: "desc" },
        DbNull: null,
    },
}));

// ── Redis ────────────────────────────────────────────────────────

jest.mock("../../utils/redis", () => ({
    redisClient: { get: jest.fn(), setEx: jest.fn() },
}));

// ── Config ───────────────────────────────────────────────────────

jest.mock("../../config", () => ({
    config: {
        music: {
            musicPath: "/music",
            transcodeCachePath: "/tmp/soundspan-cache",
            transcodeCacheMaxGb: 1,
        },
    },
}));

// ── Service stubs (not exercised in remote-pref tests) ──────────

jest.mock("../../workers/queues", () => ({
    scanQueue: { add: jest.fn(), getJob: jest.fn() },
}));
jest.mock("../../workers/organizeSingles", () => ({
    organizeSingles: jest.fn(),
}));
jest.mock("../../services/lastfm", () => ({
    lastFmService: {
        getArtistTopTracks: jest.fn(),
        getSimilarArtists: jest.fn(),
    },
}));
jest.mock("../../services/fanart", () => ({ fanartService: {} }));
jest.mock("../../services/deezer", () => ({
    deezerService: { getAlbumCover: jest.fn(), getArtistImage: jest.fn() },
}));
jest.mock("../../services/imageProvider", () => ({
    imageProviderService: { getAlbumCover: jest.fn() },
}));
jest.mock("../../services/musicbrainz", () => ({
    musicBrainzService: {
        searchArtist: jest.fn(),
        getReleaseGroups: jest.fn(),
    },
}));
jest.mock("../../services/coverArt", () => ({
    coverArtService: { getCoverArt: jest.fn(), clearNotFoundCache: jest.fn() },
}));
jest.mock("../../utils/systemSettings", () => ({
    getSystemSettings: jest.fn(),
}));
jest.mock("../../services/audioStreaming", () => ({
    AudioStreamingService: jest.fn().mockImplementation(() => ({
        getStreamFilePath: jest.fn(),
        streamFileWithRangeSupport: jest.fn(),
        destroy: jest.fn(),
    })),
}));
jest.mock("../../services/dataCache", () => ({
    dataCacheService: {
        getArtistImagesBatch: jest.fn(),
        getArtistImage: jest.fn(),
    },
}));
jest.mock("../../services/artistCountsService", () => ({
    backfillAllArtistCounts: jest.fn(),
    isBackfillNeeded: jest.fn(),
    getBackfillProgress: jest.fn(),
    isBackfillInProgress: jest.fn(),
}));
jest.mock("../../services/imageBackfill", () => ({
    isImageBackfillNeeded: jest.fn(),
    getImageBackfillProgress: jest.fn(),
    backfillAllImages: jest.fn(),
}));
jest.mock("../../utils/metadataOverrides", () => ({
    getMergedGenres: jest.fn(() => []),
    getArtistDisplaySummary: jest.fn(() => ""),
}));
jest.mock("../../utils/dateFilters", () => ({
    getEffectiveYear: jest.fn(),
    getDecadeWhereClause: jest.fn(),
    getDecadeFromYear: jest.fn(),
}));
jest.mock("../../utils/shuffle", () => ({
    shuffleArray: jest.fn((arr: unknown[]) => arr),
}));
jest.mock("../../utils/colorExtractor", () => ({
    extractColorsFromImage: jest.fn(async () => ({
        vibrant: "#000",
        darkVibrant: "#000",
        lightVibrant: "#000",
        muted: "#000",
        darkMuted: "#000",
        lightMuted: "#000",
    })),
}));
jest.mock("../../services/imageProxy", () => ({
    fetchExternalImage: jest.fn(),
    normalizeExternalImageUrl: jest.fn(() => null),
}));
jest.mock("../../services/imageStorage", () => ({
    downloadAndStoreImage: jest.fn(),
}));
jest.mock("../../services/lidarr", () => ({
    lidarrService: { deleteArtist: jest.fn() },
}));
jest.mock("music-metadata", () => ({ parseFile: jest.fn() }), {
    virtual: true,
});
jest.mock("../../services/trackMappingService", () => ({
    trackMappingService: {
        ensureRemoteTrack: jest.fn(),
    },
}));

jest.mock("../../services/remoteTrackMetadataResolver", () => ({
    resolveRemoteTrackMetadataForRequest: jest.fn(
        async ({ metadata }: any) => ({
            title: metadata.title ?? "Unknown",
            artist: metadata.artist ?? "Unknown",
            album: metadata.album ?? "Unknown",
            duration: metadata.duration ?? 180,
            thumbnailUrl: metadata.thumbnailUrl,
            isrc: metadata.isrc,
            explicit: metadata.explicit,
            quality: metadata.quality,
        }),
    ),
}));

// ── Router under test ────────────────────────────────────────────

jest.mock("../../services/metadata/catalogPersistence", () => ({
    findFreshCatalogAlbum: jest.fn(async () => null),
    findFreshArtistCatalogReleaseGroups: jest.fn(async () => null),
    findFreshCatalogReleaseGroups: jest.fn(async () => null),
    logCatalogPersistenceError: jest.fn(),
    persistCatalogReleaseGroups: jest.fn(async () => undefined),
    persistCatalogTracklist: jest.fn(async () => undefined),
}));

import router from "../library";
import { createRouteTestApp } from "./helpers/createRouteTestApp";
import { errorHandler } from "../../middleware/errorHandler";
import { trackMappingService } from "../../services/trackMappingService";
import { resolveRemoteTrackMetadataForRequest } from "../../services/remoteTrackMetadataResolver";

const app = createRouteTestApp("/api/library", router);
// Mount the real errorHandler after the router, as index.ts does in
// production: asyncHandler-migrated routes surface unexpected failures via
// next(err) -> errorHandler instead of responding from an inline catch.
app.use(errorHandler);
const mockEnsureRemoteTrack =
    trackMappingService.ensureRemoteTrack as jest.Mock;
const mockResolveRemoteTrackMetadataForRequest =
    resolveRemoteTrackMetadataForRequest as jest.Mock;

const post = (body: unknown) =>
    request(app)
        .post("/api/library/preferences")
        .set(AUTH_HEADER, AUTH_VALUE)
        .send(body as object);

describe("POST /api/library/preferences (playbackId)", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockPrisma.track.findUnique.mockResolvedValue({ id: "track-1" });
        mockPrisma.trackTidal.findUnique.mockResolvedValue(null);
        mockPrisma.trackYtMusic.findUnique.mockResolvedValue(null);
        mockEnsureRemoteTrack.mockImplementation(async (input: any) => ({
            provider: input.provider,
            id: input.provider === "tidal" ? "tt-1" : "ym-1",
            created: true,
        }));
        mockResolveRemoteTrackMetadataForRequest.mockImplementation(
            async ({ metadata }: any) => ({
                title: metadata.title ?? "Unknown",
                artist: metadata.artist ?? "Unknown",
                album: metadata.album ?? "Unknown",
                duration: metadata.duration ?? 180,
                thumbnailUrl: metadata.thumbnailUrl,
            }),
        );
    });

    it("requires authentication", async () => {
        const res = await request(app)
            .post("/api/library/preferences")
            .send({ playbackId: "t.track-1", signal: "thumbs_up" });
        expect(res.status).toBe(401);
    });

    it("likes a local track with the same writes as the legacy route", async () => {
        const legacy = await request(app)
            .post("/api/library/tracks/track-1/preference")
            .set(AUTH_HEADER, AUTH_VALUE)
            .send({ signal: "thumbs_up" });
        const legacyCalls = mockPrisma.likedTrack.upsert.mock.calls.map(
            ([arg]: any) => ({ where: arg.where, userId: arg.create.userId }),
        );
        mockPrisma.likedTrack.upsert.mockClear();

        const res = await post({
            playbackId: "t.track-1",
            signal: "thumbs_up",
        });

        expect(res.status).toBe(200);
        const calls = mockPrisma.likedTrack.upsert.mock.calls.map(
            ([arg]: any) => ({ where: arg.where, userId: arg.create.userId }),
        );
        expect(calls).toEqual(legacyCalls);
        expect(res.body).toMatchObject({
            trackId: "track-1",
            signal: legacy.body.signal,
            state: legacy.body.state,
            playbackId: "t.track-1",
        });
    });

    it("dislikes and clears a local track", async () => {
        const down = await post({
            playbackId: "t.track-1",
            signal: "thumbs_down",
        });
        expect(down.status).toBe(200);
        expect(mockPrisma.dislikedEntity.upsert).toHaveBeenCalledTimes(1);

        const clear = await post({ playbackId: "t.track-1", signal: "clear" });
        expect(clear.status).toBe(200);
        expect(mockPrisma.likedTrack.deleteMany).toHaveBeenCalled();
    });

    it("likes a TIDAL track like the legacy remote route", async () => {
        const metadata = {
            title: "Song",
            artist: "Artist",
            album: "Album",
            durationSec: 200,
        };
        const res = await post({
            playbackId: "td.12345",
            signal: "thumbs_up",
            metadata,
        });

        expect(res.status).toBe(200);
        expect(mockEnsureRemoteTrack).toHaveBeenCalledWith(
            expect.objectContaining({
                provider: "tidal",
                tidalId: 12345,
                title: "Song",
                duration: 200,
            }),
        );
        expect(mockPrisma.likedRemoteTrack.upsert).toHaveBeenCalledWith(
            expect.objectContaining({
                where: {
                    userId_trackTidalId: {
                        userId: TEST_USER_ID,
                        trackTidalId: "tt-1",
                    },
                },
            }),
        );
        expect(res.body.playbackId).toBe("td.12345");
    });

    it("likes a YT Music track like the legacy remote route", async () => {
        const res = await post({
            playbackId: "ym.vid123",
            signal: "thumbs_up",
            metadata: {
                title: "Song",
                artist: "Artist",
                album: "Album",
                durationSec: 200,
            },
        });

        expect(res.status).toBe(200);
        expect(mockPrisma.likedRemoteTrack.upsert).toHaveBeenCalledWith(
            expect.objectContaining({
                where: {
                    userId_trackYtMusicId: {
                        userId: TEST_USER_ID,
                        trackYtMusicId: "ym-1",
                    },
                },
            }),
        );
    });

    it("clears a stored remote like without needing metadata", async () => {
        mockPrisma.trackTidal.findUnique.mockResolvedValue({ id: "tt-1" });
        const res = await post({ playbackId: "td.12345", signal: "clear" });

        expect(res.status).toBe(200);
        expect(mockPrisma.likedRemoteTrack.deleteMany).toHaveBeenCalledWith({
            where: { userId: TEST_USER_ID, trackTidalId: "tt-1" },
        });
    });

    it("answers 400 METADATA_REQUIRED when a remote row must be created", async () => {
        const res = await post({ playbackId: "td.12345", signal: "thumbs_up" });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("METADATA_REQUIRED");
        expect(mockPrisma.likedRemoteTrack.upsert).not.toHaveBeenCalled();
    });

    it("answers 400 INVALID_PLAYBACK_ID for a malformed playbackId", async () => {
        const res = await post({ playbackId: "nope", signal: "thumbs_up" });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYBACK_ID");
    });

    it("answers 400 INVALID_PLAYBACK_ID when playbackId is missing", async () => {
        const res = await post({ signal: "thumbs_up" });

        expect(res.status).toBe(400);
        expect(res.body.code).toBe("INVALID_PLAYBACK_ID");
    });

    it("answers 400 for an invalid signal", async () => {
        const res = await post({ playbackId: "t.track-1", signal: "meh" });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/invalid preference signal/i);
    });

    it("answers 404 TRACK_NOT_FOUND for an unknown local track", async () => {
        mockPrisma.track.findUnique.mockResolvedValue(null);
        const res = await post({ playbackId: "t.gone", signal: "thumbs_up" });

        expect(res.status).toBe(404);
        expect(res.body.code).toBe("TRACK_NOT_FOUND");
    });

    it("answers 409 SOURCE_UNAVAILABLE for a plain YouTube track", async () => {
        const res = await post({
            playbackId: "yt.vid123",
            signal: "thumbs_up",
        });

        expect(res.status).toBe(409);
        expect(res.body.code).toBe("SOURCE_UNAVAILABLE");
    });

    it("ignores legacy id fields when playbackId is present", async () => {
        const res = await post({
            playbackId: "t.track-1",
            trackId: "other",
            signal: "thumbs_up",
        });

        expect(res.status).toBe(200);
        expect(mockPrisma.likedTrack.upsert).toHaveBeenCalledWith(
            expect.objectContaining({
                where: {
                    userId_trackId: {
                        userId: TEST_USER_ID,
                        trackId: "track-1",
                    },
                },
            }),
        );
    });
});
