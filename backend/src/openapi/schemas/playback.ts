import { z } from "zod";
import { PlaybackMetadata } from "./play";

/** Stream qualities in the library vocabulary, shared by every source. */
export const PlaybackQuality = z
    .enum(["original", "high", "medium", "low"])
    .meta({ id: "PlaybackQuality" });

/** Path parameter of the unified stream operations. */
export const PlaybackIdParams = z.object({
    playbackId: z
        .string()
        .describe("Opaque track identifier, as returned in track payloads."),
});

/** Query of `GET /api/playback/stream-info/{playbackId}`. */
export const StreamInfoQuery = z.object({
    quality: PlaybackQuality.optional().describe(
        "Requested quality; the user's saved playback quality when absent.",
    ),
});

/** Query of `GET /api/playback/stream/{playbackId}`. */
export const StreamQuery = StreamInfoQuery.extend({
    report: z
        .string()
        .optional()
        .describe(
            '"0" streams without recording a play, for preloading and downloads; the client then reports the play with POST /api/plays. Absent or any other value records a play for a library track as usual. Remote sources never record a play on stream.',
        ),
});

/**
 * Codec, quality and size of what `GET /api/playback/stream/{playbackId}`
 * serves, in one shape for every source. A field a source cannot report is
 * `null`.
 */
export const StreamInfo = z
    .object({
        playbackId: z.string(),
        contentType: z.string().nullable(),
        codec: z.string().nullable(),
        bitrate: z.number().nullable().describe("Kilobits per second"),
        sampleRate: z.number().nullable().describe("Hertz"),
        bitDepth: z.number().nullable(),
        durationMs: z.number().int().nullable(),
        contentLength: z
            .number()
            .int()
            .nullable()
            .describe("Bytes the stream operation serves"),
        quality: PlaybackQuality.describe(
            "The library quality that was requested or saved",
        ),
    })
    .meta({ id: "StreamInfo" });

/** Artist of a music-track queue item. */
const PlaybackQueueArtist = z.object({
    id: z.string(),
    name: z.string(),
});

/** Album of a music-track queue item. */
const PlaybackQueueAlbum = z.object({
    id: z.string(),
    title: z.string(),
    coverArt: z.string().nullable(),
});

/**
 * One entry of a stored queue. `itemType` `episode` is a podcast episode
 * (`podcastTitle`, `podcastId`, `episodeId`, `coverUrl`); any other entry is a
 * music track (`artist`, `album`, and a `playbackId` derived when the state is
 * read). Entries stored by older clients may have no `itemType`.
 */
export const PlaybackQueueItem = z
    .object({
        itemType: z.enum(["track", "episode"]).optional(),
        id: z.string(),
        playbackId: z.string().optional(),
        title: z.string(),
        duration: z.number().describe("Seconds"),
        artist: PlaybackQueueArtist.nullable().optional(),
        album: PlaybackQueueAlbum.nullable().optional(),
        podcastTitle: z.string().optional(),
        podcastId: z.string().optional(),
        episodeId: z.string().optional(),
        coverUrl: z.string().nullable().optional(),
    })
    .meta({ id: "PlaybackQueueItem" });

/** Kinds of media a playback state describes. */
const PlaybackType = z.enum(["track", "audiobook", "podcast"]);

/** The stored playback state of one device. */
export const PlaybackState = z
    .object({
        userId: z.string(),
        deviceId: z.string(),
        playbackType: PlaybackType,
        trackId: z.string().nullable(),
        audiobookId: z.string().nullable(),
        podcastId: z.string().nullable(),
        queue: z.array(PlaybackQueueItem).nullable(),
        currentIndex: z.number().int(),
        isShuffle: z.boolean(),
        isPlaying: z.boolean(),
        currentTime: z.number().describe("Seconds"),
        updatedAt: z.iso.datetime(),
        createdAt: z.iso.datetime(),
    })
    .meta({ id: "PlaybackState" });

/**
 * One queue entry of `POST /api/playback-state`: a podcast episode
 * (`itemType` `episode`) or a music track given as `{ playbackId, metadata? }`.
 */
const SavePlaybackQueueEntry = z.object({
    itemType: z.enum(["track", "episode"]).optional(),
    id: z.string().optional(),
    playbackId: z
        .string()
        .optional()
        .describe(
            "Opaque track identifier; wins over any legacy source fields.",
        ),
    metadata: PlaybackMetadata.optional(),
    title: z.string().optional(),
    duration: z.number().optional(),
    podcastTitle: z.string().optional(),
    podcastId: z.string().optional(),
    episodeId: z.string().optional(),
    coverUrl: z.string().optional(),
});

/** Body of `POST /api/playback-state`. */
export const SavePlaybackStateRequest = z
    .object({
        playbackType: PlaybackType,
        playbackId: z
            .string()
            .optional()
            .describe(
                "Opaque identifier of the current track; stored as `trackId` for a library track.",
            ),
        podcastId: z.string().optional(),
        queue: z.array(SavePlaybackQueueEntry).optional(),
        currentIndex: z.number().int().optional(),
        isShuffle: z.boolean().optional(),
        isPlaying: z.boolean().optional(),
        currentTime: z.number().optional(),
    })
    .meta({ id: "SavePlaybackStateRequest" });

/** Answer of `DELETE /api/playback-state`. */
export const ClearPlaybackStateResponse = z
    .object({ success: z.boolean() })
    .meta({ id: "ClearPlaybackStateResponse" });
