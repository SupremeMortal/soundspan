/**
 * YouTube Music Routes
 *
 * Exposes the ytmusic-streamer sidecar's functionality to the frontend.
 * All routes require authentication. Each user connects their own
 * YouTube Music account — OAuth credentials are stored per-user in
 * UserSettings.ytMusicOAuthJson.
 *
 * The /stream/:videoId endpoint proxies audio bytes from the sidecar
 * so that IP-locked YouTube URLs work correctly.
 */

import { Router, Request, Response, NextFunction } from "express";
import { z } from "zod";
import { requireAuth, requireAuthOrToken } from "../middleware/auth";
import { ytMusicService } from "../services/youtubeMusic";
import type { YtMusicDeviceCodePollResult } from "../services/youtubeMusic";
import { getSystemSettings } from "../utils/systemSettings";
import { logger } from "../utils/logger";
import { prisma } from "../utils/db";
import { trackMappingService } from "../services/trackMappingService";
import { encrypt, decrypt } from "../utils/encryption";
import {
    ytMusicSearchLimiter,
    ytMusicStreamLimiter,
} from "../middleware/rateLimiter";
import {
    clearYtUserOAuth,
    ensureUserOAuth,
    getHttpErrorStatus,
    getUserIdOrPublic,
    invalidateAllYtOAuthSessions,
    persistYtManualOAuthCredential,
    pollYtOAuthCredential,
    runYtOAuthCredentialOperation,
    setYtOAuthCache,
} from "../services/ytMusicUserSession";
import {
    getYtMusicStreamInfo,
    streamYtMusicTrack,
} from "../services/playback/streamYtMusicTrack";
import { sendInternalRouteError } from "../utils/routeErrorResponse";
import { asyncHandler } from "../middleware/asyncHandler";
import { parsePagination } from "../middleware/parsePagination";
import { validate } from "../middleware/validate";

export { getUserIdOrPublic };

const router = Router();
const MATCH_SCHEMA = z.object({
    artist: z.string().min(1),
    title: z.string().min(1),
    albumTitle: z.string().optional(),
    duration: z.number().positive().optional(),
    isrc: z.string().trim().min(6).max(20).optional(),
});
const MATCH_BATCH_SCHEMA = z.object({
    tracks: z.array(MATCH_SCHEMA).min(1).max(50),
});

// ── Guard middleware ───────────────────────────────────────────────

async function requireYtMusicEnabled(
    req: Request,
    res: Response,
    next: NextFunction,
) {
    try {
        const settings = await getSystemSettings();
        if (!settings.ytMusicEnabled) {
            return res
                .status(403)
                .json({ error: "YouTube Music integration is not enabled" });
        }
        next();
    } catch (err) {
        logger.error("[YTMusic Route] Failed to check settings:", err);
        sendInternalRouteError(res, "Internal server error");
    }
}

async function requireUserOAuth(
    userId: string,
    res: Response,
): Promise<boolean> {
    const ok = await ensureUserOAuth(userId);
    if (!ok) {
        setYtOAuthCache(userId, false);
        res.status(401).json({
            error: "YouTube Music authentication expired or missing. Please reconnect your account.",
        });
        return false;
    }
    return true;
}

function handleYtMusicAuthError(
    res: Response,
    err: unknown,
    userId?: string,
): boolean {
    if (getHttpErrorStatus(err) !== 401) return false;
    if (userId) {
        setYtOAuthCache(userId, false);
    } else {
        invalidateAllYtOAuthSessions();
    }
    res.status(401).json({
        error: "YouTube Music authentication expired or invalid. Please reconnect your account.",
    });
    return true;
}

/** Parse a query limit into a bounded integer in [1, 100]; falls back to 100. */
const parseBoundedLimit = (raw: unknown): number => {
    // A shared parseBoundedInt utility may supersede this route-local parser.
    const parsed = typeof raw === "string" ? Number.parseInt(raw, 10) : NaN;
    if (!Number.isFinite(parsed)) {
        return 100;
    }
    return Math.min(100, Math.max(1, parsed));
};

// ── Status ─────────────────────────────────────────────────────────

/**
 * @openapi
 * /api/ytmusic/status:
 *   get:
 *     summary: Check YouTube Music integration and authentication status
 *     tags: [YouTube Music]
 *     responses:
 *       200:
 *         description: YouTube Music status including enabled, available, and authentication state
 *       401:
 *         description: Not authenticated
 */
router.get(
    "/status",
    requireAuth,
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;
            const settings = await getSystemSettings();
            const available = await ytMusicService.isAvailable();

            const oauthConfigured = !!(
                settings?.ytMusicClientId && settings?.ytMusicClientSecret
            );

            if (!available) {
                return res.json({
                    enabled: settings.ytMusicEnabled,
                    available: false,
                    authenticated: false,
                    credentialsConfigured: oauthConfigured,
                    oauthConfigured,
                });
            }

            // Try to restore OAuth if needed, then check status
            await ensureUserOAuth(userId);
            const authStatus = await ytMusicService.getAuthStatus(userId);

            return res.json({
                enabled: settings.ytMusicEnabled,
                available: true,
                credentialsConfigured: oauthConfigured,
                oauthConfigured,
                ...authStatus,
            });
        } catch (err) {
            logger.error("[YTMusic Route] Status check failed:", err);
            sendInternalRouteError(res, "Failed to check YouTube Music status");
        }
    }),
);

// ── OAuth Device Code Flow (per-user) ──────────────────────────────

/**
 * @openapi
 * /api/ytmusic/auth/device-code:
 *   post:
 *     summary: Initiate OAuth device code flow for YouTube Music authentication
 *     tags: [YouTube Music]
 *     responses:
 *       200:
 *         description: Device code and verification URL for user authorization
 *       400:
 *         description: YouTube Music client credentials not configured
 *       401:
 *         description: Not authenticated
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/auth/device-code",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const settings = await getSystemSettings();
            if (!settings?.ytMusicClientId || !settings?.ytMusicClientSecret) {
                return res.status(400).json({
                    error: "YouTube Music Client ID and Secret must be configured by an admin first",
                });
            }

            const result = await ytMusicService.initiateDeviceAuth(
                settings.ytMusicClientId,
                settings.ytMusicClientSecret,
            );

            res.json(result);
        } catch (err: unknown) {
            logger.error("[YTMusic Route] Device code initiation failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

/**
 * @openapi
 * /api/ytmusic/auth/device-code/poll:
 *   post:
 *     summary: Poll device code authorization status for YouTube Music OAuth
 *     tags: [YouTube Music]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [deviceCode]
 *             properties:
 *               deviceCode:
 *                 type: string
 *     responses:
 *       200:
 *         description: Poll result with authorization status
 *       400:
 *         description: Missing deviceCode or client credentials not configured
 *       401:
 *         description: Not authenticated
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/auth/device-code/poll",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;
            const { deviceCode } = req.body;

            if (!deviceCode) {
                return res
                    .status(400)
                    .json({ error: "deviceCode is required" });
            }

            const result = await runYtOAuthCredentialOperation(
                userId,
                (generation) =>
                    pollYtOAuthCredential(userId, generation, deviceCode),
            );
            if (!result.credentialsConfigured) {
                return res.status(400).json({
                    error: "YouTube Music Client ID and Secret not configured",
                });
            }
            res.json(result.response);
        } catch (err: unknown) {
            logger.error("[YTMusic Route] Device code poll failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

/**
 * @openapi
 * /api/ytmusic/auth/save-token:
 *   post:
 *     summary: Save OAuth token JSON for YouTube Music authentication
 *     tags: [YouTube Music]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [oauthJson]
 *             properties:
 *               oauthJson:
 *                 type: string
 *                 description: OAuth credentials as a JSON string
 *     responses:
 *       200:
 *         description: OAuth token saved successfully
 *       400:
 *         description: Missing or invalid oauthJson
 *       401:
 *         description: Not authenticated
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/auth/save-token",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;
            const { oauthJson } = req.body;

            if (!oauthJson) {
                return res.status(400).json({ error: "oauthJson is required" });
            }

            // Validate it's proper JSON
            try {
                JSON.parse(oauthJson);
            } catch {
                return res
                    .status(400)
                    .json({ error: "Invalid JSON in oauthJson" });
            }

            const success = await runYtOAuthCredentialOperation(
                userId,
                (generation) =>
                    persistYtManualOAuthCredential(
                        userId,
                        generation,
                        oauthJson,
                    ),
            );
            if (success) {
                logger.info(
                    `[YTMusic] OAuth credentials saved for user ${userId}`,
                );
            }
            res.json({ success });
        } catch (err: unknown) {
            logger.error("[YTMusic Route] Save OAuth token failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

/**
 * @openapi
 * /api/ytmusic/auth/clear:
 *   post:
 *     summary: Clear YouTube Music OAuth credentials for the current user
 *     tags: [YouTube Music]
 *     responses:
 *       200:
 *         description: OAuth credentials cleared successfully
 *       401:
 *         description: Not authenticated
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/auth/clear",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;

            await clearYtUserOAuth(userId);

            logger.info(
                `[YTMusic] OAuth credentials cleared for user ${userId}`,
            );
            res.json({ success: true });
        } catch (err: unknown) {
            logger.error("[YTMusic Route] Clear auth failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

// ── Search ─────────────────────────────────────────────────────────
// Search and gap-fill matching intentionally skip requireUserOAuth:
// the sidecar executes these operations with public clients so user OAuth
// search history is not affected.

/**
 * @openapi
 * /api/ytmusic/search:
 *   post:
 *     summary: Search YouTube Music catalog
 *     tags: [YouTube Music]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [query]
 *             properties:
 *               query:
 *                 type: string
 *               filter:
 *                 type: string
 *     responses:
 *       200:
 *         description: Search results from YouTube Music
 *       400:
 *         description: Missing query parameter
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/search",
    requireAuth,
    requireYtMusicEnabled,
    ytMusicSearchLimiter,
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;

            const { query, filter } = req.body;
            if (!query) {
                return res.status(400).json({ error: "query is required" });
            }
            const result = await ytMusicService.searchCanonical(
                userId,
                query,
                filter,
            );
            res.json(result);
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Search failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

// ── Browse ─────────────────────────────────────────────────────────

/**
 * @openapi
 * /api/ytmusic/album/{browseId}:
 *   get:
 *     summary: Get YouTube Music album details by browse ID
 *     tags: [YouTube Music]
 *     parameters:
 *       - in: path
 *         name: browseId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Album details from YouTube Music
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/album/:browseId",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request<{ browseId: string }>, res: Response) => {
        try {
            const effectiveUserId = await getUserIdOrPublic(req.user!.id);
            const album = await ytMusicService.getAlbum(
                effectiveUserId,
                req.params.browseId,
            );
            res.json(album);
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Get album failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

/**
 * @openapi
 * /api/ytmusic/artist/{channelId}:
 *   get:
 *     summary: Get YouTube Music artist details by channel ID
 *     tags: [YouTube Music]
 *     parameters:
 *       - in: path
 *         name: channelId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Artist details from YouTube Music
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/artist/:channelId",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request<{ channelId: string }>, res: Response) => {
        try {
            const effectiveUserId = await getUserIdOrPublic(req.user!.id);
            const artist = await ytMusicService.getArtist(
                effectiveUserId,
                req.params.channelId,
            );
            res.json(artist);
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Get artist failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

/**
 * @openapi
 * /api/ytmusic/song/{videoId}:
 *   get:
 *     summary: Get YouTube Music song details by video ID
 *     tags: [YouTube Music]
 *     parameters:
 *       - in: path
 *         name: videoId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Song details from YouTube Music
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/song/:videoId",
    requireAuth,
    requireYtMusicEnabled,
    asyncHandler(async (req: Request<{ videoId: string }>, res: Response) => {
        try {
            const effectiveUserId = await getUserIdOrPublic(req.user!.id);
            const song = await ytMusicService.getSong(
                effectiveUserId,
                req.params.videoId,
            );
            res.json(song);
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Get song failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

// ── Stream Info ────────────────────────────────────────────────────
// Returns metadata about a YT Music stream (bitrate, codec, etc.)
// without proxying the actual audio bytes. Used by the player UI
// to display quality information.

/**
 * @openapi
 * /api/ytmusic/stream-info/{videoId}:
 *   get:
 *     summary: Get stream metadata (bitrate, codec, duration) for a YouTube Music track
 *     tags: [YouTube Music]
 *     security:
 *       - apiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: videoId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: quality
 *         schema:
 *           type: string
 *         description: Requested stream quality (e.g. high, low)
 *     responses:
 *       200:
 *         description: Stream metadata including bitrate, codec, and duration
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 *       404:
 *         description: Stream not found
 *       451:
 *         description: Content is age-restricted and cannot be streamed
 */
router.get(
    "/stream-info/:videoId",
    requireAuthOrToken,
    requireYtMusicEnabled,
    ytMusicStreamLimiter,
    asyncHandler(async (req: Request<{ videoId: string }>, res: Response) => {
        await getYtMusicStreamInfo({
            userId: req.user!.id,
            videoId: req.params.videoId,
            quality: req.query.quality,
            mode: "authenticated",
            req,
            res,
        });
    }),
);

// ── Stream Proxy ───────────────────────────────────────────────────
// This is the critical endpoint: the frontend requests audio from here,
// and we pipe it from the sidecar. This avoids exposing IP-locked
// YouTube CDN URLs directly to the browser.

/**
 * @openapi
 * /api/ytmusic/stream/{videoId}:
 *   get:
 *     summary: Proxy audio stream from YouTube Music sidecar
 *     tags: [YouTube Music]
 *     security:
 *       - apiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: videoId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: quality
 *         schema:
 *           type: string
 *         description: Requested stream quality (e.g. high, low)
 *     responses:
 *       200:
 *         description: Audio stream bytes piped from the YouTube Music sidecar
 *         content:
 *           audio/*:
 *             schema:
 *               type: string
 *               format: binary
 *       206:
 *         description: Partial content (range request)
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 *       404:
 *         description: Stream not found
 *       451:
 *         description: Content is age-restricted and cannot be streamed
 */
router.get(
    "/stream/:videoId",
    requireAuthOrToken,
    requireYtMusicEnabled,
    ytMusicStreamLimiter,
    asyncHandler(async (req: Request<{ videoId: string }>, res: Response) => {
        await streamYtMusicTrack({
            userId: req.user!.id,
            videoId: req.params.videoId,
            quality: req.query.quality,
            mode: "authenticated",
            req,
            res,
        });
    }),
);

// ── Library ────────────────────────────────────────────────────────

/**
 * @openapi
 * /api/ytmusic/library/songs:
 *   get:
 *     summary: Get songs from the user's YouTube Music library
 *     tags: [YouTube Music]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 100
 *         description: Maximum number of songs to return
 *     responses:
 *       200:
 *         description: List of library songs
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/library/songs",
    requireAuth,
    requireYtMusicEnabled,
    parsePagination(),
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;
            if (!(await requireUserOAuth(userId, res))) return;
            const limit =
                req.pagination?.limit ?? parseBoundedLimit(req.query.limit);
            const songs = await ytMusicService.getLibrarySongs(userId, limit);
            res.json({ songs });
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Library songs failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

/**
 * @openapi
 * /api/ytmusic/library/albums:
 *   get:
 *     summary: Get albums from the user's YouTube Music library
 *     tags: [YouTube Music]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 100
 *         description: Maximum number of albums to return
 *     responses:
 *       200:
 *         description: List of library albums
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/library/albums",
    requireAuth,
    requireYtMusicEnabled,
    parsePagination(),
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;
            if (!(await requireUserOAuth(userId, res))) return;
            const limit =
                req.pagination?.limit ?? parseBoundedLimit(req.query.limit);
            const albums = await ytMusicService.getLibraryAlbums(userId, limit);
            res.json({ albums });
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Library albums failed:", err);
            sendInternalRouteError(res, "Internal server error");
        }
    }),
);

// ── Gap-Fill Match ─────────────────────────────────────────────────

/**
 * @openapi
 * /api/ytmusic/match:
 *   post:
 *     summary: Find the best YouTube Music match for a given track
 *     tags: [YouTube Music]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [artist, title]
 *             properties:
 *               artist:
 *                 type: string
 *               title:
 *                 type: string
 *               albumTitle:
 *                 type: string
 *               duration:
 *                 type: number
 *               isrc:
 *                 type: string
 *     responses:
 *       200:
 *         description: Best matching track from YouTube Music
 *       400:
 *         description: Missing required artist and title fields
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/match",
    requireAuth,
    requireYtMusicEnabled,
    ytMusicSearchLimiter,
    validate({ body: MATCH_SCHEMA }),
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;

            const parsed = MATCH_SCHEMA.safeParse(req.valid?.body ?? req.body);
            if (!parsed.success) {
                return res
                    .status(400)
                    .json({ error: "artist and title are required" });
            }
            const match = await ytMusicService.findMatchForTrack(
                userId,
                parsed.data.artist,
                parsed.data.title,
                parsed.data.albumTitle,
                parsed.data.duration,
                parsed.data.isrc,
            );
            res.json({ match });
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Match failed:", err);
            sendInternalRouteError(res, "Failed to find matching track");
        }
    }),
);

// ── Batch Gap-Fill Match ───────────────────────────────────────────

/**
 * @openapi
 * /api/ytmusic/match-batch:
 *   post:
 *     summary: Batch-match multiple tracks against YouTube Music catalog
 *     tags: [YouTube Music]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [tracks]
 *             properties:
 *               tracks:
 *                 type: array
 *                 minItems: 1
 *                 maxItems: 50
 *                 items:
 *                   type: object
 *                   properties:
 *                     artist:
 *                       type: string
 *                     title:
 *                       type: string
 *                     albumTitle:
 *                       type: string
 *                     duration:
 *                       type: number
 *                     isrc:
 *                       type: string
 *     responses:
 *       200:
 *         description: Matches keyed by index for each input track
 *       400:
 *         description: Invalid or missing tracks array
 *       401:
 *         description: Not authenticated or YouTube Music auth expired
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.post(
    "/match-batch",
    requireAuth,
    requireYtMusicEnabled,
    ytMusicSearchLimiter,
    validate({ body: MATCH_BATCH_SCHEMA }),
    asyncHandler(async (req: Request, res: Response) => {
        try {
            const userId = req.user!.id;

            const parsed = MATCH_BATCH_SCHEMA.safeParse(
                req.valid?.body ?? req.body,
            );
            if (!parsed.success) {
                return res
                    .status(400)
                    .json({ error: "tracks array is required" });
            }

            const matches = await ytMusicService.findMatchesForAlbum(
                userId,
                parsed.data.tracks,
            );

            // Fire-and-forget: persist matched tracks as TrackYtMusic rows
            // TrackMapping rows are created when the frontend sends trackIds
            // via the track-mappings/batch endpoint or album-level fetch
            Promise.resolve().then(async () => {
                try {
                    for (let i = 0; i < matches.length; i++) {
                        const match = matches[i];
                        if (!match) continue;
                        const inputTrack = parsed.data.tracks[i];
                        await trackMappingService.upsertTrackYtMusic({
                            videoId: match.videoId,
                            title: match.title,
                            artist: inputTrack.artist,
                            album: inputTrack.albumTitle || "",
                            duration: match.duration,
                        });
                    }
                } catch (err) {
                    logger.warn(
                        "[YTMusic Route] Failed to persist gap-fill TrackYtMusic rows:",
                        err,
                    );
                }
            });

            // Return matches keyed by index for easy lookup
            res.json({ matches });
        } catch (err: unknown) {
            if (handleYtMusicAuthError(res, err)) return;
            logger.error("[YTMusic Route] Batch match failed:", err);
            sendInternalRouteError(res, "Failed to batch-match tracks");
        }
    }),
);

// ── Public Stream Routes (no user OAuth required) ─────────────────
// These endpoints use the "__public__" user_id sentinel to bypass
// OAuth on the sidecar. yt-dlp extraction is unauthenticated.
// Users must still be logged into Soundspan (requireAuthOrToken)
// and YT Music must be admin-enabled (requireYtMusicEnabled).

/**
 * @openapi
 * /api/ytmusic/stream-info-public/{videoId}:
 *   get:
 *     summary: Get stream metadata without YT Music OAuth
 *     tags: [YouTube Music]
 *     security:
 *       - apiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: videoId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Stream metadata
 *       401:
 *         description: Not authenticated
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/stream-info-public/:videoId",
    requireAuthOrToken,
    requireYtMusicEnabled,
    ytMusicStreamLimiter,
    asyncHandler(async (req: Request<{ videoId: string }>, res: Response) => {
        await getYtMusicStreamInfo({
            videoId: req.params.videoId,
            quality: req.query.quality,
            mode: "public",
            req,
            res,
        });
    }),
);

/**
 * @openapi
 * /api/ytmusic/stream-public/{videoId}:
 *   get:
 *     summary: Proxy audio stream without YT Music OAuth
 *     tags: [YouTube Music]
 *     security:
 *       - apiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: videoId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: quality
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Audio stream bytes
 *       206:
 *         description: Partial content (range request)
 *       401:
 *         description: Not authenticated
 *       403:
 *         description: YouTube Music integration is not enabled
 */
router.get(
    "/stream-public/:videoId",
    requireAuthOrToken,
    requireYtMusicEnabled,
    ytMusicStreamLimiter,
    asyncHandler(async (req: Request<{ videoId: string }>, res: Response) => {
        await streamYtMusicTrack({
            videoId: req.params.videoId,
            quality: req.query.quality,
            mode: "public",
            req,
            res,
        });
    }),
);

export default router;
