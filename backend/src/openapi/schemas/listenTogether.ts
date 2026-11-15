import { z } from "zod";
import { PlaybackMetadata } from "./play";

/** Kinds of group; only `host-follower` groups are created over REST. */
const ListenGroupType = z.enum(["host-follower", "collaborative"]);

/** Who can find a group through discovery. */
const ListenGroupVisibility = z.enum(["public", "private"]);

/**
 * One entry of a group's queue: display fields and, when one can be derived,
 * the opaque `playbackId` to stream it with.
 */
export const ListenQueueItem = z
    .object({
        id: z.string(),
        playbackId: z
            .string()
            .optional()
            .describe("Opaque track identifier. Do not parse."),
        title: z.string(),
        duration: z.number().int().describe("Seconds"),
        artist: z.object({ id: z.string(), name: z.string() }),
        album: z.object({
            id: z.string(),
            title: z.string(),
            coverArt: z.string().nullable(),
        }),
    })
    .meta({ id: "ListenQueueItem" });

/** A member of a group, host first, then in join order. */
export const ListenGroupMember = z
    .object({
        userId: z.string(),
        username: z.string(),
        isHost: z.boolean(),
        joinedAt: z.iso.datetime(),
        isConnected: z
            .boolean()
            .describe("Whether the member has a live socket connection."),
    })
    .meta({ id: "ListenGroupMember" });

/**
 * The group's shared playback. `positionMs` is the position at `serverTime`
 * (epoch milliseconds of the producing server); `trackId` is the id of the
 * queue item at `currentIndex`, `null` when the queue is empty.
 */
export const ListenGroupPlayback = z
    .object({
        queue: z.array(ListenQueueItem),
        currentIndex: z.number().int(),
        isPlaying: z.boolean(),
        positionMs: z.number(),
        serverTime: z.number().int(),
        stateVersion: z.number().int(),
        trackId: z.string().nullable(),
    })
    .meta({ id: "ListenGroupPlayback" });

/**
 * The full state of a group, as the REST operations answer it and the socket
 * broadcasts it. `readyDeadlineMs` (epoch milliseconds) is set only while
 * `syncState` is `waiting`.
 */
export const ListenGroupSnapshot = z
    .object({
        id: z.string(),
        name: z.string(),
        joinCode: z.string(),
        groupType: ListenGroupType,
        visibility: ListenGroupVisibility,
        isActive: z.boolean(),
        hostUserId: z.string(),
        membershipVersion: z.number().int().optional(),
        syncState: z.enum(["idle", "waiting", "playing", "paused"]),
        readyDeadlineMs: z.number().int().nullable().optional(),
        readyUserIds: z.array(z.string()).optional(),
        playback: ListenGroupPlayback,
        members: z.array(ListenGroupMember),
    })
    .meta({ id: "ListenGroupSnapshot" });

/** A public group as discovery lists it. */
export const ListenGroupSummary = z
    .object({
        id: z.string(),
        name: z.string(),
        joinCode: z.string(),
        groupType: ListenGroupType,
        visibility: ListenGroupVisibility,
        host: z.object({
            id: z.string(),
            username: z
                .string()
                .describe("The host's display name, or username without one."),
        }),
        memberCount: z.number().int(),
        isMember: z.boolean(),
        isPlaying: z.boolean(),
        currentTrack: z
            .object({
                id: z.string(),
                title: z.string(),
                artistName: z.string(),
            })
            .nullable(),
    })
    .meta({ id: "ListenGroupSummary" });

/** One initial queue entry of `POST /api/listen-together`. */
export const ListenQueueTrackInput = z
    .object({
        playbackId: z
            .string()
            .min(1)
            .describe("Opaque track identifier. Do not parse."),
        metadata: PlaybackMetadata.optional(),
    })
    .meta({ id: "ListenQueueTrackInput" });

/** Body of `POST /api/listen-together`. */
export const CreateListenGroupRequest = z
    .object({
        name: z.string().trim().min(1).max(80).optional(),
        visibility: ListenGroupVisibility.optional(),
        queueTrackIds: z
            .array(z.string().min(1))
            .optional()
            .describe("Library track ids of the initial queue."),
        queueTracks: z.array(ListenQueueTrackInput).optional(),
        currentTrackId: z.string().min(1).optional(),
        currentTimeMs: z.number().min(0).max(86_400_000).optional(),
        isPlaying: z.boolean().optional(),
    })
    .meta({ id: "CreateListenGroupRequest" });

/** Body of `POST /api/listen-together/join`. */
export const JoinListenGroupRequest = z
    .object({
        joinCode: z.string().min(1).max(64),
    })
    .meta({ id: "JoinListenGroupRequest" });

/** Path parameters of the per-group operations. */
export const ListenGroupIdParams = z.object({ groupId: z.string() });

/**
 * Answer of `POST /api/listen-together/{groupId}/leave`. `ended` is true when
 * the last member left; otherwise `newHostUserId` and `newHostUsername` name
 * the new host when the leaving member was the host.
 */
export const LeaveListenGroupResponse = z
    .object({
        success: z.boolean(),
        ended: z.boolean(),
        newHostUserId: z.string().optional(),
        newHostUsername: z.string().optional(),
    })
    .meta({ id: "LeaveListenGroupResponse" });

/** Answer of `POST /api/listen-together/{groupId}/end`. */
export const EndListenGroupResponse = z
    .object({ success: z.boolean() })
    .meta({ id: "EndListenGroupResponse" });
