import type { Prisma } from "@prisma/client";
import { z } from "zod";
import { PLAYLIST_REORDER_MAX_ITEMS } from "./playlistMutationLock";
import { parsePlaybackId } from "./playback/playbackId";

export type ReorderSelection =
    | { success: true; ids: string[]; byItemId: boolean }
    | { success: false; message: string };

type UnvalidatedReorderSelection =
    | { success: true; ids: unknown[]; byItemId: boolean }
    | { success: false; message: string };

export type ReorderPlaylistItem = {
    id: string;
    trackId: string | null;
};

const reorderPayloadSchema = z.object({
    playbackIds: z.unknown().optional(),
    itemIds: z.unknown().optional(),
    trackIds: z.unknown().optional(),
});

const reorderIdsSchema = z.array(z.string().min(1));

function getReorderSelection(body: unknown): UnvalidatedReorderSelection {
    const parsedPayload = reorderPayloadSchema.safeParse(body);
    const payload = parsedPayload.success ? parsedPayload.data : {};
    const { playbackIds, itemIds, trackIds } = payload;
    if (playbackIds !== undefined && !Array.isArray(playbackIds)) {
        return { success: false, message: "playbackIds must be an array" };
    }
    if (Array.isArray(playbackIds)) {
        // playbackIds win; they are translated to item ids by the route.
        return { success: true, ids: playbackIds, byItemId: true };
    }
    if (itemIds !== undefined && !Array.isArray(itemIds)) {
        return { success: false, message: "itemIds must be an array" };
    }
    if (trackIds !== undefined && !Array.isArray(trackIds)) {
        return { success: false, message: "trackIds must be an array" };
    }

    const byItemId = Array.isArray(itemIds);
    const selected = byItemId ? itemIds : trackIds;
    if (!Array.isArray(selected)) {
        return {
            success: false,
            message: "playbackIds, itemIds or trackIds must be an array",
        };
    }
    return { success: true, ids: selected, byItemId };
}

function validateReorderIds(
    selection: Extract<UnvalidatedReorderSelection, { success: true }>,
): ReorderSelection {
    if (selection.ids.length > PLAYLIST_REORDER_MAX_ITEMS) {
        return {
            success: false,
            message: `A playlist reorder cannot exceed ${PLAYLIST_REORDER_MAX_ITEMS} items`,
        };
    }
    const parsedIds = reorderIdsSchema.safeParse(selection.ids);
    if (!parsedIds.success) {
        return {
            success: false,
            message: "Reorder identifiers must be non-empty strings",
        };
    }

    const ids = parsedIds.data;
    if (new Set(ids).size !== ids.length) {
        return {
            success: false,
            message: "Reorder identifiers must not contain duplicates",
        };
    }
    return { success: true, ids, byItemId: selection.byItemId };
}

export function selectReorderIds(body: unknown): ReorderSelection {
    const selection = getReorderSelection(body);
    return selection.success ? validateReorderIds(selection) : selection;
}

function getExpectedReorderIds(
    byItemId: boolean,
    playlistItems: ReorderPlaylistItem[],
): string[] {
    if (byItemId) return playlistItems.map((item) => item.id);
    return playlistItems
        .map((item) => item.trackId)
        .filter((trackId): trackId is string => trackId !== null);
}

export function validateExactReorder(
    selection: Extract<ReorderSelection, { success: true }>,
    playlistItems: ReorderPlaylistItem[],
): { status: 400 | 404; message: string } | null {
    if (playlistItems.length > PLAYLIST_REORDER_MAX_ITEMS) {
        return {
            status: 400,
            message: `Playlist exceeds the maximum reorder size of ${PLAYLIST_REORDER_MAX_ITEMS} items`,
        };
    }

    const expectedIds = getExpectedReorderIds(
        selection.byItemId,
        playlistItems,
    );
    const expectedIdSet = new Set(expectedIds);
    if (selection.ids.some((id) => !expectedIdSet.has(id))) {
        return {
            status: 404,
            message: selection.byItemId
                ? "One or more playlist items were not found in this playlist"
                : "One or more tracks were not found in this playlist",
        };
    }
    if (
        selection.ids.length !== playlistItems.length ||
        expectedIds.length !== playlistItems.length
    ) {
        return {
            status: 400,
            message:
                "Reorder identifiers must include every playlist item exactly once",
        };
    }
    return null;
}

export type PlaybackReorderItem = {
    id: string;
    trackId: string | null;
    trackTidal: { tidalId: number } | null;
    trackYtMusic: { videoId: string } | null;
};

export function getPlaylistItemPlaybackId(
    item: PlaybackReorderItem,
): string | null {
    if (item.trackId) return `t.${item.trackId}`;
    if (item.trackTidal) return `td.${item.trackTidal.tidalId}`;
    if (item.trackYtMusic) return `ym.${item.trackYtMusic.videoId}`;
    return null;
}

/** Matches a playlist item by the track it holds, from a parsed playbackId. */
export function getPlaybackIdItemWhere(
    playlistId: string,
    playbackId: string,
): Prisma.PlaylistItemWhereInput | null {
    const parsed = parsePlaybackId(playbackId);
    if (!parsed) return null;
    switch (parsed.kind) {
        case "t":
            return { playlistId, trackId: parsed.trackId };
        case "td":
            return { playlistId, trackTidal: { tidalId: parsed.tidalId } };
        case "ym":
            return { playlistId, trackYtMusic: { videoId: parsed.videoId } };
        default:
            return null;
    }
}

/**
 * Maps `playbackId`s to the ids of the playlist items holding those tracks,
 * in the given order. Returns `null` when any playbackId is not in the playlist.
 */
export function translatePlaybackIdsToItemIds(
    playbackIds: readonly string[],
    items: readonly PlaybackReorderItem[],
): string[] | null {
    const itemIdByPlaybackId = new Map<string, string>();
    for (const item of items) {
        const playbackId = getPlaylistItemPlaybackId(item);
        if (playbackId) itemIdByPlaybackId.set(playbackId, item.id);
    }
    const ids: string[] = [];
    for (const playbackId of playbackIds) {
        const id = itemIdByPlaybackId.get(playbackId);
        if (id === undefined) return null;
        ids.push(id);
    }
    return ids;
}
