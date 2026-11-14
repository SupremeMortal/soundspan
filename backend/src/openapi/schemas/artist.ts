import { z } from "zod";
import { LibraryOriginQuery, PeerRef, RemoteProvider } from "./common";
import { ArtistAlbum } from "./album";
import { TrackSummary } from "./track";

/** An artist in the library artist list. */
export const ArtistSummary = z
    .object({
        id: z.string(),
        mbid: z.string().nullable(),
        name: z.string(),
        coverArt: z.string().nullable(),
        albumCount: z.number().int(),
        trackCount: z.number().int(),
        source: z.enum(["federated", "remote"]).optional(),
        remoteSources: z.array(RemoteProvider).optional(),
        peer: PeerRef.optional(),
    })
    .meta({ id: "ArtistSummary" });

/** One page of the library artist list. */
export const ArtistListResponse = z
    .object({
        artists: z.array(ArtistSummary),
        total: z.number().int(),
        offset: z.number().int(),
        limit: z.number().int(),
        nextCursor: z.string().nullable(),
    })
    .meta({ id: "ArtistListResponse" });

/** A top track of an artist, with Last.fm and the user's play counts. */
export const ArtistTopTrack = TrackSummary.extend({
    playCount: z.number().int().optional(),
    listeners: z.number().int().optional(),
    userPlayCount: z.number().int().optional(),
}).meta({ id: "ArtistTopTrack" });

/** An artist similar to another; `id` is the name when not in the library. */
export const SimilarArtist = z
    .object({
        id: z.string(),
        name: z.string(),
        mbid: z.string().nullable(),
        coverArt: z.string().nullable(),
        albumCount: z.number().int(),
        ownedAlbumCount: z.number().int(),
        weight: z.number(),
        inLibrary: z.boolean(),
    })
    .meta({ id: "SimilarArtist" });

/** An artist with the sections its `include*` flags asked for. */
export const ArtistDetail = z
    .object({
        id: z.string(),
        mbid: z.string().nullable(),
        name: z.string(),
        coverArt: z.string().nullable(),
        bio: z.string().nullable(),
        genres: z.array(z.string()),
        source: z.enum(["local", "federated"]),
        peer: PeerRef.optional(),
        albums: z.array(ArtistAlbum).optional(),
        topTracks: z.array(ArtistTopTrack).optional(),
        similarArtists: z.array(SimilarArtist).optional(),
        discographyComplete: z.boolean(),
    })
    .meta({ id: "ArtistDetail" });

/** Query of `GET /api/library/artists`. */
export const ArtistListQuery = z.object({
    limit: z.number().int().optional(),
    offset: z.number().int().optional(),
    cursor: z.string().optional(),
    filter: z.enum(["owned", "discovery", "remote", "all"]).optional(),
    sortBy: z.enum(["name", "name-desc", "tracks"]).optional(),
    origin: LibraryOriginQuery.optional(),
    query: z.string().optional(),
});

/** Query of `GET /api/library/artists/{id}`. */
export const ArtistDetailQuery = z.object({
    includeDiscography: z.boolean().optional(),
    includeTopTracks: z.boolean().optional(),
    includeSimilarArtists: z.boolean().optional(),
});
