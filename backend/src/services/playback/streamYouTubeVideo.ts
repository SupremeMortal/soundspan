import type { Response } from "express";
import { youtubeDownloadService } from "../youtubeDownload";
import { logger } from "../../utils/logger";
import { sendRouteError } from "../../utils/routeErrorResponse";

/** Inputs for {@link streamYouTubeVideo}. */
export interface YouTubeStreamInput {
    /** Canonical YouTube video id. */
    videoId: string;
    /** Provider-native quality (LOW, MEDIUM, HIGH, LOSSLESS); defaults to HIGH. */
    quality: unknown;
    /** The request's Range header, passed through to the sidecar. */
    range: string | undefined;
    res: Response;
}

/** Upstream headers copied onto the response. */
const FORWARD_HEADERS = [
    "content-type",
    "content-length",
    "content-range",
    "accept-ranges",
];

/**
 * Proxies a YouTube video's audio from the sidecar to `res`, forwarding the
 * upstream status and range headers. Writes its own error responses.
 */
export async function streamYouTubeVideo(
    input: YouTubeStreamInput,
): Promise<void> {
    const { videoId, range, res } = input;
    const quality = (
        typeof input.quality === "string" && input.quality
            ? input.quality
            : "HIGH"
    ).toUpperCase();
    try {
        const proxyRes = await youtubeDownloadService.getStreamProxy(
            videoId,
            quality,
            range,
        );

        res.status(proxyRes.status);
        for (const header of FORWARD_HEADERS) {
            const value = proxyRes.headers[header];
            if (value) res.setHeader(header, value);
        }

        proxyRes.data.on("error", (streamErr: Error) => {
            logger.warn(
                `[YouTube Route] Upstream stream error for ${videoId}: ${streamErr.message}`,
            );
            if (!res.headersSent) {
                res.status(502).json({ error: "Upstream stream failed" });
            } else {
                res.end();
            }
        });
        // Clean up the upstream stream when the client disconnects.
        res.on("close", () => {
            if (
                proxyRes.data &&
                typeof proxyRes.data.destroy === "function" &&
                !proxyRes.data.destroyed
            ) {
                proxyRes.data.destroy();
            }
        });
        proxyRes.data.pipe(res);
    } catch (err: any) {
        if (err.response?.status === 404) {
            res.status(404).json({ error: "Stream not found" });
            return;
        }
        if (err.response?.status === 451) {
            sendRouteError(
                res,
                451,
                "This content requires age verification and cannot be streamed.",
            );
            return;
        }
        logger.error("[YouTube Route] Stream proxy failed:", err.message);
        res.status(500).json({ error: "Failed to stream audio" });
    }
}
