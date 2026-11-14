import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    AddPlaylistItemRequest,
    CreatePlaylistRequest,
    PlaylistDetail,
    PlaylistIdParams,
    PlaylistItem,
    PlaylistItemDuplicate,
    PlaylistItemParams,
    PlaylistListQuery,
    PlaylistRecord,
    PlaylistSummary,
    PlaylistWriteResult,
    ReorderPlaylistItemsRequest,
    UpdatePlaylistRequest,
} from "../schemas/playlist";

/** Errors of a write to a playlist the user must own. */
const ownedPlaylistErrors = {
    403: ApiError,
    404: ApiError,
    ...standardErrors,
} as const;

/** Playlist read and write operations. */
export const playlistOperations = [
    defineOperation({
        method: "get",
        path: "/api/playlists",
        operationId: "listPlaylists",
        tag: "playlists",
        summary: "The user's playlists and the public playlists of others",
        description:
            "Newest first, without hidden-station rows. `limit` defaults to 500 and is clamped to 1000; `offset` defaults to 0. `isHidden` marks playlists the user hid.",
        query: PlaylistListQuery,
        responses: { 200: z.array(PlaylistSummary), ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/playlists/{id}",
        operationId: "getPlaylist",
        tag: "playlists",
        summary: "A playlist with its items",
        description:
            "403 for another user's private playlist; 404 when there is none. The server also sends pending (not yet imported) items for other consumers.",
        params: z.object({ id: z.string() }),
        responses: {
            200: PlaylistDetail,
            403: ApiError,
            404: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "post",
        path: "/api/playlists",
        operationId: "createPlaylist",
        tag: "playlists",
        summary: "Create a playlist",
        description: "`isPublic` defaults to false.",
        body: CreatePlaylistRequest,
        responses: { 200: PlaylistRecord, 400: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "put",
        path: "/api/playlists/{id}",
        operationId: "updatePlaylist",
        tag: "playlists",
        summary: "Rename a playlist or change its visibility",
        description:
            "Omitted fields keep their value. 403 for a playlist the user does not own.",
        params: PlaylistIdParams,
        body: UpdatePlaylistRequest,
        responses: {
            200: PlaylistRecord,
            400: ApiError,
            ...ownedPlaylistErrors,
        },
    }),
    defineOperation({
        method: "delete",
        path: "/api/playlists/{id}",
        operationId: "deletePlaylist",
        tag: "playlists",
        summary: "Delete a playlist",
        description: "403 for a playlist the user does not own.",
        params: PlaylistIdParams,
        responses: { 200: PlaylistWriteResult, ...ownedPlaylistErrors },
    }),
    defineOperation({
        method: "post",
        path: "/api/playlists/{id}/items",
        operationId: "addPlaylistItem",
        tag: "playlists",
        summary: "Add a track to the end of a playlist",
        description:
            "Answers the new item, or `duplicated: true` with the existing item when the track is already in the playlist. `metadata` is required (400 `METADATA_REQUIRED`) only when a TIDAL or YouTube Music track row must be created. 400 `INVALID_PLAYBACK_ID`, 404 `TRACK_NOT_FOUND`, 409 `SOURCE_UNAVAILABLE`; 403 for a playlist the user does not own. Legacy identifier fields (`trackId`, `tidalTrackId`, `youtubeVideoId` with display fields) exist for other consumers; a `playbackId` wins over them.",
        params: PlaylistIdParams,
        body: AddPlaylistItemRequest,
        responses: {
            200: z.union([PlaylistItem, PlaylistItemDuplicate]),
            400: ApiError,
            409: ApiError,
            ...ownedPlaylistErrors,
        },
    }),
    defineOperation({
        method: "delete",
        path: "/api/playlists/{id}/items/{playbackId}",
        operationId: "removePlaylistItem",
        tag: "playlists",
        summary: "Remove a track from a playlist",
        description:
            "404 when the playlist does not exist or holds no item for the track; 403 for a playlist the user does not own.",
        params: PlaylistItemParams,
        responses: { 200: PlaylistWriteResult, ...ownedPlaylistErrors },
    }),
    defineOperation({
        method: "put",
        path: "/api/playlists/{id}/items/reorder",
        operationId: "reorderPlaylistItems",
        tag: "playlists",
        summary: "Put the items of a playlist in a new order",
        description:
            "`playbackIds` must list every item of the playlist exactly once (400 otherwise). 400 `INVALID_PLAYBACK_ID` for an unparseable id, 404 `TRACK_NOT_FOUND` for one not in the playlist; 403 for a playlist the user does not own. `itemIds` and `trackIds` forms exist for other consumers; `playbackIds` wins over them.",
        params: PlaylistIdParams,
        body: ReorderPlaylistItemsRequest,
        responses: {
            200: PlaylistWriteResult,
            400: ApiError,
            ...ownedPlaylistErrors,
        },
    }),
];
