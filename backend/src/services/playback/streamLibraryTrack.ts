import type { Request, Response } from "express";
import { config } from "../../config";
import { prisma } from "../../utils/db";
import { logger } from "../../utils/logger";
import { TRACK_VISIBLE_WHERE } from "../../utils/librarySorting";
import {
    sendInternalRouteError,
    sendRouteError,
} from "../../utils/routeErrorResponse";
import { loadActiveFederationStreamPeer } from "../../routes/library/federationStreamPeer";
import {
    applyLibraryPeerFallback,
    proxyLibraryPeerStream,
} from "../../routes/library/libraryPeerStream";
import { serveNativeLibraryTrack } from "../../routes/library/libraryNativeTrackStream";

/** Inputs for {@link streamLibraryTrack}; the request is used only for Range and disconnect handling. */
export interface StreamLibraryTrackInput {
    userId: string;
    trackId: string;
    /** Raw requested quality; the user's preference (default "medium") applies when it is not a string. */
    quality: unknown;
    req: Request<{ id: string }>;
    res: Response;
    /** Set by the unified stream route; enables ETag and If-Range handling. */
    playbackId?: string;
    /** False streams without recording a play (`report=0`); defaults to true. */
    recordPlay?: boolean;
}

/**
 * Streams a library track to `res`: local file (with transcoding), federated
 * peer proxy, or a mapped fallback. Writes its own error responses.
 */
export async function streamLibraryTrack(
    input: StreamLibraryTrackInput,
): Promise<void> {
    const {
        userId,
        trackId,
        quality,
        req,
        res,
        playbackId,
        recordPlay = true,
    } = input;
    try {
        let track = await prisma.track.findUnique({
            where: { id: trackId, ...TRACK_VISIBLE_WHERE },
        });

        if (!track) {
            logger.debug("[STREAM] Track not found");
            sendRouteError(res, 404, "Track not found");
            return;
        }

        const isFederatedTrack =
            config.features.federation && track.origin === "FEDERATED";
        const federationPeer = isFederatedTrack
            ? await loadActiveFederationStreamPeer(track.peerId)
            : null;
        const canProxyPeer = Boolean(federationPeer && track.remoteId);
        const requestedQuality = await resolveStreamQuality(userId, quality);
        if (isFederatedTrack && !canProxyPeer) {
            const fallbackTrack = await applyLibraryPeerFallback({
                req,
                res,
                userId,
                trackId: track.id,
                quality: requestedQuality,
            });
            if (!fallbackTrack) return;
            track = fallbackTrack;
        }

        if (recordPlay) {
            await recordStreamPlay(userId, track.id, track.title);
        }

        if (canProxyPeer && federationPeer && track.remoteId) {
            const served = await proxyLibraryPeerStream({
                req,
                res,
                peer: federationPeer,
                remoteId: track.remoteId,
                trackId: track.id,
                sourceModified: track.fileModified,
                sourceMime: track.mime,
                requestedQuality,
            });
            if (served) return;
        }

        if (canProxyPeer) {
            const fallbackTrack = await applyLibraryPeerFallback({
                req,
                res,
                userId,
                trackId: track.id,
                quality: requestedQuality,
            });
            if (!fallbackTrack) return;
            track = fallbackTrack;
        }

        await serveNativeLibraryTrack({
            req,
            res,
            track,
            requestedQuality,
            playbackId,
        });
    } catch (error) {
        logger.error("Stream track error:", error);
        sendInternalRouteError(res, "Failed to stream track");
    }
}

async function recordStreamPlay(
    userId: string,
    trackId: string,
    title: string,
): Promise<void> {
    const recent = await prisma.play.findFirst({
        where: {
            userId,
            trackId,
            playedAt: { gte: new Date(Date.now() - 30 * 1000) },
        },
        orderBy: { playedAt: "desc" },
    });
    if (recent) return;
    await prisma.play.create({ data: { userId, trackId } });
    logger.debug("[STREAM] Logged new play for track:", title);
}

async function resolveStreamQuality(
    userId: string,
    requested: unknown,
): Promise<string> {
    if (typeof requested === "string") return requested;
    const settings = await prisma.userSettings.findUnique({
        where: { userId },
    });
    return settings?.playbackQuality || "medium";
}
