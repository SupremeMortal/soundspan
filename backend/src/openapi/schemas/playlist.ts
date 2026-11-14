import { z } from "zod";
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
