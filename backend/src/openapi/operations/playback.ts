import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import { Lyrics, LyricsParams, LyricsQuery } from "../schemas/lyrics";
import {
    PlayNotRecorded,
    PlayRecord,
    RecordPlayRequest,
} from "../schemas/play";
import {
    ClearPlaybackStateResponse,
    PlaybackIdParams,
    PlaybackState,
    SavePlaybackStateRequest,
    StreamInfo,
    StreamInfoQuery,
    StreamQuery,
} from "../schemas/playback";

/** JSON error statuses of the unified stream and stream-info operations. */
const streamErrors = {
    ...standardErrors,
    400: ApiError,
    404: ApiError,
    409: ApiError,
    429: ApiError,
    502: ApiError,
    504: ApiError,
} as const;

const DEVICE_HEADER =
    "The `X-Playback-Device-Id` request header selects the device whose state is read or written; it defaults to `legacy` and is cut to 128 characters.";

/** Playback, play reporting, playback state and lyrics operations. */
export const playbackOperations = [
    defineOperation({
        method: "get",
        path: "/api/playback/stream/{playbackId}",
        operationId: "streamTrack",
        tag: "playback",
        summary: "Stream audio for any track source",
        description:
            "Supports `Range` requests (`206` with `Content-Range`). Library tracks carry a strong `ETag`; to resume a download, send it back as `If-Range` with a `Range` header: a matching `ETag` answers `206`, anything else (a changed file, or a source without a strong `ETag`) answers `200` with the full body. Errors carry `code` `INVALID_PLAYBACK_ID`, `INVALID_QUALITY`, `TRACK_NOT_FOUND`, `SOURCE_UNAVAILABLE`, `RATE_LIMITED` (with `Retry-After`) or `UPSTREAM_FAILED`. Authenticate with an `X-API-Key` header, a Bearer token, or a `token` query parameter.",
        params: PlaybackIdParams,
        query: StreamQuery,
        responses: {
            200: { binary: "audio/*" },
            206: { binary: "audio/*" },
            ...streamErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/playback/stream-info/{playbackId}",
        operationId: "getStreamInfo",
        tag: "playback",
        summary: "Describe the audio stream for any track source",
        description:
            "Codec, quality and size of what `streamTrack` serves for the same `playbackId` and `quality`. Errors are those of `streamTrack`.",
        params: PlaybackIdParams,
        query: StreamInfoQuery,
        responses: { 200: StreamInfo, ...streamErrors },
    }),
    defineOperation({
        method: "post",
        path: "/api/plays",
        operationId: "recordPlay",
        tag: "playback",
        summary: "Record a play of a track",
        description:
            "A request that repeats the same user, track and `playedAt` answers with the play already recorded and records nothing new. A `listenedMs` below 5000 records nothing and answers `{ recorded: false }`. `metadata` is required (400 `METADATA_REQUIRED`) only when a TIDAL or YouTube Music track row must be created. Legacy identifier fields (`trackId`, `tidalTrackId`, `youtubeVideoId` with display fields) exist for other consumers; a `playbackId` wins over them.",
        body: RecordPlayRequest,
        responses: {
            200: z.union([PlayRecord, PlayNotRecorded]),
            ...standardErrors,
            400: ApiError,
            404: ApiError,
            409: ApiError,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/playback-state",
        operationId: "getPlaybackState",
        tag: "playback",
        summary: "Read the stored playback state of this device",
        description: `${DEVICE_HEADER} Answers \`null\` when no state is stored. Music-track queue items carry a \`playbackId\` derived when the state is read.`,
        responses: { 200: PlaybackState.nullable(), ...standardErrors },
    }),
    defineOperation({
        method: "post",
        path: "/api/playback-state",
        operationId: "savePlaybackState",
        tag: "playback",
        summary: "Store the playback state of this device",
        description: `${DEVICE_HEADER} Omitted fields keep their stored value. The queue keeps its first 100 entries; a \`playbackId\` entry is stored in the legacy format, and an invalid or unknown one answers 400 \`INVALID_PLAYBACK_ID\` or 404 \`TRACK_NOT_FOUND\`.`,
        body: SavePlaybackStateRequest,
        responses: {
            200: PlaybackState,
            ...standardErrors,
            400: ApiError,
            404: ApiError,
        },
    }),
    defineOperation({
        method: "delete",
        path: "/api/playback-state",
        operationId: "clearPlaybackState",
        tag: "playback",
        summary: "Clear the stored playback state of this device",
        description: `${DEVICE_HEADER} The shared \`legacy\` state is cleared too.`,
        responses: { 200: ClearPlaybackStateResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/lyrics/{trackId}",
        operationId: "getLyrics",
        tag: "playback",
        summary: "Lyrics of a track",
        description:
            "Synced (LRC) or plain lyrics, from the cache, the file's embedded tags, or LRCLIB. For a library track the stored metadata drives the lookup; for any other path value the `artist`, `title`, `album` and `duration` parameters do, and without `artist` and `title` the answer is `source: none`. 504 when the lookup times out.",
        params: LyricsParams,
        query: LyricsQuery,
        responses: { 200: Lyrics, ...standardErrors, 504: ApiError },
    }),
];
