import type { Request, Response } from "express";
import { prisma } from "../../utils/db";
import {
    TRACK_VISIBLE_WHERE,
    trackBrowseWhere,
} from "../../utils/librarySorting";
import {
    buildAlbumDetailWhere,
    buildRemoteAlbumTrackWheres,
    findAlbumWithTracks,
    formatAlbumTracks,
} from "../albumDetailTracks";
import { encodePlaybackId, parsePlaybackId } from "../playback/playbackId";
import { getPlaybackStreamInfo } from "../playback/playbackStreamInfo";
import {
    PlaybackResolutionError,
    resolvePlayback,
    type PlaybackQuality,
} from "../playback/resolvePlayback";
import { resolveDownloadQuality } from "./resolveDownloadQuality";
import { resolveOfflinePolicy, type OfflineBlockReason } from "./offlinePolicy";

/** What an offline request names: one track, or every track of an album or playlist. */
export type OfflineItemKind = "track" | "album" | "playlist";

/** One entry of the `POST /api/offline/items` response. */
export type OfflineItem =
    | {
          playbackId: string;
          downloadable: true;
          downloadUrl: string;
          /** Bytes the stream serves; null when the source cannot say. */
          expectedSize: number | null;
          quality: PlaybackQuality;
          contentType: string | null;
      }
    | {
          playbackId: string;
          downloadable: false;
          reason: OfflineBlockReason;
      };

/** The resolved items and the summed size of the downloadable ones. */
export interface ResolvedOfflineItems {
    items: OfflineItem[];
    /** Sum of `expectedSize` over downloadable items that report one. */
    estimatedTotalBytes: number;
}

/** Input for {@link resolveOfflineItems}. */
export interface ResolveOfflineItemsInput {
    userId: string;
    kind: OfflineItemKind;
    /** A `playbackId` for `track`; the album or playlist id otherwise. */
    id: string;
    quality?: PlaybackQuality;
}

/** Why a request could not be resolved; routes turn it into a response. */
export type OfflineItemsErrorCode =
    | "INVALID_PLAYBACK_ID"
    | "ALBUM_NOT_FOUND"
    | "PLAYLIST_NOT_FOUND";

/** Thrown by {@link resolveOfflineItems} when the request itself is unusable. */
export class OfflineItemsError extends Error {
    constructor(
        readonly status: 400 | 404,
        readonly code: OfflineItemsErrorCode,
        message: string,
    ) {
        super(message);
        this.name = "OfflineItemsError";
    }
}

/** Stream-info lookups running at once while resolving a large album. */
const RESOLVE_CONCURRENCY = 4;

type StreamInfoBody = {
    contentType?: unknown;
    contentLength?: unknown;
    quality?: unknown;
};

/**
 * A minimal `Response` that records what a stream-info service writes, so the
 * unified stream-info service can be reused without an HTTP exchange.
 */
function createCapture() {
    const captured: { status: number; body: unknown } = {
        status: 200,
        body: undefined,
    };
    const res = {
        statusCode: 200,
        headersSent: false,
        status(code: number) {
            captured.status = code;
            res.statusCode = code;
            return res;
        },
        json(body: unknown) {
            captured.body = body;
            res.headersSent = true;
            return res;
        },
        setHeader: () => res,
        header: () => res,
        on: () => res,
        once: () => res,
        end: () => res,
    };
    return { captured, res: res as unknown as Response };
}

function blocked(playbackId: string, reason: OfflineBlockReason): OfflineItem {
    return { playbackId, downloadable: false, reason };
}

function sizeOrNull(value: unknown): number | null {
    return typeof value === "number" && Number.isFinite(value) && value >= 0
        ? value
        : null;
}

async function resolveItem(
    userId: string,
    playbackId: string,
    requested: PlaybackQuality | undefined,
): Promise<OfflineItem> {
    const parsed = parsePlaybackId(playbackId);
    if (!parsed) return blocked(playbackId, "TRACK_UNAVAILABLE");

    // Only library tracks are offline-downloadable; remote sources keep
    // streaming through /api/playback/stream.
    if (parsed.kind !== "t") return blocked(playbackId, "SOURCE_UNAVAILABLE");

    const policy = await resolveOfflinePolicy(userId, parsed);
    if (!policy.downloadable) return blocked(playbackId, policy.reason);

    let playback;
    try {
        playback = await resolvePlayback(userId, {
            parsed,
            quality: requested,
        });
    } catch (err: unknown) {
        if (err instanceof PlaybackResolutionError) {
            return blocked(
                playbackId,
                err.code === "TRACK_NOT_FOUND"
                    ? "TRACK_UNAVAILABLE"
                    : "SOURCE_UNAVAILABLE",
            );
        }
        throw err;
    }

    const { captured, res } = createCapture();
    const req = { headers: {}, query: {} } as unknown as Request;
    await getPlaybackStreamInfo({ playback, playbackId, userId, req, res });
    if (captured.status >= 400 || !captured.body) {
        return blocked(
            playbackId,
            captured.status === 404
                ? "TRACK_UNAVAILABLE"
                : "SOURCE_UNAVAILABLE",
        );
    }

    const info = captured.body as StreamInfoBody;
    const { quality } = resolveDownloadQuality(
        parsed,
        (info.quality as PlaybackQuality) ?? playback.libraryQuality,
        {},
    );
    return {
        playbackId,
        downloadable: true,
        downloadUrl: `/api/playback/stream/${playbackId}?quality=${quality}`,
        expectedSize: sizeOrNull(info.contentLength),
        quality,
        contentType:
            typeof info.contentType === "string" ? info.contentType : null,
    };
}

async function albumPlaybackIds(
    userId: string,
    albumId: string,
): Promise<string[]> {
    const browseTrackWhere = {
        ...TRACK_VISIBLE_WHERE,
        ...trackBrowseWhere("all"),
    };
    const remote = buildRemoteAlbumTrackWheres(userId);
    const album = await findAlbumWithTracks(
        buildAlbumDetailWhere(
            albumId,
            browseTrackWhere,
            remote.likedTidal,
            remote.likedYt,
        ),
        browseTrackWhere,
        remote.includedTidal,
        remote.includedYt,
    );
    if (!album) {
        throw new OfflineItemsError(404, "ALBUM_NOT_FOUND", "Album not found");
    }
    return formatAlbumTracks(album).map((track) => track.playbackId);
}

async function playlistPlaybackIds(
    userId: string,
    playlistId: string,
): Promise<string[]> {
    const playlist = await prisma.playlist.findUnique({
        where: { id: playlistId },
        select: {
            userId: true,
            isPublic: true,
            items: {
                // Same visibility rule as the playlist list previews.
                where: {
                    OR: [{ trackId: null }, { track: TRACK_VISIBLE_WHERE }],
                },
                orderBy: { sort: "asc" },
                select: {
                    trackId: true,
                    trackTidal: { select: { tidalId: true } },
                    trackYtMusic: { select: { videoId: true } },
                },
            },
        },
    });
    // A private playlist of another user is reported as missing so its
    // existence is not disclosed.
    if (!playlist || (!playlist.isPublic && playlist.userId !== userId)) {
        throw new OfflineItemsError(
            404,
            "PLAYLIST_NOT_FOUND",
            "Playlist not found",
        );
    }
    const ids: string[] = [];
    for (const item of playlist.items) {
        if (item.trackId) {
            ids.push(encodePlaybackId({ kind: "t", trackId: item.trackId }));
        } else if (item.trackTidal) {
            ids.push(
                encodePlaybackId({
                    kind: "td",
                    tidalId: item.trackTidal.tidalId,
                }),
            );
        } else if (item.trackYtMusic) {
            ids.push(
                encodePlaybackId({
                    kind: "ym",
                    videoId: item.trackYtMusic.videoId,
                }),
            );
        }
    }
    return ids;
}

async function mapWithLimit<T, R>(
    values: T[],
    limit: number,
    fn: (value: T) => Promise<R>,
): Promise<R[]> {
    const results: R[] = new Array(values.length);
    let next = 0;
    const workers = Array.from(
        { length: Math.min(limit, values.length) },
        async () => {
            while (next < values.length) {
                const index = next++;
                results[index] = await fn(values[index]);
            }
        },
    );
    await Promise.all(workers);
    return results;
}

/**
 * Turns an offline download request into the `items` of `POST /api/offline/items`:
 * every visible track of the album or playlist (any source, in order), each
 * either downloadable with its stream URL and size or blocked with a reason.
 */
export async function resolveOfflineItems(
    input: ResolveOfflineItemsInput,
): Promise<ResolvedOfflineItems> {
    const { userId, kind, id, quality } = input;
    let playbackIds: string[];
    if (kind === "track") {
        if (!parsePlaybackId(id)) {
            throw new OfflineItemsError(
                400,
                "INVALID_PLAYBACK_ID",
                "Invalid playbackId",
            );
        }
        playbackIds = [id];
    } else if (kind === "album") {
        playbackIds = await albumPlaybackIds(userId, id);
    } else {
        playbackIds = await playlistPlaybackIds(userId, id);
    }

    const items = await mapWithLimit(playbackIds, RESOLVE_CONCURRENCY, (pid) =>
        resolveItem(userId, pid, quality),
    );
    const estimatedTotalBytes = items.reduce(
        (sum, item) =>
            item.downloadable ? sum + (item.expectedSize ?? 0) : sum,
        0,
    );
    return { items, estimatedTotalBytes };
}
