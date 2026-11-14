import { prisma } from "../../utils/db";
import { TRACK_VISIBLE_WHERE } from "../../utils/librarySorting";
import { getSystemSettings } from "../../utils/systemSettings";
import { ytMusicService } from "../youtubeMusic";
import { ensureUserOAuth } from "../ytMusicUserSession";
import { tidalStreamingService } from "../tidalStreaming";
import { tidalQualityForPlaybackQuality } from "../tidalAccountMode";
import type { ParsedPlaybackId } from "./playbackId";

/** The library quality vocabulary clients use on the unified endpoints. */
export type PlaybackQuality = "original" | "high" | "medium" | "low";

const PLAYBACK_QUALITIES: readonly PlaybackQuality[] = [
    "original",
    "high",
    "medium",
    "low",
];
const DEFAULT_PLAYBACK_QUALITY: PlaybackQuality = "medium";

/** Why a `playbackId` cannot be served; routes turn the code into a response. */
export type PlaybackResolutionErrorCode =
    | "SOURCE_UNAVAILABLE"
    | "TRACK_NOT_FOUND";

/** Thrown by {@link resolvePlayback} when no stream service can serve the id. */
export class PlaybackResolutionError extends Error {
    constructor(
        readonly code: PlaybackResolutionErrorCode,
        message: string,
    ) {
        super(message);
        this.name = "PlaybackResolutionError";
    }
}

/** Middleware a route must apply before calling the resolved stream service. */
export interface PlaybackMiddleware {
    /** `ytMusicStreamLimiter` from `middleware/rateLimiter`. */
    ytMusicStreamLimiter: boolean;
    /** The `ytMusicEnabled` admin check. */
    ytMusicEnabledCheck: boolean;
}

/**
 * The stream service that serves a `playbackId` and its provider-native
 * quality. `t` keeps the library vocabulary; the other kinds carry the
 * quality string their service expects.
 */
export type ResolvedPlayback = {
    middleware: PlaybackMiddleware;
    /** The library-vocabulary quality that was requested or saved. */
    libraryQuality: PlaybackQuality;
} & (
    | {
          kind: "t";
          trackId: string;
          quality: PlaybackQuality;
          /** Whether the library stream records a play; false for `report=0`. */
          recordPlay: boolean;
      }
    | { kind: "td"; tidalId: number; quality: string }
    | {
          kind: "ym";
          videoId: string;
          mode: "authenticated" | "public";
          quality: string;
      }
    | { kind: "yt"; videoId: string; quality: string }
);

/** Input for {@link resolvePlayback}. */
export interface ResolvePlaybackInput {
    parsed: ParsedPlaybackId;
    /** Requested quality; absent means the user's saved playback quality. */
    quality?: PlaybackQuality;
    /**
     * False when the stream must not record a play (`report=0`); absent means
     * true. Only library tracks record plays on stream.
     */
    recordPlay?: boolean;
}

const NO_MIDDLEWARE: PlaybackMiddleware = {
    ytMusicStreamLimiter: false,
    ytMusicEnabledCheck: false,
};

const YT_MUSIC_MIDDLEWARE: PlaybackMiddleware = {
    ytMusicStreamLimiter: true,
    ytMusicEnabledCheck: true,
};

/** The caller's quality, else the user's saved playback quality, else medium. */
async function effectiveQuality(
    userId: string,
    requested: PlaybackQuality | undefined,
): Promise<PlaybackQuality> {
    if (requested) return requested;
    const settings = await prisma.userSettings.findUnique({
        where: { userId },
        select: { playbackQuality: true },
    });
    const saved = settings?.playbackQuality as PlaybackQuality | undefined;
    return saved && PLAYBACK_QUALITIES.includes(saved)
        ? saved
        : DEFAULT_PLAYBACK_QUALITY;
}

/** YT Music's lowercase tiers; Original asks for its lossless tier. */
function ytMusicQuality(quality: PlaybackQuality): string {
    return quality === "original" ? "lossless" : quality;
}

/** The YouTube sidecar's tiers; Original asks for LOSSLESS. */
function youtubeQuality(quality: PlaybackQuality): string {
    return quality === "original" ? "LOSSLESS" : quality.toUpperCase();
}

async function resolveLibrary(
    userId: string,
    trackId: string,
    requested: PlaybackQuality | undefined,
    recordPlay: boolean,
): Promise<ResolvedPlayback> {
    const track = await prisma.track.findUnique({
        where: { id: trackId, ...TRACK_VISIBLE_WHERE },
        select: { id: true },
    });
    if (!track) {
        throw new PlaybackResolutionError("TRACK_NOT_FOUND", "Track not found");
    }
    const quality = await effectiveQuality(userId, requested);
    return {
        kind: "t",
        trackId,
        quality,
        recordPlay,
        libraryQuality: quality,
        middleware: NO_MIDDLEWARE,
    };
}

async function resolveTidal(
    userId: string,
    tidalId: number,
    requested: PlaybackQuality | undefined,
): Promise<ResolvedPlayback> {
    const usable =
        (await tidalStreamingService.isEnabled()) &&
        (await tidalStreamingService.isAvailable()) &&
        (await tidalStreamingService.getAuthStatus(userId)).authenticated;
    if (!usable) {
        throw new PlaybackResolutionError(
            "SOURCE_UNAVAILABLE",
            "TIDAL streaming is not available",
        );
    }
    const quality = await effectiveQuality(userId, requested);
    return {
        kind: "td",
        tidalId,
        quality: tidalQualityForPlaybackQuality(quality),
        libraryQuality: quality,
        middleware: NO_MIDDLEWARE,
    };
}

async function resolveYtMusic(
    userId: string,
    videoId: string,
    requested: PlaybackQuality | undefined,
): Promise<ResolvedPlayback> {
    const settings = await getSystemSettings();
    if (!settings?.ytMusicEnabled) {
        throw new PlaybackResolutionError(
            "SOURCE_UNAVAILABLE",
            "YouTube Music integration is not enabled",
        );
    }
    // Same decision the web player makes: the authenticated route needs the
    // sidecar up and the user's account linked; otherwise the public route.
    const linked =
        (await ytMusicService.isAvailable()) && (await ensureUserOAuth(userId));
    const quality = await effectiveQuality(userId, requested);
    return {
        kind: "ym",
        videoId,
        mode: linked ? "authenticated" : "public",
        quality: ytMusicQuality(quality),
        libraryQuality: quality,
        middleware: YT_MUSIC_MIDDLEWARE,
    };
}

/**
 * Decides which stream service serves a `playbackId` for a user, with which
 * provider-native quality, and which middleware the route must apply.
 * Throws {@link PlaybackResolutionError} when it cannot be served.
 */
export async function resolvePlayback(
    userId: string,
    input: ResolvePlaybackInput,
): Promise<ResolvedPlayback> {
    const { parsed, quality, recordPlay = true } = input;
    switch (parsed.kind) {
        case "t":
            return resolveLibrary(userId, parsed.trackId, quality, recordPlay);
        case "td":
            return resolveTidal(userId, parsed.tidalId, quality);
        case "ym":
            return resolveYtMusic(userId, parsed.videoId, quality);
        case "yt": {
            const effective = await effectiveQuality(userId, quality);
            return {
                kind: "yt",
                videoId: parsed.videoId,
                quality: youtubeQuality(effective),
                libraryQuality: effective,
                middleware: NO_MIDDLEWARE,
            };
        }
    }
}
