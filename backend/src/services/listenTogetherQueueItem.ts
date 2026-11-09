/**
 * Shared queue-item shape for Listen Together group state.
 *
 * Extracted from listenTogetherManager.ts and exposed through the dedicated
 * Listen Together type home.
 */

import type {
    CanonicalMediaProviderIdentity,
    CanonicalMediaSource,
    RemoteMediaSource,
    ResolvedMediaSource,
} from "@soundspan/media-metadata-contract";
import { tryEncodePlaybackId } from "./playback/playbackId";

export interface SyncQueueItem {
    id: string;
    /** Opaque unified playback identifier, derived when the item is serialized. */
    playbackId?: string;
    title: string;
    duration: number;
    loudnessLufs?: number | null;
    truePeakDb?: number | null;
    artist: { id: string; name: string };
    album: {
        id: string;
        title: string;
        coverArt: string | null;
        albumLoudnessLufs?: number | null;
        albumTruePeakDb?: number | null;
    };
    mediaSource?: CanonicalMediaSource;
    provider?: CanonicalMediaProviderIdentity;
    streamSource?: RemoteMediaSource;
    tidalTrackId?: number;
    youtubeVideoId?: string;
    /** Audio container hint for "youtube-direct" streams (webm for opus, mp4 for AAC). */
    youtubeAudioFormat?: "mp4" | "webm";
    localTrackId?: string;
    trackTidalId?: string;
    trackYtMusicId?: string;
    trackMappingId?: string;
    originSource?: ResolvedMediaSource;
    /** Current owning-peer reachability captured when the queue item was built. */
    peerOnline?: boolean;
}

/**
 * Derive the unified `playbackId` for a stored queue item from its stream
 * source and provider ids. Items persisted before `playbackId` existed get one
 * too, so no data migration is needed. Returns the item unchanged (without the
 * field) when no valid id can be derived.
 */
export function withQueueItemPlaybackId(item: SyncQueueItem): SyncQueueItem {
    const { playbackId: _stored, ...rest } = item;
    const source = item.streamSource;
    let playbackId: string | undefined;
    if (source === "tidal") {
        const tidalId = item.tidalTrackId ?? item.provider?.tidalTrackId;
        if (tidalId !== undefined) {
            playbackId = tryEncodePlaybackId({ kind: "td", tidalId });
        }
    } else if (source === "youtube" || source === "youtube-direct") {
        const videoId = item.youtubeVideoId ?? item.provider?.youtubeVideoId;
        if (videoId) {
            playbackId = tryEncodePlaybackId({
                kind: source === "youtube" ? "ym" : "yt",
                videoId,
            });
        }
    } else {
        playbackId = tryEncodePlaybackId({
            kind: "t",
            trackId: item.localTrackId ?? item.id,
        });
    }
    return playbackId ? { ...rest, playbackId } : rest;
}
