import { Router, type Request, type Response } from "express";
import { asyncHandler } from "../../middleware/asyncHandler";
import { normalizeTrackPreferenceSignal } from "../../services/trackPreference";
import { parsePlaybackId } from "../../services/playback/playbackId";
import {
    PlaybackInputError,
    playbackTrackInputSchema,
    resolvePlaybackInput,
} from "../../services/playback/playbackInput";
import { sendRouteError } from "../../utils/routeErrorResponse";
import { handleSetTrackPreference } from "./tracks";
import { handleSetRemoteTrackPreference } from "./remoteTracks";

/**
 * Router segment for the source-agnostic track preference route.
 */
export const playbackPreferencesRouter = Router();

/**
 * @openapi
 * /api/library/preferences:
 *   post:
 *     summary: Set preference (like/dislike/clear) for a track by playbackId
 *     description: >-
 *       Source-agnostic counterpart of the per-track and per-remote-track
 *       preference routes. It stores the same result as the matching legacy
 *       route. `metadata` is used only when a TIDAL or YouTube Music track
 *       row must be created.
 *     tags: [Library]
 *     security:
 *       - apiKeyAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [playbackId, signal]
 *             properties:
 *               playbackId:
 *                 type: string
 *                 minLength: 1
 *                 description: "Opaque track identifier. Do not parse."
 *               signal:
 *                 type: string
 *                 enum: [thumbs_up, thumbs_down, clear]
 *               metadata:
 *                 type: object
 *                 required: [title, artist, album, durationSec]
 *                 properties:
 *                   title: { type: string, minLength: 1 }
 *                   artist: { type: string, minLength: 1 }
 *                   album: { type: string, minLength: 1 }
 *                   durationSec: { type: integer, minimum: 0 }
 *                   artworkUrl: { type: string, minLength: 1 }
 *                   isrc: { type: string, minLength: 1 }
 *     responses:
 *       200:
 *         description: Updated preference, including the request's playbackId
 *       400:
 *         description: Invalid signal, or a coded error (INVALID_PLAYBACK_ID, METADATA_REQUIRED)
 *       404:
 *         description: Track not found (code TRACK_NOT_FOUND)
 *       409:
 *         description: Source unavailable (code SOURCE_UNAVAILABLE)
 *       401:
 *         description: Not authenticated
 */
/**
 * Handles POST /api/library/preferences by translating the playbackId into
 * the legacy route's identifier and running that route's handler.
 */
export async function handleSetPlaybackPreference(req: Request, res: Response) {
    const userId = req.user?.id;
    if (!userId) {
        return sendRouteError(res, 401, "Authentication required");
    }

    const signal = normalizeTrackPreferenceSignal(
        req.body?.signal ?? req.body?.score ?? req.body?.action,
    );
    if (!signal) {
        return res.status(400).json({
            error: "Invalid preference signal. Use thumbs_up, thumbs_down, or clear.",
        });
    }

    const input = playbackTrackInputSchema.safeParse({
        playbackId: req.body?.playbackId,
        metadata: req.body?.metadata,
    });
    const playbackId = input.success ? input.data.playbackId : undefined;
    const parsed = playbackId ? parsePlaybackId(playbackId) : null;

    try {
        if (!input.success || !parsed) {
            throw new PlaybackInputError(
                "INVALID_PLAYBACK_ID",
                "Invalid playbackId",
            );
        }
        // A like may have to create the remote row, so resolve it (and fail
        // with METADATA_REQUIRED) before the legacy handler runs. Local and
        // plain YouTube ids are validated for every signal.
        if (
            signal === "thumbs_up" ||
            parsed.kind === "t" ||
            parsed.kind === "yt"
        ) {
            await resolvePlaybackInput(userId, input.data);
        }

        const legacyId =
            parsed.kind === "t"
                ? parsed.trackId
                : parsed.kind === "td"
                  ? `tidal:${parsed.tidalId}`
                  : parsed.kind === "ym"
                    ? `yt:${parsed.videoId}`
                    : "";
        const metadata = input.data.metadata;
        req.body = {
            signal,
            metadata: metadata && {
                title: metadata.title,
                artist: metadata.artist,
                album: metadata.album,
                duration: metadata.durationSec,
                thumbnailUrl: metadata.artworkUrl,
                isrc: metadata.isrc,
            },
        };
        const params = req.params as { id?: string };
        params.id = legacyId;

        const json = res.json.bind(res);
        res.json = (body: unknown) =>
            json(
                res.statusCode < 400 && body && typeof body === "object"
                    ? { ...body, playbackId }
                    : body,
            );

        if (parsed.kind === "t") {
            return await handleSetTrackPreference(
                req as Request<{ id: string }>,
                res,
            );
        }
        return await handleSetRemoteTrackPreference(
            req as Request<{ id: string }>,
            res,
        );
    } catch (error) {
        if (error instanceof PlaybackInputError) {
            return sendRouteError(res, error.status, error.message, {
                code: error.code,
            });
        }
        throw error;
    }
}

playbackPreferencesRouter.post(
    "/preferences",
    asyncHandler(handleSetPlaybackPreference),
);
