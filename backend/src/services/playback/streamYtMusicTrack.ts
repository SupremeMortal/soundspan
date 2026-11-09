import type { Request, Response } from "express";
import { prisma } from "../../utils/db";
import { logger } from "../../utils/logger";
import { sendInternalRouteError } from "../../utils/routeErrorResponse";
import { normalizeYtMusicStreamQuality, ytMusicService } from "../youtubeMusic";
import {
    getHttpErrorStatus,
    getUserIdOrPublic,
    invalidateAllYtOAuthSessions,
} from "../ytMusicUserSession";

const DEFAULT_YTMUSIC_STREAM_QUALITY = "high";
/** Sidecar identity used when streaming without a linked YT Music account. */
const PUBLIC_YT_MUSIC_USER = "__public__";

/**
 * How a YT Music request picks its sidecar identity and quality.
 * `authenticated` uses the user's linked account when they have one and the
 * public identity otherwise, with the user's saved quality as the default.
 * `public` always uses the public identity and defaults to `HIGH`.
 */
export type YtMusicStreamMode = "authenticated" | "public";

/**
 * Inputs for {@link streamYtMusicTrack} and {@link getYtMusicStreamInfo}.
 *
 * Callers must apply, before the service: authentication
 * (`requireAuthOrToken`), the admin enablement check (the YT Music
 * `ytMusicEnabled` setting) and `ytMusicStreamLimiter` from
 * `middleware/rateLimiter`. The service writes its own error responses.
 */
export type YtMusicStreamInput = {
    videoId: string;
    /** Provider-native quality; the mode's default applies when it is not a string. */
    quality: unknown;
    /** The request is used only for the Range header. */
    req: Request;
    res: Response;
} & (
    | { mode: "authenticated"; userId: string }
    | { mode: "public"; userId?: string }
);

const AGE_RESTRICTED_BODY = {
    error: "age_restricted",
    message:
        "This content requires age verification and cannot be streamed via YouTube Music.",
};

const STREAM_PROXY_ERRORS: Record<number, { error: string; message?: string }> =
    {
        404: { error: "Stream not found" },
        451: AGE_RESTRICTED_BODY,
        503: { error: "YouTube Music streaming is busy" },
        504: { error: "YouTube Music stream timed out" },
    };

/** Writes the mapped upstream proxy error to `res`; false when the status is not mapped. */
function sendStreamProxyError(res: Response, err: unknown): boolean {
    const status = getHttpErrorStatus(err);
    if (typeof status !== "number" || !STREAM_PROXY_ERRORS[status]) {
        return false;
    }
    res.status(status).json(STREAM_PROXY_ERRORS[status]);
    return true;
}

/** Writes 401 and drops every cached OAuth session when the sidecar rejected the credentials. */
function sendAuthError(res: Response, err: unknown): boolean {
    if (getHttpErrorStatus(err) !== 401) return false;
    invalidateAllYtOAuthSessions();
    res.status(401).json({
        error: "YouTube Music authentication expired or invalid. Please reconnect your account.",
    });
    return true;
}

function requestedQuality(raw: unknown): string | undefined {
    if (typeof raw !== "string") return undefined;
    const trimmed = raw.trim();
    return trimmed.length > 0 ? trimmed : undefined;
}

/** The quality to request: the caller's, else the user's saved one, else `high`. */
async function resolveAuthenticatedQuality(
    userId: string,
    raw: unknown,
): Promise<string> {
    const requested = requestedQuality(raw);
    if (requested) return requested;
    try {
        const settings = await prisma.userSettings.findUnique({
            where: { userId },
            select: { ytMusicQuality: true },
        });
        return (
            normalizeYtMusicStreamQuality(settings?.ytMusicQuality) ??
            DEFAULT_YTMUSIC_STREAM_QUALITY
        );
    } catch (error) {
        logger.warn(
            `[YTMusic] Failed to read user quality preference for user ${userId}; falling back to ${DEFAULT_YTMUSIC_STREAM_QUALITY}`,
            error,
        );
        return DEFAULT_YTMUSIC_STREAM_QUALITY;
    }
}

async function resolveIdentity(
    input: YtMusicStreamInput,
): Promise<{ sidecarUser: string; quality: string | undefined }> {
    if (input.mode === "public") {
        return {
            sidecarUser: PUBLIC_YT_MUSIC_USER,
            quality: normalizeYtMusicStreamQuality(
                (input.quality as string) || "HIGH",
            ),
        };
    }
    return {
        sidecarUser: await getUserIdOrPublic(input.userId),
        quality: await resolveAuthenticatedQuality(input.userId, input.quality),
    };
}

/**
 * Proxies a YT Music audio stream from the sidecar to `res`, forwarding
 * status, Range and content headers. Writes its own error responses.
 */
export async function streamYtMusicTrack(
    input: YtMusicStreamInput,
): Promise<void> {
    const { videoId, req, res, mode } = input;
    const scope = mode === "public" ? "Public " : "";
    try {
        const { sidecarUser, quality } = await resolveIdentity(input);
        const proxyRes = await ytMusicService.getStreamProxy(
            sidecarUser,
            videoId,
            quality,
            req.headers.range,
        );

        res.status(proxyRes.status);
        for (const header of [
            "content-type",
            "content-length",
            "content-range",
            "accept-ranges",
        ]) {
            const value = proxyRes.headers[header];
            if (value) res.setHeader(header, value);
        }

        // A sidecar that drops mid-stream makes the browser retry with a new Range.
        proxyRes.data.on("error", (streamErr: Error) => {
            logger.warn(
                `[YTMusic Route] ${scope}Upstream stream error for ${videoId}: ${streamErr.message}`,
            );
            if (!res.headersSent) {
                res.status(502).json({ error: "Upstream stream failed" });
            } else {
                res.end();
            }
        });
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
    } catch (err: unknown) {
        if (sendStreamProxyError(res, err)) return;
        if (mode === "authenticated" && sendAuthError(res, err)) return;
        logger.error(`[YTMusic Route] ${scope}Stream proxy failed:`, err);
        sendInternalRouteError(res, "Failed to stream audio");
    }
}

/**
 * Writes YT Music stream metadata (bitrate, codec, duration) to `res` as JSON.
 * Writes its own error responses.
 */
export async function getYtMusicStreamInfo(
    input: YtMusicStreamInput,
): Promise<void> {
    const { videoId, res, mode } = input;
    try {
        const { sidecarUser, quality } = await resolveIdentity(input);
        const info = await ytMusicService.getStreamInfo(
            sidecarUser,
            videoId,
            quality,
        );
        res.json({
            videoId: info.videoId,
            abr: info.abr,
            acodec: info.acodec,
            duration: info.duration,
            content_type: info.content_type,
        });
    } catch (err: unknown) {
        if (getHttpErrorStatus(err) === 404) {
            res.status(404).json({ error: "Stream not found" });
            return;
        }
        if (getHttpErrorStatus(err) === 451) {
            res.status(451).json(AGE_RESTRICTED_BODY);
            return;
        }
        if (mode === "authenticated" && sendAuthError(res, err)) return;
        logger.error(
            `[YTMusic Route] ${mode === "public" ? "Public s" : "S"}tream info failed:`,
            err,
        );
        sendInternalRouteError(res, "Failed to get stream info");
    }
}
