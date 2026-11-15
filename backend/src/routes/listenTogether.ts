/**
 * REST routes for Listen Together.
 *
 * These handle the "cold path": creating groups, joining by code,
 * discovering public groups, leaving, and ending groups.
 *
 * All real-time playback sync goes through Socket.IO (listenTogetherSocket.ts).
 */

import { Router, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth";
import { logger } from "../utils/logger";
import {
    createGroup,
    joinGroup,
    discoverGroups,
    getActiveGroupCount,
    getMyGroup,
    leaveGroup,
    endGroup,
} from "../services/listenTogether";
import { GroupError } from "../services/listenTogetherManager";
import { JoinListenGroupRequest } from "../openapi/schemas/listenTogether";

const router = Router();
router.use(requireAuth);

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const queueTrackInputSchema = z
    .object({
        playbackId: z.string().min(1).optional(),
        metadata: z
            .object({
                title: z.string().trim().min(1),
                artist: z.string().trim().min(1),
                album: z.string().trim().min(1),
                durationSec: z.number().int().nonnegative(),
                artworkUrl: z.string().trim().min(1).optional(),
                isrc: z.string().trim().min(1).optional(),
            })
            .optional(),
        trackId: z.string().min(1).optional(),
        tidalTrackId: z.number().int().positive().optional(),
        youtubeVideoId: z.string().min(1).optional(),
        title: z.string().optional(),
        artist: z.string().optional(),
        album: z.string().optional(),
        duration: z.number().int().nonnegative().optional(),
        thumbnailUrl: z.string().optional(),
        isrc: z.string().optional(),
    })
    .refine(
        (value) =>
            value.playbackId !== undefined ||
            [value.trackId, value.tidalTrackId, value.youtubeVideoId].filter(
                (entry) => entry !== undefined,
            ).length === 1,
        {
            message:
                "Each queue track requires a playbackId or exactly one of trackId, tidalTrackId, or youtubeVideoId",
        },
    );

const createGroupSchema = z.object({
    name: z.string().trim().min(1).max(80).optional(),
    visibility: z.enum(["public", "private"]).optional(),
    queueTrackIds: z.array(z.string().min(1)).optional(),
    queueTracks: z.array(queueTrackInputSchema).optional(),
    currentTrackId: z.string().min(1).optional(),
    currentTimeMs: z.number().finite().min(0).max(86_400_000).optional(),
    isPlaying: z.boolean().optional(),
});

const joinGroupSchema = JoinListenGroupRequest;

// ---------------------------------------------------------------------------
// Error handler
// ---------------------------------------------------------------------------

function handleError(label: string, error: unknown, res: Response) {
    if (error instanceof z.ZodError) {
        return res
            .status(400)
            .json({ error: "Invalid request", details: error.issues });
    }
    if (error instanceof GroupError) {
        const statusMap: Record<string, number> = {
            NOT_FOUND: 404,
            NOT_MEMBER: 403,
            NOT_ALLOWED: 403,
            INVALID: 400,
            INVALID_PLAYBACK_ID: 400,
            CONFLICT: 409,
            UNAVAILABLE: 503,
        };
        const status = statusMap[error.code] ?? 500;
        if (status === 500) {
            logger.error(`[ListenTogether] ${label}:`, error.message);
            return res.status(status).json({ error: "Internal server error" });
        }
        return res.status(status).json({
            error: error.message,
            ...(error.code === "INVALID_PLAYBACK_ID"
                ? { code: error.code }
                : {}),
        });
    }
    logger.error(`[ListenTogether] ${label} failed:`, error);
    return res.status(500).json({ error: "Internal server error" });
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

router.post("/", async (req, res) => {
    try {
        const user = req.user!;
        const payload = createGroupSchema.parse(req.body ?? {});
        const snapshot = await createGroup(user.id, user.username, payload);
        return res.status(201).json(snapshot);
    } catch (error) {
        return handleError("create", error, res);
    }
});

router.post("/join", async (req, res) => {
    try {
        const user = req.user!;
        const payload = joinGroupSchema.parse(req.body ?? {});
        const snapshot = await joinGroup(
            user.id,
            user.username,
            payload.joinCode,
        );
        return res.json(snapshot);
    } catch (error) {
        return handleError("join", error, res);
    }
});

router.get("/discover", async (req, res) => {
    try {
        const groups = await discoverGroups(req.user!.id);
        return res.json(groups);
    } catch (error) {
        return handleError("discover", error, res);
    }
});

/**
 * @openapi
 * /api/listen-together/active-count:
 *   get:
 *     summary: Get the count of active Listen Together groups
 *     tags: [Listen Together]
 *     security:
 *       - apiKeyAuth: []
 *     responses:
 *       200:
 *         description: Count of active groups
 */
router.get("/active-count", async (_req, res) => {
    try {
        const count = await getActiveGroupCount();
        return res.json({ count });
    } catch (error) {
        return handleError("active-count", error, res);
    }
});

router.get("/mine", async (req, res) => {
    try {
        const snapshot = await getMyGroup(req.user!.id);
        return res.json(snapshot);
    } catch (error) {
        return handleError("mine", error, res);
    }
});

router.post("/:groupId/leave", async (req, res) => {
    try {
        const result = await leaveGroup(req.user!.id, req.params.groupId);
        return res.json({ success: true, ...result });
    } catch (error) {
        return handleError("leave", error, res);
    }
});

router.post("/:groupId/end", async (req, res) => {
    try {
        await endGroup(req.user!.id, req.params.groupId);
        return res.json({ success: true });
    } catch (error) {
        return handleError("end", error, res);
    }
});

export default router;
