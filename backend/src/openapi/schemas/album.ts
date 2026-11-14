import { z } from "zod";
import { LibraryOriginQuery, PeerRef, RemoteProvider } from "./common";
import { ArtistRef, TrackSummary } from "./track";

/** Fields every album row carries, in lists and in artist detail. */
const albumFields = {
    id: z.string(),
    title: z.string(),
    year: z.number().int().nullable(),
    coverArt: z.string().nullable(),
    artistId: z.string(),
    rgMbid: z.string().nullable(),
    remoteSources: z.array(RemoteProvider).optional(),
    peer: PeerRef.optional(),
};

/** An album in the library album list. */
export const AlbumSummary = z
    .object({
        ...albumFields,
        source: z.enum(["local", "federated", "remote"]),
        artist: ArtistRef,
    })
    .meta({ id: "AlbumSummary" });

/** An album with its tracks, ownership and release-group match. */
export const AlbumDetail = AlbumSummary.extend({
    owned: z.boolean(),
    matchedRgMbid: z.string().nullable(),
    matchedInLibrary: z.boolean(),
    tracks: z.array(TrackSummary).optional(),
}).meta({ id: "AlbumDetail" });

/** One page of the library album list. */
export const AlbumListResponse = z
    .object({
        albums: z.array(AlbumSummary),
        total: z.number().int(),
        offset: z.number().int(),
        limit: z.number().int(),
    })
    .meta({ id: "AlbumListResponse" });

/** Query of `GET /api/library/albums`. */
export const AlbumListQuery = z.object({
    artistId: z.string().optional(),
    limit: z.number().int().optional(),
    offset: z.number().int().optional(),
    filter: z.enum(["owned", "discovery", "all"]).optional(),
    sortBy: z.enum(["name", "name-desc", "recent"]).optional(),
    origin: LibraryOriginQuery.optional(),
});

/** Query of `GET /api/library/albums/{id}`. */
export const AlbumDetailQuery = z.object({
    includeTracks: z.boolean().optional(),
});

/**
 * An album in artist detail: a library album (`database`), a liked remote
 * album (`remote`) or a MusicBrainz release group not in the library
 * (`musicbrainz`, no tracks).
 */
export const ArtistAlbum = z
    .object({
        ...albumFields,
        source: z.enum(["database", "musicbrainz", "remote"]),
        provenanceSource: z.enum(["local", "federated", "remote"]).optional(),
        owned: z.boolean(),
        tracks: z.array(TrackSummary),
    })
    .meta({ id: "ArtistAlbum" });
