import { z } from "zod";
import { prisma } from "../../utils/db";
import { TRACK_VISIBLE_WHERE } from "../../utils/librarySorting";
import { trackMappingService } from "../trackMappingService";
import { parsePlaybackId } from "./playbackId";

/** Display metadata a client sends with a track that may not be persisted yet. */
const playbackMetadataSchema = z.object({
    title: z.string().trim().min(1),
    artist: z.string().trim().min(1),
    album: z.string().trim().min(1),
    durationSec: z.number().int().nonnegative(),
    artworkUrl: z.string().trim().min(1).optional(),
    isrc: z.string().trim().min(1).optional(),
});

/** Request shape every write endpoint accepts: `{ playbackId, metadata? }`. */
export const playbackTrackInputSchema = z.object({
    playbackId: z.string().min(1),
    metadata: playbackMetadataSchema.optional(),
});

/** A validated `{ playbackId, metadata? }` request value. */
export type PlaybackTrackInput = z.infer<typeof playbackTrackInputSchema>;

/**
 * The internal reference existing write code stores: exactly one of the
 * three fields is set.
 */
export interface PlaybackInputReference {
    trackId: string | null;
    trackTidalId: string | null;
    trackYtMusicId: string | null;
}

/** Why a `playbackId` input cannot be resolved, with its HTTP status. */
export type PlaybackInputErrorCode =
    | "INVALID_PLAYBACK_ID"
    | "METADATA_REQUIRED"
    | "TRACK_NOT_FOUND"
    | "SOURCE_UNAVAILABLE";

const STATUS_BY_CODE: Record<PlaybackInputErrorCode, number> = {
    INVALID_PLAYBACK_ID: 400,
    METADATA_REQUIRED: 400,
    TRACK_NOT_FOUND: 404,
    SOURCE_UNAVAILABLE: 409,
};

/** Thrown by {@link resolvePlaybackInput}; routes map `code`/`status` to a response. */
export class PlaybackInputError extends Error {
    readonly status: number;

    constructor(
        readonly code: PlaybackInputErrorCode,
        message: string,
    ) {
        super(message);
        this.name = "PlaybackInputError";
        this.status = STATUS_BY_CODE[code];
    }
}

/**
 * Resolves a `playbackId` input to the internal reference write endpoints
 * store. `td` and `ym` rows are created through the same
 * `trackMappingService.ensureRemoteTrack` upsert the remote play and remote
 * playlist paths use; `metadata` is read only when a row must be created.
 * Plain YouTube (`yt`) ids cannot be stored by any write endpoint here and
 * fail with `SOURCE_UNAVAILABLE`.
 */
export async function resolvePlaybackInput(
    _userId: string,
    input: PlaybackTrackInput,
): Promise<PlaybackInputReference> {
    const parsed = parsePlaybackId(input.playbackId);
    if (!parsed) {
        throw new PlaybackInputError(
            "INVALID_PLAYBACK_ID",
            "Invalid playbackId",
        );
    }

    switch (parsed.kind) {
        case "t": {
            const track = await prisma.track.findUnique({
                where: { id: parsed.trackId, ...TRACK_VISIBLE_WHERE },
            });
            if (!track) {
                throw new PlaybackInputError(
                    "TRACK_NOT_FOUND",
                    "Track not found",
                );
            }
            return {
                trackId: parsed.trackId,
                trackTidalId: null,
                trackYtMusicId: null,
            };
        }
        case "td": {
            const existing = await prisma.trackTidal.findUnique({
                where: { tidalId: parsed.tidalId },
                select: { id: true },
            });
            const id =
                existing?.id ??
                (
                    await trackMappingService.ensureRemoteTrack({
                        provider: "tidal",
                        tidalId: parsed.tidalId,
                        ...requireMetadata(input),
                    })
                ).id;
            return { trackId: null, trackTidalId: id, trackYtMusicId: null };
        }
        case "ym": {
            const existing = await prisma.trackYtMusic.findUnique({
                where: { videoId: parsed.videoId },
                select: { id: true },
            });
            const id =
                existing?.id ??
                (
                    await trackMappingService.ensureRemoteTrack({
                        provider: "youtube",
                        videoId: parsed.videoId,
                        ...requireMetadata(input),
                    })
                ).id;
            return { trackId: null, trackTidalId: null, trackYtMusicId: id };
        }
        case "yt":
            throw new PlaybackInputError(
                "SOURCE_UNAVAILABLE",
                "Plain YouTube tracks cannot be stored by this endpoint",
            );
    }
}

function requireMetadata(input: PlaybackTrackInput) {
    const metadata = input.metadata;
    if (!metadata) {
        throw new PlaybackInputError(
            "METADATA_REQUIRED",
            "metadata is required to add a track that is not stored yet",
        );
    }
    return {
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        duration: metadata.durationSec,
        isrc: metadata.isrc,
        thumbnailUrl: metadata.artworkUrl,
    };
}
