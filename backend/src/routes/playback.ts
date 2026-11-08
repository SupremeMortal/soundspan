/**
 * Unified playback routes, mounted at `/api/playback`.
 *
 * One stream surface for every track source, addressed by an opaque
 * `playbackId`:
 *
 *   GET /stream/:playbackId - Audio stream (Range supported)
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
import { streamLibraryTrack } from "../services/playback/streamLibraryTrack";
import { streamTidalTrack } from "../services/playback/streamTidalTrack";
import { streamYtMusicTrack } from "../services/playback/streamYtMusicTrack";
import { streamYouTubeVideo } from "../services/playback/streamYouTubeVideo";
import { sendRouteError } from "../utils/routeErrorResponse";
import { logger } from "../utils/logger";

const router = Router();

// Stream starts share the budget the library stream route uses.
router.use("/stream/:playbackId", streamingLimiter);

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

async function dispatchStream(
    playback: ResolvedPlayback,
    userId: string,
    req: Request,
    res: Response,
): Promise<void> {
    switch (playback.kind) {
        case "t":
            return streamLibraryTrack({
                userId,
                trackId: playback.trackId,
                quality: playback.quality,
                req: req as Request<{ id: string }>,
                res,
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
 *       whatever source backs it. Supports Range requests. Authenticate with
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
    asyncHandler(async (req: Request<{ playbackId: string }>, res: Response) => {
        const parsed = parsePlaybackId(req.params.playbackId);
        if (!parsed) {
            sendRouteError(res, 400, "Invalid playbackId", {
                code: "INVALID_PLAYBACK_ID",
            });
            return;
        }
        let quality: PlaybackQuality | undefined;
        if (req.query.quality !== undefined) {
            const q = qualitySchema.safeParse(req.query.quality);
            if (!q.success) {
                sendRouteError(res, 400, "Invalid quality", {
                    code: "INVALID_QUALITY",
                });
                return;
            }
            quality = q.data;
        }

        const userId = req.user!.id;
        let playback: ResolvedPlayback;
        try {
            playback = await resolvePlayback(userId, { parsed, quality });
        } catch (err: unknown) {
            if (err instanceof PlaybackResolutionError) {
                sendResolutionError(res, err);
                return;
            }
            throw err;
        }

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
    }),
);

export default router;
