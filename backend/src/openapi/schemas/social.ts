import { z } from "zod";

/** Answer of `POST /api/social/presence/heartbeat`. */
export const PresenceHeartbeatResponse = z
    .object({
        success: z.boolean(),
        ttlSeconds: z
            .number()
            .int()
            .describe(
                "Seconds until the presence expires without a heartbeat.",
            ),
    })
    .meta({ id: "PresenceHeartbeatResponse" });

/**
 * The track an online user is listening to. `artistId` and `albumId` are
 * `null` when the queue entry carries no id; `playbackId` is absent when none
 * can be derived.
 */
export const OnlineUserTrack = z
    .object({
        id: z.string(),
        playbackId: z
            .string()
            .optional()
            .describe("Opaque track identifier. Do not parse."),
        title: z.string(),
        duration: z.number().describe("Seconds"),
        artistName: z.string(),
        artistId: z.string().nullable(),
        albumTitle: z.string(),
        albumId: z.string().nullable(),
        coverArt: z.string().nullable(),
    })
    .meta({ id: "OnlineUserTrack" });

/**
 * A user who is online and shares their presence. `listeningTrack` is `null`
 * unless the user shares their listening status and is playing a track the
 * server can show.
 */
export const OnlineUser = z
    .object({
        id: z.string(),
        username: z.string(),
        displayName: z.string(),
        hasProfilePicture: z.boolean(),
        isInListenTogetherGroup: z.boolean(),
        listeningStatus: z.enum(["playing", "paused", "idle"]),
        listeningTrack: OnlineUserTrack.nullable(),
        lastHeartbeatAt: z.iso.datetime(),
    })
    .meta({ id: "OnlineUser" });

/** Answer of `GET /api/social/online`, sorted by `displayName`. */
export const OnlineUsersResponse = z
    .object({ users: z.array(OnlineUser) })
    .meta({ id: "OnlineUsersResponse" });
