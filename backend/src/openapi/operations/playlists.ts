import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    PlaylistDetail,
    PlaylistListQuery,
    PlaylistSummary,
} from "../schemas/playlist";

/** Playlist read operations. */
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
];
