import fs from "fs";
import type { Request, Response } from "express";
import { prisma } from "../../utils/db";
import { TRACK_VISIBLE_WHERE } from "../../utils/librarySorting";
import {
    buildFederatedAudioInfo,
    resolveAudioInfoAbsolutePath,
} from "../../utils/libraryAudioInfo";
import {
    TRACK_AUDIO_INFO_SELECT,
    isFederatedAudioInfoTrack,
    loadLocalAudioInfo,
    resolvePlaybackAudioInfoPath,
} from "../../routes/library/trackAudioInfo";
import { sendRouteError } from "../../utils/routeErrorResponse";
import { logger } from "../../utils/logger";
import { youtubeDownloadService } from "../youtubeDownload";
import { getTidalStreamInfo } from "./streamTidalTrack";
import { getYtMusicStreamInfo } from "./streamYtMusicTrack";
import type { PlaybackQuality, ResolvedPlayback } from "./resolvePlayback";

/** The one stream-info shape every source answers with; unknown fields are null. */
export interface UnifiedStreamInfo {
    playbackId: string;
    contentType: string | null;
    codec: string | null;
    /** kbps */
    bitrate: number | null;
    /** Hz */
    sampleRate: number | null;
    bitDepth: number | null;
    durationMs: number | null;
    /** Bytes of the representation that `/stream` serves. */
    contentLength: number | null;
    /** The library-vocabulary quality that was requested or saved. */
    quality: PlaybackQuality;
}

/** Inputs for {@link getPlaybackStreamInfo}. */
export interface PlaybackStreamInfoInput {
    playback: ResolvedPlayback;
    playbackId: string;
    userId: string;
    req: Request;
    res: Response;
}

function text(value: unknown): string | null {
    return typeof value === "string" && value.trim() ? value.trim() : null;
}

function positive(value: unknown): number | null {
    return typeof value === "number" && Number.isFinite(value) && value > 0
        ? value
        : null;
}

function lowerCodec(value: unknown): string | null {
    return text(value)?.toLowerCase() ?? null;
}

function seconds(value: unknown): number | null {
    const s = positive(value);
    return s === null ? null : Math.round(s * 1000);
}

const EMPTY_INFO = {
    contentType: null,
    codec: null,
    bitrate: null,
    sampleRate: null,
    bitDepth: null,
    durationMs: null,
    contentLength: null,
} as const;

/**
 * Runs a per-source stream-info service that writes its answer with
 * `res.json`, rewriting a successful body into the unified shape. Error
 * responses pass through unchanged.
 */
async function adaptServiceJson(
    res: Response,
    toUnified: (body: Record<string, unknown>) => UnifiedStreamInfo,
    run: () => Promise<void>,
): Promise<void> {
    const json = res.json.bind(res);
    res.json = ((body?: unknown) => {
        if (
            res.statusCode < 400 &&
            body &&
            typeof body === "object" &&
            !Array.isArray(body)
        ) {
            return json(toUnified(body as Record<string, unknown>));
        }
        return json(body);
    }) as Response["json"];
    await run();
}

async function tidalInfo(
    input: PlaybackStreamInfoInput,
    playback: Extract<ResolvedPlayback, { kind: "td" }>,
): Promise<void> {
    const { res, playbackId, userId, req } = input;
    await adaptServiceJson(
        res,
        (body) => ({
            ...EMPTY_INFO,
            playbackId,
            contentType: text(body.content_type),
            codec: lowerCodec(body.acodec),
            sampleRate: positive(body.sample_rate),
            bitDepth: positive(body.bit_depth),
            quality: playback.libraryQuality,
        }),
        () =>
            getTidalStreamInfo({
                userId,
                trackId: playback.tidalId,
                quality: playback.quality,
                req,
                res,
            }),
    );
}

async function ytMusicInfo(
    input: PlaybackStreamInfoInput,
    playback: Extract<ResolvedPlayback, { kind: "ym" }>,
): Promise<void> {
    const { res, playbackId, userId, req } = input;
    const bitrate = (body: Record<string, unknown>) => {
        const abr = positive(body.abr);
        return abr === null ? null : Math.round(abr);
    };
    await adaptServiceJson(
        res,
        (body) => ({
            ...EMPTY_INFO,
            playbackId,
            contentType: text(body.content_type),
            codec: lowerCodec(body.acodec),
            bitrate: bitrate(body),
            durationMs: seconds(body.duration),
            quality: playback.libraryQuality,
        }),
        () =>
            getYtMusicStreamInfo(
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
            ),
    );
}

function upstreamStatus(err: unknown): number | undefined {
    const status = (err as { response?: { status?: unknown } } | null)?.response
        ?.status;
    return typeof status === "number" ? status : undefined;
}

async function youtubeInfo(
    input: PlaybackStreamInfoInput,
    playback: Extract<ResolvedPlayback, { kind: "yt" }>,
): Promise<void> {
    const { res, playbackId } = input;
    try {
        const info = await youtubeDownloadService.getVideoInfo(
            `https://www.youtube.com/watch?v=${playback.videoId}`,
        );
        const container =
            info.audioFormat === "webm"
                ? { contentType: "audio/webm", codec: "opus" }
                : info.audioFormat === "mp4"
                  ? { contentType: "audio/mp4", codec: "aac" }
                  : { contentType: null, codec: null };
        const body: UnifiedStreamInfo = {
            ...EMPTY_INFO,
            ...container,
            playbackId,
            durationMs: seconds(info.duration),
            quality: playback.libraryQuality,
        };
        res.json(body);
    } catch (err: unknown) {
        if (upstreamStatus(err) === 404) {
            sendRouteError(res, 404, "Video not found", {
                code: "TRACK_NOT_FOUND",
            });
            return;
        }
        logger.error("[Playback] YouTube stream info failed:", err);
        sendRouteError(res, 502, "Failed to get stream info", {
            code: "UPSTREAM_FAILED",
        });
    }
}

async function libraryInfo(
    input: PlaybackStreamInfoInput,
    playback: Extract<ResolvedPlayback, { kind: "t" }>,
): Promise<void> {
    const { res, playbackId, userId } = input;
    const notFound = (message: string) =>
        sendRouteError(res, 404, message, { code: "TRACK_NOT_FOUND" });
    try {
        const track = await prisma.track.findUnique({
            where: { id: playback.trackId, ...TRACK_VISIBLE_WHERE },
            select: TRACK_AUDIO_INFO_SELECT,
        });
        if (!track) return void notFound("Track not found");

        const base = {
            playbackId,
            durationMs: seconds(track.duration),
            quality: playback.libraryQuality,
        };

        if (isFederatedAudioInfoTrack(track)) {
            const audio = buildFederatedAudioInfo(track);
            res.json({
                ...EMPTY_INFO,
                ...base,
                contentType: text(track.mime),
                codec: lowerCodec(audio.codec),
                bitrate: positive(audio.bitrate),
                contentLength: positive(track.fileSize),
            } satisfies UnifiedStreamInfo);
            return;
        }
        if (!track.filePath) return void notFound("Track not found");

        const absolutePath = resolveAudioInfoAbsolutePath(track.filePath);
        if (!absolutePath || !fs.existsSync(absolutePath)) {
            return void notFound("File not found on disk");
        }

        let metadataPath = absolutePath;
        let transcoded = false;
        if (playback.quality !== "original") {
            const served = await resolvePlaybackAudioInfoPath(
                playback.trackId,
                track.fileModified,
                absolutePath,
                userId,
                playback.quality,
            );
            metadataPath = served.metadataPath;
            transcoded = metadataPath !== absolutePath;
        }
        const audio = await loadLocalAudioInfo(
            playback.trackId,
            track.filePath,
            track.fileModified,
            metadataPath,
            transcoded ? "playback" : "source",
            transcoded ? playback.quality : null,
        );
        if (!audio) return void notFound("Playback file not found on disk");
        const { size } = await fs.promises.stat(metadataPath);

        res.json({
            ...EMPTY_INFO,
            ...base,
            contentType: transcoded ? "audio/mpeg" : text(track.mime),
            codec: lowerCodec(audio.codec),
            bitrate: positive(audio.bitrate),
            sampleRate: positive(audio.sampleRate),
            bitDepth: positive(audio.bitDepth),
            contentLength: positive(size),
        } satisfies UnifiedStreamInfo);
    } catch (err: unknown) {
        logger.error("[Playback] Library stream info failed:", err);
        sendRouteError(res, 502, "Failed to read audio metadata", {
            code: "UPSTREAM_FAILED",
        });
    }
}

/**
 * Writes the unified stream info for a resolved playback to `res`, using the
 * same per-source services the existing stream-info routes use. Writes its own
 * error responses.
 */
export async function getPlaybackStreamInfo(
    input: PlaybackStreamInfoInput,
): Promise<void> {
    const { playback } = input;
    switch (playback.kind) {
        case "t":
            return libraryInfo(input, playback);
        case "td":
            return tidalInfo(input, playback);
        case "ym":
            return ytMusicInfo(input, playback);
        case "yt":
            return youtubeInfo(input, playback);
    }
}
