import type { Request, Response } from "express";
import type { Track } from "@prisma/client";
import {
    AudioStreamingService,
    type Quality,
} from "../../services/audioStreaming";
import { config } from "../../config";
import { safeResolvePath } from "../../utils/safeResolvePath";
import { logger } from "../../utils/logger";
import {
    sendInternalRouteError,
    sendRouteError,
} from "../../utils/routeErrorResponse";

const log = logger.child("LibraryNativeTrackStream");

/**
 * ETag inputs for the unified stream: the file actually served identifies the
 * variant (original file or one transcode-cache quality). The per-source
 * routes pass no playbackId and keep their validator-free responses.
 */
function sendServedFile(
    input: {
        req: Request;
        res: Response;
        service: AudioStreamingService;
        playbackId?: string;
    },
    served: { filePath: string; mimeType: string },
): Promise<void> {
    const { req, res, service, playbackId } = input;
    if (!playbackId) {
        return service.streamFileWithRangeSupport(
            req,
            res,
            served.filePath,
            served.mimeType,
        );
    }
    return service.streamFileWithRangeSupport(
        req,
        res,
        served.filePath,
        served.mimeType,
        undefined,
        { playbackId, variant: served.filePath },
    );
}

async function streamNativeFile(input: {
    req: Request;
    res: Response;
    track: Track;
    quality: Quality;
    absolutePath: string;
    service: AudioStreamingService;
    playbackId?: string;
}): Promise<void> {
    try {
        const streamFile = await input.service.getStreamFilePath(
            input.track.id,
            input.quality,
            input.track.fileModified,
            input.absolutePath,
        );
        await sendServedFile(input, streamFile);
    } catch (error: any) {
        if (error.code !== "FFMPEG_NOT_FOUND" || input.quality === "original") {
            throw error;
        }
        const original = await input.service.getStreamFilePath(
            input.track.id,
            "original",
            input.track.fileModified,
            input.absolutePath,
        );
        await sendServedFile(input, original);
    }
}

/** Streams a local library file with bounded transcode fallback. */
export async function serveNativeLibraryTrack(input: {
    req: Request;
    res: Response;
    track: Track;
    requestedQuality: string;
    /** Set by the unified stream route to send an ETag and honour If-Range. */
    playbackId?: string;
}): Promise<Response | void> {
    if (!input.track.filePath) {
        return sendRouteError(input.res, 404, "Track not available");
    }
    const normalizedPath = input.track.filePath.replace(/\\/g, "/");
    const absolutePath = safeResolvePath(
        config.music.musicPath,
        normalizedPath,
    );
    if (!absolutePath) {
        log.warn("Rejected out-of-root stream path", {
            trackId: input.track.id,
        });
        return sendRouteError(input.res, 404, "Track not available");
    }
    const service = new AudioStreamingService(
        config.music.musicPath,
        config.music.transcodeCachePath,
        config.music.transcodeCacheMaxGb,
    );
    try {
        await streamNativeFile({
            ...input,
            quality: input.requestedQuality as Quality,
            absolutePath,
            service,
        });
    } catch (error) {
        log.error("Native streaming failed", { error });
        return sendInternalRouteError(input.res, "Failed to stream track");
    } finally {
        service.destroy();
    }
}
