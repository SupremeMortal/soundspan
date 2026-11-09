import { resolveCanonicalMediaSource } from "@soundspan/media-metadata-contract";
import { encodePlaybackId, type ParsedPlaybackId } from "./playbackId";

/** Source fields as stored on persisted queue items and listening projections. */
export interface StoredPlaybackItem {
    id?: unknown;
    mediaSource?: unknown;
    streamSource?: unknown;
    sourceType?: unknown;
    tidalTrackId?: unknown;
    youtubeVideoId?: unknown;
    provider?: unknown;
}

function asRecord(value: unknown): Record<string, unknown> | null {
    return value && typeof value === "object"
        ? (value as Record<string, unknown>)
        : null;
}

function asString(value: unknown): string | null {
    return typeof value === "string" && value.trim() ? value.trim() : null;
}

/**
 * Derives the `playbackId` of a stored track item from its source fields,
 * without any schema change. Returns `undefined` when the item lacks a usable
 * identity (so callers omit the field rather than emit a bad id).
 */
export function derivePlaybackIdFromStoredItem(
    item: StoredPlaybackItem,
): string | undefined {
    const provider = asRecord(item.provider);
    const tidalTrackId = provider?.tidalTrackId ?? item.tidalTrackId;
    const youtubeVideoId = asString(
        provider?.youtubeVideoId ?? item.youtubeVideoId,
    );
    const source = resolveCanonicalMediaSource({
        mediaSource: item.mediaSource ?? provider?.source,
        streamSource: item.streamSource,
        sourceType: item.sourceType,
        tidalTrackId,
        youtubeVideoId,
    });

    let ref: ParsedPlaybackId | null = null;
    if (source === "tidal") {
        const tidalId = Number(tidalTrackId);
        ref = { kind: "td", tidalId };
    } else if (source === "youtube" && youtubeVideoId) {
        ref = { kind: "ym", videoId: youtubeVideoId };
    } else if (source === "youtube-direct" && youtubeVideoId) {
        ref = { kind: "yt", videoId: youtubeVideoId };
    } else if (source === "local" || source === "peer") {
        const trackId = asString(item.id);
        if (trackId) ref = { kind: "t", trackId };
    }
    if (!ref) return undefined;
    try {
        return encodePlaybackId(ref);
    } catch {
        return undefined;
    }
}
