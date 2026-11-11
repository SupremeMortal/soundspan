import { Router } from "express";
import { logger } from "../utils/logger";
import { requireAuth } from "../middleware/auth";
import { prisma } from "../utils/db";
import { z } from "zod";
import {
    sendInternalRouteError,
    sendRouteError,
} from "../utils/routeErrorResponse";
import { resolveOfflinePolicy } from "../services/offline/offlinePolicy";
import {
    OfflineItemsError,
    resolveOfflineItems,
} from "../services/offline/resolveOfflineItems";
import {
    encodePlaybackId,
    parsePlaybackId,
    playbackIdSchema,
} from "../services/playback/playbackId";
import {
    LOCAL_TRACK_WHERE,
    TRACK_VISIBLE_WHERE,
} from "../utils/librarySorting";

const router = Router();

router.use(requireAuth);

const qualitySchema = z.enum(["original", "high", "medium", "low"]);

const downloadAlbumSchema = z.object({
    quality: qualitySchema.optional(),
});

const requestItemsSchema = z.object({
    kind: z.enum(["track", "album", "playlist"]),
    id: z.string().min(1).max(256),
    deviceId: z.string().uuid(),
    quality: qualitySchema.optional(),
});

const completeItemSchema = z.object({
    deviceId: z.string().uuid(),
    playbackId: playbackIdSchema,
    quality: qualitySchema,
    sizeBytes: z
        .number()
        .int()
        .positive()
        .max(4096 * 1024 * 1024),
});

const removeItemsSchema = z.object({
    deviceId: z.string().uuid(),
    playbackIds: z.array(z.string().min(1).max(256)).max(500),
});

const deviceQuerySchema = z.object({ deviceId: z.string().uuid() });

/** Cache limit used when a user has no settings row (matches `/stats`). */
const DEFAULT_MAX_CACHE_MB = 5120;
const BYTES_PER_MB = 1024 * 1024;

const completeTrackSchema = z.object({
    localPath: z.string().min(1).max(1024),
    quality: qualitySchema,
    fileSizeMb: z.coerce.number().finite().positive().max(4096),
});

/**
 * @openapi
 * /api/offline/items:
 *   post:
 *     summary: Request offline downloads for a track, album, or playlist
 *     description: >
 *       Resolves the request to downloadable items (stream URL, expected size,
 *       quality, content type) or blocked items with a reason. Albums and
 *       playlists include every visible track in order. Does not record
 *       cached files; completion does.
 *     tags: [Offline]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [kind, id, deviceId]
 *             properties:
 *               kind:
 *                 type: string
 *                 enum: [track, album, playlist]
 *               id:
 *                 type: string
 *                 description: A playbackId for track; the album or playlist id otherwise
 *               deviceId:
 *                 type: string
 *                 format: uuid
 *                 description: Client-generated per-installation id
 *               quality:
 *                 type: string
 *                 enum: [original, high, medium, low]
 *     responses:
 *       200:
 *         description: Resolved items with cache usage
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 items:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       playbackId: { type: string }
 *                       downloadable: { type: boolean }
 *                       downloadUrl: { type: string }
 *                       expectedSize: { type: integer, nullable: true }
 *                       quality: { type: string }
 *                       contentType: { type: string, nullable: true }
 *                       reason:
 *                         type: string
 *                         description: SOURCE_DOWNLOADS_DISABLED when an admin turned offline downloads off; SOURCE_UNAVAILABLE when the track's source cannot be streamed by this user; TRACK_UNAVAILABLE when the track no longer exists.
 *                         enum: [SOURCE_DOWNLOADS_DISABLED, TRACK_UNAVAILABLE, SOURCE_UNAVAILABLE]
 *                 estimatedTotalBytes: { type: integer }
 *                 cacheLimitBytes: { type: integer }
 *                 cacheUsedBytes: { type: integer }
 *       400:
 *         description: Invalid request (code INVALID_REQUEST or INVALID_PLAYBACK_ID)
 *       401:
 *         description: Not authenticated
 *       404:
 *         description: Album or playlist not found (code ALBUM_NOT_FOUND or PLAYLIST_NOT_FOUND)
 *       409:
 *         description: Cache limit exceeded (code CACHE_LIMIT_EXCEEDED with cacheLimitBytes, cacheUsedBytes, estimatedTotalBytes)
 */
// POST /offline/items
router.post("/items", async (req, res) => {
    const parsed = requestItemsSchema.safeParse(req.body);
    if (!parsed.success) {
        return res.status(400).json({
            error: "Invalid request",
            code: "INVALID_REQUEST",
            details: parsed.error.flatten(),
        });
    }
    const { kind, id, quality } = parsed.data;
    const userId = req.user!.id;

    try {
        const resolved = await resolveOfflineItems({
            userId,
            kind,
            id,
            quality,
        });

        const [settings, cacheStats] = await Promise.all([
            prisma.userSettings.findUnique({ where: { userId } }),
            prisma.cachedTrack.aggregate({
                where: { userId },
                _sum: { fileSizeMb: true },
            }),
        ]);
        const cacheLimitBytes = Math.round(
            (settings?.maxCacheSizeMb ?? DEFAULT_MAX_CACHE_MB) * BYTES_PER_MB,
        );
        const cacheUsedBytes = Math.round(
            (cacheStats._sum.fileSizeMb ?? 0) * BYTES_PER_MB,
        );

        if (cacheUsedBytes + resolved.estimatedTotalBytes > cacheLimitBytes) {
            return res.status(409).json({
                error: "Cache size limit exceeded",
                code: "CACHE_LIMIT_EXCEEDED",
                cacheLimitBytes,
                cacheUsedBytes,
                estimatedTotalBytes: resolved.estimatedTotalBytes,
            });
        }

        res.json({ ...resolved, cacheLimitBytes, cacheUsedBytes });
    } catch (error) {
        if (error instanceof OfflineItemsError) {
            return sendRouteError(res, error.status, error.message, {
                code: error.code,
            });
        }
        logger.error("Request offline items error:", error);
        return sendInternalRouteError(res, "Failed to resolve offline items");
    }
});

/**
 * @openapi
 * /api/offline/items/complete:
 *   post:
 *     summary: Record that a device finished writing an offline file
 *     description: >
 *       Upserts the device's cached-item row for the playbackId and quality.
 *       Calling it again for the same item updates the recorded size.
 *     tags: [Offline]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [deviceId, playbackId, quality, sizeBytes]
 *             properties:
 *               deviceId: { type: string, format: uuid }
 *               playbackId: { type: string }
 *               quality:
 *                 type: string
 *                 enum: [original, high, medium, low]
 *               sizeBytes: { type: integer, minimum: 1 }
 *     responses:
 *       200:
 *         description: Item recorded
 *       400:
 *         description: Invalid request (code INVALID_REQUEST)
 *       401:
 *         description: Not authenticated
 *       404:
 *         description: Library track no longer exists (code TRACK_UNAVAILABLE)
 */
// POST /offline/items/complete
router.post("/items/complete", async (req, res) => {
    const parsed = completeItemSchema.safeParse(req.body);
    if (!parsed.success) {
        return sendRouteError(res, 400, "Invalid request", {
            code: "INVALID_REQUEST",
            details: parsed.error.flatten(),
        });
    }
    const { deviceId, quality, sizeBytes } = parsed.data;
    const userId = req.user!.id;

    try {
        const ref = parsed.data.playbackId;
        const encodedId = encodePlaybackId(ref);
        let trackId: string | null = null;
        if (ref.kind === "t") {
            const track = await prisma.track.findUnique({
                where: { id: ref.trackId },
                select: { id: true },
            });
            if (!track) {
                return sendRouteError(res, 404, "Track not found", {
                    code: "TRACK_UNAVAILABLE",
                });
            }
            trackId = track.id;
        }

        const fileSizeMb = sizeBytes / BYTES_PER_MB;
        const existing = await prisma.cachedTrack.findFirst({
            where: { userId, deviceId, playbackId: encodedId, quality },
        });
        if (existing) {
            await prisma.cachedTrack.update({
                where: { id: existing.id },
                data: { fileSizeMb, lastAccessedAt: new Date() },
            });
        } else {
            await prisma.cachedTrack.create({
                data: {
                    userId,
                    deviceId,
                    playbackId: encodedId,
                    trackId,
                    // The client keeps the file; the server records no path.
                    localPath: `${deviceId}/${encodedId}`,
                    quality,
                    fileSizeMb,
                },
            });
        }
        res.json({ playbackId: encodedId, quality, sizeBytes });
    } catch (error) {
        logger.error("Complete offline item error:", error);
        return sendInternalRouteError(res, "Failed to complete download");
    }
});

/**
 * @openapi
 * /api/offline/items:
 *   delete:
 *     summary: Remove a device's offline items
 *     description: Unknown ids are ignored.
 *     tags: [Offline]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [deviceId, playbackIds]
 *             properties:
 *               deviceId: { type: string, format: uuid }
 *               playbackIds:
 *                 type: array
 *                 items: { type: string }
 *     responses:
 *       200:
 *         description: Number of rows removed
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 deletedCount: { type: integer }
 *       400:
 *         description: Invalid request (code INVALID_REQUEST)
 *       401:
 *         description: Not authenticated
 *   get:
 *     summary: List what the server believes a device holds
 *     description: >
 *       Used to reconcile after a reinstall. `revoked` is true when an admin
 *       turned offline downloads off or the track no longer exists; the client
 *       should remove such files.
 *     tags: [Offline]
 *     parameters:
 *       - in: query
 *         name: deviceId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: The device's items
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 items:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       playbackId: { type: string }
 *                       quality: { type: string }
 *                       sizeBytes: { type: integer }
 *                       revoked: { type: boolean }
 *       400:
 *         description: Invalid request (code INVALID_REQUEST)
 *       401:
 *         description: Not authenticated
 */
// DELETE /offline/items
router.delete("/items", async (req, res) => {
    const parsed = removeItemsSchema.safeParse(req.body);
    if (!parsed.success) {
        return sendRouteError(res, 400, "Invalid request", {
            code: "INVALID_REQUEST",
            details: parsed.error.flatten(),
        });
    }
    try {
        const { count } = await prisma.cachedTrack.deleteMany({
            where: {
                userId: req.user!.id,
                deviceId: parsed.data.deviceId,
                playbackId: { in: parsed.data.playbackIds },
            },
        });
        res.json({ deletedCount: count });
    } catch (error) {
        logger.error("Delete offline items error:", error);
        return sendInternalRouteError(res, "Failed to remove offline items");
    }
});

// GET /offline/items
router.get("/items", async (req, res) => {
    const parsed = deviceQuerySchema.safeParse(req.query);
    if (!parsed.success) {
        return sendRouteError(res, 400, "Invalid request", {
            code: "INVALID_REQUEST",
            details: parsed.error.flatten(),
        });
    }
    const userId = req.user!.id;
    try {
        const rows = await prisma.cachedTrack.findMany({
            where: { userId, deviceId: parsed.data.deviceId },
            orderBy: { cachedAt: "asc" },
        });
        const items = await Promise.all(
            rows.map(async (row) => {
                const ref = parsePlaybackId(row.playbackId);
                const policy = ref
                    ? await resolveOfflinePolicy(userId, ref)
                    : null;
                const revoked =
                    policy !== null &&
                    !policy.downloadable &&
                    (policy.reason === "SOURCE_DOWNLOADS_DISABLED" ||
                        policy.reason === "TRACK_UNAVAILABLE");
                return {
                    playbackId: row.playbackId,
                    quality: row.quality,
                    sizeBytes: Math.round(row.fileSizeMb * BYTES_PER_MB),
                    revoked,
                };
            }),
        );
        res.json({ items });
    } catch (error) {
        logger.error("List offline items error:", error);
        return sendInternalRouteError(res, "Failed to list offline items");
    }
});

/**
 * @openapi
 * /api/offline/albums/{id}/download:
 *   post:
 *     summary: Create a download job for an album's tracks
 *     tags: [Offline]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Album ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               quality:
 *                 type: string
 *                 enum: [original, high, medium, low]
 *                 description: Audio quality for download
 *     responses:
 *       200:
 *         description: Download job created with track stream URLs
 *       400:
 *         description: Cache size limit exceeded or invalid request
 *       404:
 *         description: Album not found
 *       409:
 *         description: An admin disabled offline downloads (code SOURCE_DOWNLOADS_DISABLED)
 *       401:
 *         description: Not authenticated
 */
// POST /offline/albums/:id/download
router.post("/albums/:id/download", async (req, res) => {
    try {
        const userId = req.user!.id;
        const albumId = req.params.id;
        const { quality } = downloadAlbumSchema.parse(req.body);

        // Get user's default quality if not specified
        let selectedQuality: "original" | "high" | "medium" | "low" =
            quality || "medium";
        if (!quality) {
            const settings = await prisma.userSettings.findUnique({
                where: { userId },
            });
            selectedQuality =
                (settings?.playbackQuality as
                    | "original"
                    | "high"
                    | "medium"
                    | "low") || "medium";
        }

        // Get album with tracks
        const album = await prisma.album.findUnique({
            where: { id: albumId },
            include: {
                tracks: {
                    where: { ...TRACK_VISIBLE_WHERE, ...LOCAL_TRACK_WHERE },
                    orderBy: [{ discNo: "asc" }, { trackNo: "asc" }],
                },
                artist: {
                    select: {
                        name: true,
                    },
                },
            },
        });

        if (!album) {
            return res.status(404).json({ error: "Album not found" });
        }

        // The admin switch applies to every track alike, so one policy
        // check against the first track covers the whole job.
        if (album.tracks.length > 0) {
            const policy = await resolveOfflinePolicy(userId, {
                kind: "t",
                trackId: album.tracks[0].id,
            });
            if (!policy.downloadable) {
                return res.status(409).json({
                    error: "Offline downloads are disabled",
                    code: policy.reason,
                });
            }
        }

        // Calculate total size estimate
        const avgSizeMb: Record<string, number> = {
            original: 30, // FLAC
            high: 10, // MP3 320
            medium: 6, // MP3 192
            low: 4, // MP3 128
        };

        const estimatedSizeMb =
            album.tracks.length * avgSizeMb[selectedQuality];

        // Check user's cache limit
        const settings = await prisma.userSettings.findUnique({
            where: { userId },
        });

        if (settings) {
            const currentCacheSize = await prisma.cachedTrack.aggregate({
                where: { userId },
                _sum: { fileSizeMb: true },
            });

            const currentSize = currentCacheSize._sum.fileSizeMb || 0;

            if (currentSize + estimatedSizeMb > settings.maxCacheSizeMb) {
                return res.status(400).json({
                    error: "Cache size limit exceeded",
                    currentSize,
                    maxSize: settings.maxCacheSizeMb,
                    needed: estimatedSizeMb,
                });
            }
        }

        // Create download job (tracks to be downloaded by mobile client)
        const downloadJob = {
            albumId: album.id,
            albumTitle: album.title,
            artistName: album.artist.name,
            quality: selectedQuality,
            tracks: album.tracks.map((track) => ({
                trackId: track.id,
                title: track.title,
                trackNo: track.trackNo,
                duration: track.duration,
                streamUrl: `/library/tracks/${track.id}/stream?quality=${selectedQuality}`,
            })),
            estimatedSizeMb,
        };

        res.json(downloadJob);
    } catch (error) {
        if (error instanceof z.ZodError) {
            return res
                .status(400)
                .json({ error: "Invalid request", details: error.issues });
        }
        logger.error("Create download job error:", error);
        res.status(500).json({ error: "Failed to create download job" });
    }
});

/**
 * @openapi
 * /api/offline/tracks/{id}/complete:
 *   post:
 *     summary: Mark a track download as complete
 *     tags: [Offline]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Track ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - localPath
 *               - quality
 *               - fileSizeMb
 *             properties:
 *               localPath:
 *                 type: string
 *                 minLength: 1
 *                 maxLength: 1024
 *                 description: Local file path on device
 *               quality:
 *                 type: string
 *                 enum: [original, high, medium, low]
 *                 description: Audio quality of the cached file
 *               fileSizeMb:
 *                 type: number
 *                 exclusiveMinimum: 0
 *                 maximum: 4096
 *                 description: File size in megabytes
 *     responses:
 *       200:
 *         description: Cached track record created or updated
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Not authenticated
 */
// POST /offline/tracks/:id/complete (called by mobile after download)
router.post("/tracks/:id/complete", async (req, res) => {
    try {
        const userId = req.user!.id;
        const trackId = req.params.id;
        const { localPath, quality, fileSizeMb } = completeTrackSchema.parse(
            req.body,
        );
        const track = await prisma.track.findFirst({
            where: {
                id: trackId,
                ...TRACK_VISIBLE_WHERE,
                ...LOCAL_TRACK_WHERE,
            },
            select: { id: true },
        });
        if (!track) {
            return res.status(404).json({ error: "Track not found" });
        }

        // Legacy rows have deviceId = null. PostgreSQL treats NULLs as distinct
        // in unique indexes, so the composite unique cannot dedupe them and
        // Prisma cannot upsert on a null key: find the row, then update or
        // create it.
        const playbackId = `t.${trackId}`;
        const existing = await prisma.cachedTrack.findFirst({
            where: { userId, deviceId: null, playbackId, quality },
        });
        const cachedTrack = existing
            ? await prisma.cachedTrack.update({
                  where: { id: existing.id },
                  data: {
                      localPath,
                      fileSizeMb,
                      lastAccessedAt: new Date(),
                  },
              })
            : await prisma.cachedTrack.create({
                  data: {
                      userId,
                      deviceId: null,
                      playbackId,
                      trackId,
                      localPath,
                      quality,
                      fileSizeMb,
                  },
              });

        res.json(cachedTrack);
    } catch (error) {
        if (error instanceof z.ZodError) {
            return res
                .status(400)
                .json({ error: "Invalid request", details: error.issues });
        }
        logger.error("Complete track download error:", error);
        res.status(500).json({ error: "Failed to complete download" });
    }
});

/**
 * @openapi
 * /api/offline/albums:
 *   get:
 *     summary: Get all offline-cached albums for the current user
 *     tags: [Offline]
 *     responses:
 *       200:
 *         description: List of cached albums with track details and sizes
 *       401:
 *         description: Not authenticated
 */
// GET /offline/albums
router.get("/albums", async (req, res) => {
    try {
        const userId = req.user!.id;

        // Get all cached tracks grouped by album
        const cachedTracks = await prisma.cachedTrack.findMany({
            where: { userId },
            include: {
                track: {
                    include: {
                        album: {
                            include: {
                                artist: {
                                    select: {
                                        id: true,
                                        name: true,
                                        mbid: true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        // Rows without a library track (other sources) have nothing to group.
        const removedCachedTracks = cachedTracks.filter(
            (cached) =>
                cached.track !== null && cached.track.removedAt !== null,
        );
        if (removedCachedTracks.length > 0) {
            await prisma.cachedTrack.deleteMany({
                where: {
                    id: { in: removedCachedTracks.map((cached) => cached.id) },
                    userId,
                },
            });
        }
        const visibleCachedTracks = cachedTracks.flatMap((cached) =>
            cached.track !== null && cached.track.removedAt === null
                ? [{ ...cached, track: cached.track }]
                : [],
        );

        // Group by album
        const albumsMap = new Map();

        for (const cached of visibleCachedTracks) {
            const albumId = cached.track.album.id;

            if (!albumsMap.has(albumId)) {
                albumsMap.set(albumId, {
                    album: cached.track.album,
                    tracks: [],
                    totalSizeMb: 0,
                });
            }

            const albumData = albumsMap.get(albumId);
            albumData.tracks.push({
                ...cached.track,
                cachedPath: cached.localPath,
                cachedQuality: cached.quality,
                cachedSizeMb: cached.fileSizeMb,
            });
            albumData.totalSizeMb += cached.fileSizeMb;
        }

        const albums = Array.from(albumsMap.values()).map((data) => ({
            ...data.album,
            cachedTracks: data.tracks,
            totalSizeMb: data.totalSizeMb,
        }));

        res.json(albums);
    } catch (error) {
        logger.error("Get cached albums error:", error);
        res.status(500).json({ error: "Failed to get cached albums" });
    }
});

/**
 * @openapi
 * /api/offline/albums/{id}:
 *   delete:
 *     summary: Remove a cached album from offline storage
 *     tags: [Offline]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Album ID
 *     responses:
 *       200:
 *         description: Album removed from cache
 *       401:
 *         description: Not authenticated
 */
// DELETE /offline/albums/:id
router.delete("/albums/:id", async (req, res) => {
    try {
        const userId = req.user!.id;
        const albumId = req.params.id;

        // Get all cached tracks for this album
        const cachedTracks = await prisma.cachedTrack.findMany({
            where: {
                userId,
                track: {
                    albumId,
                },
            },
        });

        // Delete all cached tracks for this album
        await prisma.cachedTrack.deleteMany({
            where: {
                userId,
                track: {
                    albumId,
                },
            },
        });

        res.json({
            message: "Album removed from cache",
            deletedCount: cachedTracks.length,
        });
    } catch (error) {
        logger.error("Delete cached album error:", error);
        res.status(500).json({ error: "Failed to delete cached album" });
    }
});

/**
 * @openapi
 * /api/offline/stats:
 *   get:
 *     summary: Get offline cache usage statistics
 *     description: >
 *       With `deviceId`, the response also carries a `device` object with that
 *       device's totals; the top-level numbers always cover every device.
 *     tags: [Offline]
 *     parameters:
 *       - in: query
 *         name: deviceId
 *         required: false
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Cache usage stats including size and track count
 *       400:
 *         description: Invalid deviceId (code INVALID_REQUEST)
 *       401:
 *         description: Not authenticated
 */
// GET /offline/stats
router.get("/stats", async (req, res) => {
    try {
        const userId = req.user!.id;
        let deviceId: string | undefined;
        if (req.query?.deviceId !== undefined) {
            const parsed = deviceQuerySchema.safeParse(req.query);
            if (!parsed.success) {
                return sendRouteError(res, 400, "Invalid request", {
                    code: "INVALID_REQUEST",
                });
            }
            deviceId = parsed.data.deviceId;
        }

        const [settings, cacheStats] = await Promise.all([
            prisma.userSettings.findUnique({
                where: { userId },
            }),
            prisma.cachedTrack.aggregate({
                where: { userId },
                _sum: { fileSizeMb: true },
                _count: true,
            }),
        ]);

        const usedMb = cacheStats._sum.fileSizeMb || 0;
        const maxMb = settings?.maxCacheSizeMb || 5120;
        const trackCount = cacheStats._count || 0;

        const body = {
            usedMb,
            maxMb,
            availableMb: maxMb - usedMb,
            percentUsed: (usedMb / maxMb) * 100,
            trackCount,
        };
        if (deviceId === undefined) {
            return res.json(body);
        }
        const deviceStats = await prisma.cachedTrack.aggregate({
            where: { userId, deviceId },
            _sum: { fileSizeMb: true },
            _count: true,
        });
        res.json({
            ...body,
            device: {
                deviceId,
                usedMb: deviceStats._sum.fileSizeMb || 0,
                trackCount: deviceStats._count || 0,
            },
        });
    } catch (error) {
        logger.error("Get cache stats error:", error);
        res.status(500).json({ error: "Failed to get cache stats" });
    }
});

export default router;
