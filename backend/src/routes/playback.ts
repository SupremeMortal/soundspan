/**
 * Unified playback routes, mounted at `/api/playback`.
 *
 * One stream surface for every track source, addressed by an opaque
 * `playbackId`:
 *
 *   GET /stream/:playbackId      - Audio stream (Range supported)
 *   GET /stream-info/:playbackId - Codec, quality and size of that stream
 *
 * Each request is resolved to a stream service (library, TIDAL, YT Music or
 * YouTube) by `resolvePlayback`; the services are the same ones the per-source
 * routes call, so Range handling and response headers match them.
 */

import { Router } from "express";
import type { NextFunction, Request, Response } from "express";
import { z } from "zod";
import { requireAuthOrToken } from "../middleware/auth";
import {
    streamingLimiter,
    ytMusicStreamLimiter,
} from "../middleware/rateLimiter";
import { asyncHandler } from "../middleware/asyncHandler";
import { parsePlaybackId } from "../services/playback/playbackId";
import {
    PlaybackResolutionError,
    resolvePlayback,
    type PlaybackQuality,
    type ResolvedPlayback,
} from "../services/playback/resolvePlayback";
import { getPlaybackStreamInfo } from "../services/playback/playbackStreamInfo";
import { streamLibraryTrack } from "../services/playback/streamLibraryTrack";
import { streamTidalTrack } from "../services/playback/streamTidalTrack";
import { streamYtMusicTrack } from "../services/playback/streamYtMusicTrack";
import { streamYouTubeVideo } from "../services/playback/streamYouTubeVideo";
import { sendRouteError } from "../utils/routeErrorResponse";
import { logger } from "../utils/logger";

const router = Router();

// Stream starts share the budget the library stream route uses.
router.use("/stream/:playbackId", streamingLimiter);
router.use("/stream-info/:playbackId", streamingLimiter);

const qualitySchema = z.enum(["original", "high", "medium", "low"]);

/** The machine-readable `code` for each error status on this surface. */
function errorCodeForStatus(status: number): string | undefined {
    if (status === 404) return "TRACK_NOT_FOUND";
    if (status === 409) return "SOURCE_UNAVAILABLE";
    if (status === 429) return "RATE_LIMITED";
    if (status === 502 || status === 503 || status === 504) {
        return "UPSTREAM_FAILED";
    }
    return undefined;
}

/**
 * Makes JSON error bodies written by the shared stream services carry the
 * unified `code`, so every source reports errors in one shape.
 */
function addErrorCodes(res: Response): void {
    const json = res.json.bind(res);
    res.json = ((body?: unknown) => {
        const code = errorCodeForStatus(res.statusCode);
        if (
            code &&
            body &&
            typeof body === "object" &&
            !Array.isArray(body) &&
            !("code" in body)
        ) {
            return json({ ...body, code });
        }
        return json(body);
    }) as Response["json"];
}

/** Runs the YT Music limiter, answering its 429 in the unified error shape. */
function runYtMusicLimiter(req: Request, res: Response): Promise<boolean> {
    return new Promise((resolve) => {
        const send = res.send.bind(res);
        res.send = ((body?: unknown) => {
            if (res.statusCode === 429) {
                res.send = send;
                sendRouteError(
                    res,
                    429,
                    typeof body === "string" ? body : "Too many requests",
                    { code: "RATE_LIMITED" },
                );
                resolve(false);
                return res;
            }
            return send(body);
        }) as Response["send"];
        const next: NextFunction = () => {
            res.send = send;
            resolve(true);
        };
        ytMusicStreamLimiter(req, res, next);
    });
}

function sendResolutionError(res: Response, err: PlaybackResolutionError) {
    const status = err.code === "TRACK_NOT_FOUND" ? 404 : 409;
    return sendRouteError(res, status, err.message, { code: err.code });
}

/** The playback a request addresses, once validated and resolved. */
interface ResolvedRequest {
    playback: ResolvedPlayback;
    userId: string;
}

/**
 * Validates `playbackId` and `quality` and resolves the stream service for
 * the caller. Writes the error response and returns null when it cannot.
 */
async function resolveRequest(
    req: Request<{ playbackId: string }>,
    res: Response,
): Promise<ResolvedRequest | null> {
    const parsed = parsePlaybackId(req.params.playbackId);
    if (!parsed) {
        sendRouteError(res, 400, "Invalid playbackId", {
            code: "INVALID_PLAYBACK_ID",
        });
        return null;
    }
    let quality: PlaybackQuality | undefined;
    if (req.query.quality !== undefined) {
        const q = qualitySchema.safeParse(req.query.quality);
        if (!q.success) {
            sendRouteError(res, 400, "Invalid quality", {
                code: "INVALID_QUALITY",
            });
            return null;
        }
        quality = q.data;
    }

    const userId = req.user!.id;
    try {
        const playback = await resolvePlayback(userId, { parsed, quality });
        return { playback, userId };
    } catch (err: unknown) {
        if (err instanceof PlaybackResolutionError) {
            sendResolutionError(res, err);
            return null;
        }
        throw err;
    }
}

/**
 * Only library streams carry a strong ETag, so an `If-Range` on any other
 * source cannot be validated. Per RFC 9110 the Range is then ignored and the
 * full body is sent, so a resumed download never splices two encodings.
 */
function dropUnverifiableRange(playback: ResolvedPlayback, req: Request): void {
    if (playback.kind !== "t" && req.headers["if-range"] !== undefined) {
        delete req.headers.range;
    }
}

async function dispatchStream(
    playback: ResolvedPlayback,
    userId: string,
    req: Request,
    res: Response,
): Promise<void> {
    dropUnverifiableRange(playback, req);
    switch (playback.kind) {
        case "t":
            return streamLibraryTrack({
                userId,
                trackId: playback.trackId,
                quality: playback.quality,
                req: req as Request<{ id: string }>,
                res,
                playbackId: String(req.params.playbackId),
            });
        case "td":
            return streamTidalTrack({
                userId,
                trackId: playback.tidalId,
                quality: playback.quality,
                req,
                res,
            });
        case "ym":
            return streamYtMusicTrack(
                playback.mode === "authenticated"
                    ? {
                          mode: "authenticated",
                          userId,
                          videoId: playback.videoId,
                          quality: playback.quality,
                          req,
                          res,
                      }
                    : {
                          mode: "public",
                          userId,
                          videoId: playback.videoId,
                          quality: playback.quality,
                          req,
                          res,
                      },
            );
        case "yt":
            return streamYouTubeVideo({
                videoId: playback.videoId,
                quality: playback.quality,
                range: req.headers.range,
                res,
            });
    }
}

/**
 * @openapi
 * /api/playback/stream/{playbackId}:
 *   get:
 *     summary: Stream audio for any track source
 *     description: >
 *       Streams the audio for a track identified by an opaque playbackId,
 *       whatever source backs it. Supports Range requests. To resume a
 *       download, send the ETag back as If-Range with a Range header: a
 *       matching ETag answers 206, anything else (a changed file, or a
 *       source that has no strong ETag) answers 200 with the full body.
 *       Authenticate with
 *       an X-API-Key header, a Bearer token, or a token query parameter.
 *     tags: [Playback]
 *     security:
 *       - apiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: playbackId
 *         required: true
 *         description: Opaque track identifier, as returned in track payloads.
 *         schema:
 *           type: string
 *       - in: query
 *         name: quality
 *         schema:
 *           type: string
 *           enum: [original, high, medium, low]
 *         description: Requested quality; the user's saved playback quality when absent.
 *     responses:
 *       200:
 *         description: Audio stream
 *       206:
 *         description: Partial content (Range request)
 *       400:
 *         description: INVALID_PLAYBACK_ID or INVALID_QUALITY
 *       401:
 *         description: Not authenticated
 *       404:
 *         description: TRACK_NOT_FOUND
 *       409:
 *         description: SOURCE_UNAVAILABLE
 *       429:
 *         description: RATE_LIMITED; see the Retry-After header
 *       502:
 *         description: UPSTREAM_FAILED
 */
router.get(
    "/stream/:playbackId",
    requireAuthOrToken,
    asyncHandler(
        async (req: Request<{ playbackId: string }>, res: Response) => {
            const resolved = await resolveRequest(req, res);
            if (!resolved) return;
            const { playback, userId } = resolved;

            if (
                playback.middleware.ytMusicStreamLimiter &&
                !(await runYtMusicLimiter(req, res))
            ) {
                return;
            }

            addErrorCodes(res);
            try {
                await dispatchStream(playback, userId, req, res);
            } catch (err: unknown) {
                logger.error("[Playback] Stream failed:", err);
                if (!res.headersSent) {
                    sendRouteError(res, 502, "Upstream stream failed", {
                        code: "UPSTREAM_FAILED",
                    });
                } else {
                    res.end();
                }
            }
        },
    ),
);

/**
 * @openapi
 * /api/playback/stream-info/{playbackId}:
 *   get:
 *     summary: Describe the audio stream for any track source
 *     description: >
 *       Returns codec, quality and size of what `/api/playback/stream` serves
 *       for a playbackId, in one shape for every source. Fields a source cannot
 *       know are null. Authenticate with an X-API-Key header, a Bearer token, or
 *       a token query parameter.
 *     tags: [Playback]
 *     security:
 *       - apiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: playbackId
 *         required: true
 *         description: Opaque track identifier, as returned in track payloads.
 *         schema:
 *           type: string
 *       - in: query
 *         name: quality
 *         schema:
 *           type: string
 *           enum: [original, high, medium, low]
 *         description: Requested quality; the user's saved playback quality when absent.
 *     responses:
 *       200:
 *         description: Stream information
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               required: [playbackId, contentType, codec, bitrate, sampleRate, bitDepth, durationMs, contentLength, quality]
 *               properties:
 *                 playbackId:
 *                   type: string
 *                   example: td.123456
 *                 contentType:
 *                   type: string
 *                   nullable: true
 *                   example: audio/flac
 *                 codec:
 *                   type: string
 *                   nullable: true
 *                   example: flac
 *                 bitrate:
 *                   type: number
 *                   nullable: true
 *                   description: Kilobits per second
 *                 sampleRate:
 *                   type: number
 *                   nullable: true
 *                   description: Hertz
 *                 bitDepth:
 *                   type: number
 *                   nullable: true
 *                 durationMs:
 *                   type: number
 *                   nullable: true
 *                 contentLength:
 *                   type: number
 *                   nullable: true
 *                   description: Bytes the stream endpoint serves
 *                 quality:
 *                   type: string
 *                   enum: [original, high, medium, low]
 *                   description: The library quality that was requested or saved
 *       400:
 *         description: INVALID_PLAYBACK_ID or INVALID_QUALITY
 *       401:
 *         description: Not authenticated
 *       404:
 *         description: TRACK_NOT_FOUND
 *       409:
 *         description: SOURCE_UNAVAILABLE
 *       429:
 *         description: RATE_LIMITED; see the Retry-After header
 *       502:
 *         description: UPSTREAM_FAILED
 */
router.get(
    "/stream-info/:playbackId",
    requireAuthOrToken,
    asyncHandler(
        async (req: Request<{ playbackId: string }>, res: Response) => {
            const resolved = await resolveRequest(req, res);
            if (!resolved) return;
            const { playback, userId } = resolved;

            if (
                playback.middleware.ytMusicStreamLimiter &&
                !(await runYtMusicLimiter(req, res))
            ) {
                return;
            }

            addErrorCodes(res);
            try {
                await getPlaybackStreamInfo({
                    playback,
                    playbackId: req.params.playbackId,
                    userId,
                    req,
                    res,
                });
            } catch (err: unknown) {
                logger.error("[Playback] Stream info failed:", err);
                if (!res.headersSent) {
                    sendRouteError(res, 502, "Upstream stream info failed", {
                        code: "UPSTREAM_FAILED",
                    });
                }
            }
        },
    ),
);

export default router;
