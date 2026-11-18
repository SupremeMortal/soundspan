import { z } from "zod";
import { PlaybackMetadata } from "./play";
import { LibraryTrack } from "./track";

/** The user who owns a playlist. */
export const PlaylistOwner = z
    .object({ username: z.string() })
    .meta({ id: "PlaylistOwner" });

/** Fields every playlist carries, in the list and in detail. */
const playlistFields = {
    id: z.string(),
    userId: z.string(),
    name: z.string(),
    isPublic: z.boolean(),
    createdAt: z.iso.datetime(),
    updatedAt: z.iso.datetime(),
    user: PlaylistOwner,
    isOwner: z.boolean(),
    isHidden: z.boolean(),
    trackCount: z.number().int(),
    unplayableCount: z.number().int().optional(),
};

/** The album cover of a playlist list cover seed. */
export const PlaylistCoverAlbum = z
    .object({ coverArt: z.string().nullable() })
    .meta({ id: "PlaylistCoverAlbum" });

/**
 * One of the first items of a playlist, used to build its cover; `track` is
 * null for an item that is not a library track.
 */
export const PlaylistCoverItem = z
    .object({
        id: z.string(),
        track: z.object({ album: PlaylistCoverAlbum }).nullable(),
    })
    .meta({ id: "PlaylistCoverItem" });

/**
 * A playlist in the list. `unplayableCount` (removed library tracks) is
 * omitted when zero; `items` holds at most 12 cover seeds.
 */
export const PlaylistSummary = z
    .object({
        ...playlistFields,
        items: z.array(PlaylistCoverItem),
    })
    .meta({ id: "PlaylistSummary" });

/**
 * Whether a playlist item can be played. `reason` and `message` are null when
 * it can; otherwise `reason` is a machine-readable code (for example
 * `track_removed`, `peer_offline`, `provider_unavailable`). Clients must
 * tolerate codes added later.
 */
export const PlaylistItemPlayback = z
    .object({
        isPlayable: z.boolean(),
        reason: z.string().nullable(),
        message: z.string().nullable(),
    })
    .meta({ id: "PlaylistItemPlayback" });

/**
 * A track item of a playlist. `track` is null when the item no longer has a
 * track source.
 */
export const PlaylistItem = z
    .object({
        id: z.string(),
        playlistId: z.string(),
        sort: z.number().int(),
        type: z.enum(["track"]),
        track: LibraryTrack.nullable(),
        playback: PlaylistItemPlayback,
    })
    .meta({ id: "PlaylistItem" });

/**
 * A playlist with its track items in playlist order. At most 1000 track and
 * pending items are returned together; `truncated` is true when the playlist
 * holds more (`totalItemCount`).
 */
export const PlaylistDetail = z
    .object({
        ...playlistFields,
        pendingCount: z.number().int(),
        totalItemCount: z.number().int(),
        truncated: z.boolean(),
        items: z.array(PlaylistItem),
    })
    .meta({ id: "PlaylistDetail" });

/** Query of `GET /api/playlists`. */
export const PlaylistListQuery = z.object({
    limit: z.number().int().optional(),
    offset: z.number().int().optional(),
});

/** Body of `POST /api/playlists`. */
export const CreatePlaylistRequest = z
    .object({
        name: z.string().min(1).max(200),
        isPublic: z.boolean().optional().default(false),
    })
    .meta({ id: "CreatePlaylistRequest" });

/** Body of `PUT /api/playlists/{id}`; omitted fields keep their value. */
export const UpdatePlaylistRequest = z
    .object({
        name: z.string().min(1).max(200).optional(),
        isPublic: z.boolean().optional(),
    })
    .meta({ id: "UpdatePlaylistRequest" });

/** Path parameter of the single-playlist operations. */
export const PlaylistIdParams = z.object({
    id: z.string().describe("Playlist id"),
});

/** Path parameters of `DELETE /api/playlists/{id}/items/{playbackId}`. */
export const PlaylistItemParams = z.object({
    id: z.string().describe("Playlist id"),
    playbackId: z
        .string()
        .describe(
            "Opaque track identifier of the item to remove. A playlist item id, or a library track id, is also accepted for other consumers.",
        ),
});

/**
 * A playlist row as stored, the answer of the create and update operations.
 * It carries no owner, items or counts.
 */
export const PlaylistRecord = z
    .object({
        id: z.string(),
        userId: z.string(),
        name: z.string(),
        isPublic: z.boolean(),
        mixId: z.string().nullable(),
        spotifyPlaylistId: z.string().nullable(),
        spotifyPlaylistUrl: z.string().nullable(),
        createdAt: z.iso.datetime(),
        updatedAt: z.iso.datetime(),
    })
    .meta({ id: "PlaylistRecord" });

/** Body of `POST /api/playlists/{id}/items`. */
export const AddPlaylistItemRequest = z
    .object({
        playbackId: z
            .string()
            .min(1)
            .describe("Opaque track identifier. Do not parse."),
        metadata: PlaybackMetadata.optional(),
    })
    .meta({ id: "AddPlaylistItemRequest" });

/** The answer when the track is already in the playlist; nothing is added. */
export const PlaylistItemDuplicate = z
    .object({
        message: z.string(),
        duplicated: z.literal(true),
        item: PlaylistItem,
    })
    .meta({ id: "PlaylistItemDuplicate" });

/** Body of `PUT /api/playlists/{id}/items/reorder`. */
export const ReorderPlaylistItemsRequest = z
    .object({
        playbackIds: z
            .array(z.string())
            .max(1000)
            .describe(
                "The playbackId of every item of the playlist, in the new order.",
            ),
    })
    .meta({ id: "ReorderPlaylistItemsRequest" });

/** The answer of a playlist write that returns no data. */
export const PlaylistWriteResult = z
    .object({ message: z.string() })
    .meta({ id: "PlaylistWriteResult" });
