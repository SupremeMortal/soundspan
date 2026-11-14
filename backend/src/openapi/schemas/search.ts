import { z } from "zod";
import { PeerRef, RemoteProvider } from "./common";
import { ArtistRef, LibraryTrack, TrackSummary } from "./track";

/** Where a library search result is stored. */
const SearchResultSource = z.enum(["local", "federated"]);

/**
 * A library artist matching a search. `peer` is null or absent for a local
 * artist.
 */
export const SearchArtist = z
    .object({
        id: z.string(),
        name: z.string(),
        mbid: z.string().nullable(),
        heroUrl: z.string().nullable(),
        summary: z.string().nullable().optional(),
        rank: z.number(),
        source: SearchResultSource.optional(),
        peer: PeerRef.nullable().optional(),
    })
    .meta({ id: "SearchArtist" });

/** A library album matching a search. */
export const SearchAlbum = z
    .object({
        id: z.string(),
        title: z.string(),
        artistId: z.string(),
        year: z.number().int().nullable(),
        coverUrl: z.string().nullable(),
        source: SearchResultSource.optional(),
        peer: PeerRef.nullable().optional(),
        artist: ArtistRef,
    })
    .meta({ id: "SearchAlbum" });

/** A library track matching a search. */
export const SearchTrack = TrackSummary.extend({
    albumId: z.string(),
    trackNo: z.number().int(),
    source: SearchResultSource.optional(),
    peer: PeerRef.nullable().optional(),
}).meta({ id: "SearchTrack" });

/** A subscribed podcast matching a search. */
export const SearchPodcast = z
    .object({
        id: z.string(),
        title: z.string(),
        author: z.string().nullable(),
        description: z.string().nullable(),
        imageUrl: z.string().nullable(),
        episodeCount: z.number().int(),
        rank: z.number().optional(),
    })
    .meta({ id: "SearchPodcast" });

/** A podcast episode matching a search. */
export const SearchEpisode = z
    .object({
        id: z.string(),
        title: z.string(),
        description: z.string().nullable(),
        podcastId: z.string(),
        podcastTitle: z.string(),
        publishedAt: z.iso.datetime(),
        duration: z.number().int(),
        audioUrl: z.string(),
        rank: z.number(),
    })
    .meta({ id: "SearchEpisode" });

/**
 * A liked TIDAL or YouTube Music track that is not in the library. The server
 * also sends legacy per-source fields for other consumers; clients play it by
 * `playbackId`.
 */
export const SearchRemoteTrack = LibraryTrack.omit({ source: true })
    .extend({
        albumId: z.string().nullable(),
        artistId: z.string().nullable(),
    })
    .meta({ id: "SearchRemoteTrack" });

/**
 * A liked TIDAL or YouTube Music album that is not in the library;
 * `remoteSources` lists the services it was liked on.
 */
export const SearchRemoteAlbum = z
    .object({
        id: z.string(),
        title: z.string(),
        artistId: z.string(),
        year: z.number().int().nullable(),
        coverUrl: z.string().nullable(),
        source: z.enum(["remote"]),
        remoteSources: z.array(RemoteProvider),
        artist: ArtistRef,
    })
    .meta({ id: "SearchRemoteAlbum" });

/** Library search results by kind; see the `search` operation for the remote groups. */
export const SearchResponse = z
    .object({
        artists: z.array(SearchArtist),
        albums: z.array(SearchAlbum),
        tracks: z.array(SearchTrack),
        podcasts: z.array(SearchPodcast),
        episodes: z.array(SearchEpisode),
        remoteTracks: z.array(SearchRemoteTrack),
        remoteAlbums: z.array(SearchRemoteAlbum),
    })
    .meta({ id: "SearchResponse" });

/** Query of `GET /api/search`. */
export const SearchQuery = z.object({
    q: z.string().max(500).optional(),
    type: z
        .enum([
            "all",
            "artists",
            "albums",
            "tracks",
            "audiobooks",
            "podcasts",
            "episodes",
        ])
        .optional(),
    genre: z.string().max(120).optional(),
    limit: z.number().int().optional(),
    offset: z.number().int().min(0).max(10_000).optional(),
    source: z.enum(["all", "local", "peers"]).optional(),
});

/**
 * One catalog result outside the library: an artist (`music`), a track
 * (`track`) or a podcast from the iTunes directory (`podcast`). `id` is a
 * number for podcasts (the iTunes collection id) and a string otherwise.
 * Fields that do not apply to a kind are absent. A track can be played when
 * it has a `playbackId`. The server also sends legacy per-source fields for
 * other consumers.
 */
export const DiscoverResult = z
    .object({
        type: z.enum(["music", "track", "podcast"]),
        id: z.union([z.string(), z.number()]),
        name: z.string(),
        mbid: z.string().optional(),
        image: z.string().nullable().optional(),
        listeners: z.number().int().optional(),
        url: z.string().nullable().optional(),
        bio: z.string().nullable().optional(),
        tags: z.array(z.string()).optional(),
        artist: z.string().optional(),
        album: z.string().nullable().optional(),
        durationSec: z.number().nullable().optional(),
        previewUrl: z.string().nullable().optional(),
        playbackId: z.string().optional(),
        description: z.string().optional(),
        coverUrl: z.string().optional(),
        feedUrl: z.string().optional(),
        genres: z.array(z.string()).optional(),
        trackCount: z.number().int().optional(),
    })
    .meta({ id: "DiscoverResult" });

/** Set when Last.fm corrected the query to an artist's canonical name. */
export const DiscoverAliasInfo = z
    .object({
        original: z.string(),
        canonical: z.string(),
        mbid: z.string().optional(),
    })
    .meta({ id: "DiscoverAliasInfo" });

/** Catalog search results: new artists first, then tracks, then podcasts. */
export const DiscoverSearchResponse = z
    .object({
        results: z.array(DiscoverResult),
        aliasInfo: DiscoverAliasInfo.nullable(),
    })
    .meta({ id: "DiscoverSearchResponse" });

/** Query of `GET /api/search/discover`. */
export const DiscoverSearchQuery = z.object({
    q: z.string().optional(),
    type: z.enum(["music", "podcasts", "all"]).optional(),
    limit: z.number().int().optional(),
});
