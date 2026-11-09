import type { Request, Response } from "express";
import {
    awaitTidalPlayDownload,
    findTidalPlayDownload,
    isTidalPlayDownloadEnabled,
    openTidalPlayDownload,
    resolveTidalPlayDownloadQuality,
    streamTidalPlayDownload,
    tidalPlayDownloadInfo,
    tidalPlayDownloadStartInfo,
    tidalPlayDownloadStreamInfo,
} from "../tidalPlayDownloads";
import { tidalStreamingService } from "../tidalStreaming";
import {
    ensureUserOAuth,
    markTidalSessionStale,
    setTidalOAuthCache,
} from "../tidalUserSession";
import { toErrorMessage } from "../../utils/errors";
import { logger } from "../../utils/logger";
import {
    sendInternalRouteError,
    sendRouteError,
} from "../../utils/routeErrorResponse";

/** Inputs for {@link streamTidalTrack} and {@link getTidalStreamInfo}. */
export interface TidalStreamInput {
    userId: string;
    /** Numeric TIDAL track id. */
    trackId: number;
    /** Provider-native TIDAL quality; the user's preference applies when it is not a string. */
    quality: unknown;
    /** The request is used only for Range and disconnect handling. */
    req: Request;
    res: Response;
}

// ── Download as you play ──────────────────────────────────────────

/** Whether the admin turned on download-as-you-play; never throws. */
async function playDownloadsEnabled(): Promise<boolean> {
    try {
        return await isTidalPlayDownloadEnabled();
    } catch (err: unknown) {
        logger.warn(
            "[TIDAL-STREAM] Download-as-you-play setting unavailable:",
            toErrorMessage(err),
        );
        return false;
    }
}

/** Whether a Range header asks for bytes after the start of the file. */
function requestsLaterBytes(range: string | undefined): boolean {
    const match = /^bytes=(\d+)-/.exec(range ?? "");
    return Boolean(match && Number(match[1]) > 0);
}

/**
 * Play a TIDAL song from its download: the local file once it exists,
 * otherwise the download's bytes as they arrive. A request for later bytes
 * (a seek, or a resumed player) waits for the whole file, because the
 * stream itself cannot seek. Nothing streams straight from TIDAL.
 */
async function streamFromPlayDownload(
    req: Request,
    res: Response,
    userId: string,
    trackId: number,
): Promise<void> {
    let file = await findTidalPlayDownload(trackId);
    if (!file && requestsLaterBytes(req.headers.range)) {
        file = await awaitTidalPlayDownload(trackId, userId);
        if (!file) throw new Error("TIDAL play download failed");
    }
    if (file) {
        const quality = await resolveTidalPlayDownloadQuality(userId);
        try {
            await streamTidalPlayDownload(req, res, file, quality);
        } catch (err: unknown) {
            logger.error(
                `[TIDAL-STREAM] Downloaded file failed for track ${trackId}:`,
                toErrorMessage(err),
            );
            if (!res.headersSent) sendInternalRouteError(res, "Stream failed");
        }
        return;
    }
    const { stream, info } = await openTidalPlayDownload(trackId, userId);
    res.status(200);
    res.setHeader("Content-Type", info.contentType);
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Accept-Ranges", "none");
    // Leaving early only stops this copy; the sidecar finishes the download.
    res.on("close", () => {
        (
            stream as NodeJS.ReadableStream & { destroy?: () => void }
        ).destroy?.();
    });
    stream.on("error", (streamErr: Error) => {
        logger.warn(
            `[TIDAL-STREAM] Play download stream error for track ${trackId}: ${streamErr.message}`,
        );
        if (!res.headersSent) sendRouteError(res, 502, "Download failed");
        else res.end();
    });
    stream.pipe(res);
}

/**
 * Streams a TIDAL track to `res`. With download-as-you-play on, plays from the
 * download; otherwise proxies the sidecar stream with the user's (or the
 * shared instance) account. Writes its own error responses.
 */
export async function streamTidalTrack(input: TidalStreamInput): Promise<void> {
    const { userId, trackId, req, res } = input;
    if (await playDownloadsEnabled()) {
        try {
            await streamFromPlayDownload(req, res, userId, trackId);
        } catch (err: unknown) {
            logger.error(
                `[TIDAL-STREAM] Play download failed for track ${trackId}:`,
                toErrorMessage(err),
            );
            if (!res.headersSent) sendRouteError(res, 502, "Download failed");
        }
        return;
    }

    // Get user's preferred quality
    let quality = typeof input.quality === "string" ? input.quality : undefined;
    if (!quality) {
        quality = await tidalStreamingService.getUserPreferredQuality(userId);
    }

    try {
        const hasAuth = await ensureUserOAuth(userId);
        if (!hasAuth) {
            setTidalOAuthCache(userId, false);
            res.status(401).json({ error: "Not authenticated to TIDAL" });
            return;
        }

        const rangeHeader = req.headers.range;
        const stream = await tidalStreamingService.getStreamProxy(
            userId,
            trackId,
            quality,
            rangeHeader,
        );

        // Forward response headers
        const responseHeaders: Record<string, string> = {
            "Accept-Ranges": "bytes",
            "Cache-Control": "no-cache",
        };

        if (stream.headers["content-type"]) {
            responseHeaders["Content-Type"] = stream.headers["content-type"];
        }
        if (stream.headers["content-range"]) {
            responseHeaders["Content-Range"] = stream.headers["content-range"];
        }

        res.status(stream.status);
        Object.entries(responseHeaders).forEach(([key, value]) => {
            res.setHeader(key, value);
        });

        stream.data.on("error", (streamErr: Error) => {
            logger.warn(
                `[TIDAL-STREAM] Upstream stream error for track ${trackId}: ${streamErr.message}`,
            );
            if (!res.headersSent) {
                res.status(502).json({ error: "Upstream stream failed" });
            } else {
                res.end();
            }
        });
        // Clean up upstream stream when client disconnects
        res.on("close", () => {
            if (
                stream.data &&
                typeof stream.data.destroy === "function" &&
                !stream.data.destroyed
            ) {
                stream.data.destroy();
            }
        });
        stream.data.pipe(res);
    } catch (err: any) {
        if (err?.response?.status === 401) {
            markTidalSessionStale(userId);
        }
        logger.error(
            `[TIDAL-STREAM] Stream proxy failed for track ${trackId}:`,
            err.message,
        );
        if (!res.headersSent) {
            res.status(500).json({ error: "Stream failed" });
        }
    }
}

/**
 * Writes TIDAL stream metadata (quality, codec, ...) to `res` as JSON: the
 * download's description with download-as-you-play on, otherwise the sidecar's.
 * Writes its own error responses.
 */
export async function getTidalStreamInfo(
    input: TidalStreamInput,
): Promise<void> {
    const { userId, trackId, res } = input;
    let quality = typeof input.quality === "string" ? input.quality : undefined;

    if (await playDownloadsEnabled()) {
        try {
            const file = await findTidalPlayDownload(trackId);
            if (file) {
                const fileQuality =
                    await resolveTidalPlayDownloadQuality(userId);
                res.json(tidalPlayDownloadStreamInfo(file, fileQuality));
                return;
            }
            const info = await tidalPlayDownloadInfo(trackId, userId);
            res.json(tidalPlayDownloadStartInfo(trackId, info));
            return;
        } catch (err: unknown) {
            logger.error(
                `[TIDAL-STREAM] Play download info failed for track ${trackId}:`,
                toErrorMessage(err),
            );
            sendRouteError(res, 502, "Download failed");
            return;
        }
    }

    try {
        const hasAuth = await ensureUserOAuth(userId);
        if (!hasAuth) {
            setTidalOAuthCache(userId, false);
            res.status(401).json({ error: "Not authenticated to TIDAL" });
            return;
        }

        if (!quality) {
            quality =
                await tidalStreamingService.getUserPreferredQuality(userId);
        }

        const info = await tidalStreamingService.getStreamInfo(
            userId,
            trackId,
            quality,
        );
        res.json(info);
    } catch (err: any) {
        if (err?.response?.status === 401) {
            markTidalSessionStale(userId);
        }
        logger.error("[TIDAL-STREAM] Stream info failed:", err.message);
        res.status(500).json({ error: "Failed to get stream info" });
    }
}
