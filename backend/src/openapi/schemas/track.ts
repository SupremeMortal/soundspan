import { z } from "zod";
import { LibraryOriginQuery, PeerRef } from "./common";

/** An artist as embedded in a track; Last.fm-only tracks carry no `id`. */
export const TrackArtistRef = z
    .object({
        id: z.string().optional(),
        name: z.string(),
    })
    .meta({ id: "TrackArtistRef" });

/** An artist reference with its library id. */
export const ArtistRef = z
    .object({
        id: z.string(),
        name: z.string(),
        mbid: z.string().nullable().optional(),
    })
    .meta({ id: "ArtistRef" });

/** The album a track belongs to; a track not in the library has no `id`. */
export const TrackAlbumRef = z
    .object({
        id: z.string().optional(),
        title: z.string(),
        coverArt: z.string().nullable().optional(),
        coverUrl: z.string().nullable().optional(),
        albumLoudnessLufs: z.number().nullable().optional(),
        albumTruePeakDb: z.number().nullable().optional(),
        artist: ArtistRef.optional(),
    })
    .meta({ id: "TrackAlbumRef" });

/**
 * A track row as embedded in album and artist detail. `playbackId` is absent
 * when the track cannot be played (no stream source).
 */
export const TrackSummary = z
    .object({
        id: z.string(),
        title: z.string(),
        duration: z.number().int(),
        trackNo: z.number().int().nullable().optional(),
        discNo: z.number().int().optional(),
        playbackId: z.string().optional(),
        albumId: z.string().optional(),
        isrc: z.string().nullable().optional(),
        loudnessLufs: z.number().nullable().optional(),
        truePeakDb: z.number().nullable().optional(),
        artist: TrackArtistRef.optional(),
        album: TrackAlbumRef.optional(),
        peer: PeerRef.optional(),
    })
    .meta({ id: "TrackSummary" });

/**
 * An artist on a library list track; `id` is null for a streaming track that
 * is not linked to a library artist.
 */
export const LibraryTrackArtist = z
    .object({
        id: z.string().nullable(),
        name: z.string(),
    })
    .meta({ id: "LibraryTrackArtist" });

/**
 * The album of a library list track; `id` is null for a streaming track that
 * is not linked to a library album. `rgMbid`, `matchedRgMbid` and
 * `matchedInLibrary` are sent by the Songs list only.
 */
export const LibraryTrackAlbum = z
    .object({
        id: z.string().nullable(),
        title: z.string(),
        coverArt: z.string().nullable(),
        coverUrl: z.string().nullable().optional(),
        rgMbid: z.string().nullable().optional(),
        matchedRgMbid: z.string().nullable().optional(),
        matchedInLibrary: z.boolean().optional(),
        albumLoudnessLufs: z.number().nullable().optional(),
        albumTruePeakDb: z.number().nullable().optional(),
        artist: LibraryTrackArtist.optional(),
    })
    .meta({ id: "LibraryTrackAlbum" });

/**
 * Where a library list track plays from. Clients must tolerate values added
 * later.
 */
export const TrackSource = z
    .enum(["local", "federated", "tidal", "youtube"])
    .meta({ id: "TrackSource" });

/**
 * A track in a library list that merges library rows (`local`,
 * `federated`) with liked streaming rows. A streaming row has no `trackNo`
 * and may have no library album or artist.
 */
export const LibraryTrack = TrackSummary.extend({
    trackNo: z.number().int().nullable(),
    albumId: z.string().nullable().optional(),
    source: TrackSource,
    artist: LibraryTrackArtist.optional(),
    album: LibraryTrackAlbum,
}).meta({ id: "LibraryTrack" });

/** One page of the library Songs list. */
export const LibraryTrackListResponse = z
    .object({
        tracks: z.array(LibraryTrack),
        total: z.number().int(),
        offset: z.number().int(),
        limit: z.number().int(),
    })
    .meta({ id: "LibraryTrackListResponse" });

/** Query of `GET /api/library/tracks`. */
export const LibraryTrackListQuery = z.object({
    albumId: z.string().optional(),
    limit: z.number().int().optional(),
    offset: z.number().int().optional(),
    sortBy: z.enum(["name", "name-desc"]).optional(),
    origin: LibraryOriginQuery.optional(),
});

/** A liked track, with the time it was first liked. */
export const LikedTrack = LibraryTrack.extend({
    likedAt: z.iso.datetime(),
}).meta({ id: "LikedTrack" });

/** The fixed playlist the liked tracks are presented as. */
export const LikedPlaylistInfo = z
    .object({
        id: z.string(),
        name: z.string(),
        description: z.string(),
    })
    .meta({ id: "LikedPlaylistInfo" });

/** Pass both values back as `cursorLikedAt` and `cursorTrackId`. */
export const LikedTracksCursor = z
    .object({
        likedAt: z.iso.datetime(),
        trackId: z.string(),
    })
    .meta({ id: "LikedTracksCursor" });

/** Paging state of the liked tracks list. */
export const LikedTracksPagination = z
    .object({
        limit: z.number().int(),
        hasMore: z.boolean(),
        nextCursor: LikedTracksCursor.nullable(),
    })
    .meta({ id: "LikedTracksPagination" });

/** One page of liked tracks, newest like first. */
export const LikedTracksResponse = z
    .object({
        playlist: LikedPlaylistInfo,
        tracks: z.array(LikedTrack),
        total: z.number().int(),
        pagination: LikedTracksPagination,
    })
    .meta({ id: "LikedTracksResponse" });

/** Query of `GET /api/library/liked`. */
export const LikedTracksQuery = z.object({
    limit: z.number().int().optional(),
    cursorLikedAt: z.iso.datetime().optional(),
    cursorTrackId: z.string().optional(),
});
