import { z } from "zod";
import { ApiError } from "./common";

/** Quality of an offline file; the stream qualities a download can ask for. */
export const OfflineQuality = z.enum(["original", "high", "medium", "low"]);

/** Body of `POST /api/offline/items`. */
export const RequestOfflineItemsRequest = z
    .object({
        kind: z.enum(["track", "album", "playlist"]),
        id: z.string().min(1).max(256),
        deviceId: z.string().uuid(),
        quality: OfflineQuality.optional(),
    })
    .meta({ id: "RequestOfflineItemsRequest" });

/**
 * Body of `POST /api/offline/items/complete`. The route parses `playbackId`
 * further and answers 400 `INVALID_REQUEST` for an id that is not a valid
 * `playbackId`.
 */
export const CompleteOfflineItemRequest = z
    .object({
        deviceId: z.string().uuid(),
        playbackId: z.string(),
        quality: OfflineQuality,
        sizeBytes: z
            .number()
            .int()
            .positive()
            .max(4096 * 1024 * 1024),
    })
    .meta({ id: "CompleteOfflineItemRequest" });

/** Body of `DELETE /api/offline/items`. */
export const DeleteOfflineItemsRequest = z
    .object({
        deviceId: z.string().uuid(),
        playbackIds: z.array(z.string().min(1).max(256)).max(500),
    })
    .meta({ id: "DeleteOfflineItemsRequest" });

/** Query of `GET /api/offline/items`. */
export const OfflineDeviceQuery = z.object({ deviceId: z.string().uuid() });

/** Query of `GET /api/offline/stats`. */
export const OfflineStatsQuery = z.object({
    deviceId: z
        .string()
        .uuid()
        .optional()
        .describe("Adds the `device` totals of this device to the answer."),
});

/**
 * One track of an offline request. A downloadable item
 * (`downloadable: true`) carries `downloadUrl`, `expectedSize`, `quality` and
 * `contentType`; a blocked item (`downloadable: false`) carries `reason`.
 */
export const OfflineItem = z
    .object({
        playbackId: z.string(),
        downloadable: z.boolean(),
        downloadUrl: z
            .string()
            .optional()
            .describe(
                "Relative stream URL of the file. It carries `report=0`, so the download records no play.",
            ),
        expectedSize: z
            .number()
            .int()
            .nullable()
            .optional()
            .describe(
                "Bytes the stream serves; null when the source cannot say.",
            ),
        quality: OfflineQuality.optional(),
        contentType: z.string().nullable().optional(),
        reason: z
            .enum([
                "SOURCE_DOWNLOADS_DISABLED",
                "TRACK_UNAVAILABLE",
                "SOURCE_UNAVAILABLE",
            ])
            .optional()
            .describe(
                "SOURCE_DOWNLOADS_DISABLED when an admin turned offline downloads off; SOURCE_UNAVAILABLE when the track's source cannot be streamed by this user; TRACK_UNAVAILABLE when the track no longer exists.",
            ),
    })
    .meta({ id: "OfflineItem" });

/** The answer of `POST /api/offline/items`. */
export const OfflineItemsResponse = z
    .object({
        items: z.array(OfflineItem),
        estimatedTotalBytes: z.number().int(),
        cacheLimitBytes: z.number().int(),
        cacheUsedBytes: z.number().int(),
    })
    .meta({ id: "OfflineItemsResponse" });

/** The 409 of `POST /api/offline/items` (`code` `CACHE_LIMIT_EXCEEDED`). */
export const CacheLimitExceededError = ApiError.extend({
    cacheLimitBytes: z.number().int(),
    cacheUsedBytes: z.number().int(),
    estimatedTotalBytes: z.number().int(),
}).meta({ id: "CacheLimitExceededError" });

/** The completed item as recorded. */
export const CompletedOfflineItem = z
    .object({
        playbackId: z.string(),
        quality: OfflineQuality,
        sizeBytes: z.number().int(),
    })
    .meta({ id: "CompletedOfflineItem" });

/** The answer of `DELETE /api/offline/items`. */
export const DeleteOfflineItemsResponse = z
    .object({ deletedCount: z.number().int() })
    .meta({ id: "DeleteOfflineItemsResponse" });

/** One file the server believes a device holds. */
export const DeviceOfflineItem = z
    .object({
        playbackId: z.string(),
        quality: OfflineQuality,
        sizeBytes: z.number().int(),
        revoked: z
            .boolean()
            .describe(
                "True when an admin turned offline downloads off or the track no longer exists; the client removes the file.",
            ),
    })
    .meta({ id: "DeviceOfflineItem" });

/** The answer of `GET /api/offline/items`. */
export const DeviceOfflineItemsResponse = z
    .object({ items: z.array(DeviceOfflineItem) })
    .meta({ id: "DeviceOfflineItemsResponse" });

/** Offline cache usage; the top-level numbers cover every device. */
export const OfflineStats = z
    .object({
        usedMb: z.number(),
        maxMb: z.number().int(),
        availableMb: z.number(),
        percentUsed: z.number(),
        trackCount: z.number().int(),
        device: z
            .object({
                deviceId: z.string(),
                usedMb: z.number(),
                trackCount: z.number().int(),
            })
            .optional()
            .describe(
                "Totals of the requested device; present only with `deviceId`.",
            ),
    })
    .meta({ id: "OfflineStats" });
