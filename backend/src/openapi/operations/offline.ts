import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    CacheLimitExceededError,
    CompletedOfflineItem,
    CompleteOfflineItemRequest,
    DeleteOfflineItemsRequest,
    DeleteOfflineItemsResponse,
    DeviceOfflineItemsResponse,
    OfflineDeviceQuery,
    OfflineItemsResponse,
    OfflineStats,
    OfflineStatsQuery,
    RequestOfflineItemsRequest,
} from "../schemas/offline";

/** Source-agnostic offline download operations, keyed by device. */
export const offlineOperations = [
    defineOperation({
        method: "post",
        path: "/api/offline/items",
        operationId: "requestOfflineItems",
        tag: "offline",
        summary: "Request offline downloads for a track, album, or playlist",
        description:
            "Resolves the request to downloadable items or blocked items with a reason. `id` is a playbackId for `track` and the album or playlist id otherwise; albums and playlists include every visible track in order. Records no cached file; `completeOfflineItem` does. Errors carry `code` `INVALID_REQUEST` or `INVALID_PLAYBACK_ID` (400), `ALBUM_NOT_FOUND` or `PLAYLIST_NOT_FOUND` (404), and `CACHE_LIMIT_EXCEEDED` (409) when the used bytes of every device plus the estimate exceed the limit.",
        body: RequestOfflineItemsRequest,
        responses: {
            200: OfflineItemsResponse,
            ...standardErrors,
            400: ApiError,
            404: ApiError,
            409: CacheLimitExceededError,
        },
    }),
    defineOperation({
        method: "post",
        path: "/api/offline/items/complete",
        operationId: "completeOfflineItem",
        tag: "offline",
        summary: "Record that a device finished writing an offline file",
        description:
            "Upserts the device's cached-item row for the playbackId and quality; calling it again updates the recorded size. Errors carry `code` `INVALID_REQUEST` (400, including a `playbackId` that is not valid) or `TRACK_UNAVAILABLE` (404, the library track no longer exists).",
        body: CompleteOfflineItemRequest,
        responses: {
            200: CompletedOfflineItem,
            ...standardErrors,
            400: ApiError,
            404: ApiError,
        },
    }),
    defineOperation({
        method: "delete",
        path: "/api/offline/items",
        operationId: "deleteOfflineItems",
        tag: "offline",
        summary: "Remove a device's offline items",
        description:
            "Unknown ids are ignored. Errors carry `code` `INVALID_REQUEST` (400).",
        body: DeleteOfflineItemsRequest,
        responses: {
            200: DeleteOfflineItemsResponse,
            ...standardErrors,
            400: ApiError,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/offline/items",
        operationId: "listOfflineItems",
        tag: "offline",
        summary: "List what the server believes a device holds",
        description:
            "Used to reconcile after a reinstall. Errors carry `code` `INVALID_REQUEST` (400).",
        query: OfflineDeviceQuery,
        responses: {
            200: DeviceOfflineItemsResponse,
            ...standardErrors,
            400: ApiError,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/offline/stats",
        operationId: "getOfflineStats",
        tag: "offline",
        summary: "Get offline cache usage statistics",
        description:
            "The top-level numbers always cover every device; with `deviceId` the answer also carries `device`. Errors carry `code` `INVALID_REQUEST` (400) for a `deviceId` that is not a UUID.",
        query: OfflineStatsQuery,
        responses: {
            200: OfflineStats,
            ...standardErrors,
            400: ApiError,
        },
    }),
];
