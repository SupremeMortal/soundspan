import { z } from "zod";
import { defineOperation } from "../defineOperation";
import {
    AlbumDetail,
    AlbumDetailQuery,
    AlbumListQuery,
    AlbumListResponse,
} from "../schemas/album";
import {
    ArtistDetail,
    ArtistDetailQuery,
    ArtistListQuery,
    ArtistListResponse,
} from "../schemas/artist";
import { ApiError, standardErrors } from "../schemas/common";
import { CoverArtQuery } from "../schemas/coverArt";
import {
    RecentlyAddedResponse,
    RecentlyListenedResponse,
    RecentShelfQuery,
} from "../schemas/recent";
import {
    LibraryTrackListQuery,
    LibraryTrackListResponse,
    LikedTracksQuery,
    LikedTracksResponse,
} from "../schemas/track";

const IdParams = z.object({ id: z.string() });

/** Statuses of both cover-art operations. */
const coverArtResponses = {
    200: { binary: "image/*" },
    302: null,
    304: null,
    400: ApiError,
    404: ApiError,
    502: ApiError,
    ...standardErrors,
};

const COVER_ART_DESCRIPTION =
    "Served as webp when `Accept` includes `image/webp` and a `size` is given; images are downscaled, never upscaled. 302 redirects to an external or native cover. 304 answers a matching `If-None-Match`.";

/** Library browse operations. */
export const libraryOperations = [
    defineOperation({
        method: "get",
        path: "/api/library/artists",
        operationId: "listArtists",
        tag: "library",
        summary: "One page of library artists",
        description:
            "Offset paging with `limit` and `offset`; pass `nextCursor` back as `cursor` to page by cursor instead. `sortBy=tracks` uses stored library track counts and does not include remote counts. 400 for an unknown `origin`.",
        query: ArtistListQuery,
        responses: {
            200: ArtistListResponse,
            400: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/artists/{id}",
        operationId: "getArtist",
        tag: "library",
        summary: "An artist with its albums, top tracks and similar artists",
        description:
            "`id` is a library artist id, a MusicBrainz artist id, or an artist name (case-insensitive). Each `include*` flag defaults to true; with `includeDiscography` the albums include MusicBrainz release groups the library does not hold.",
        params: IdParams,
        query: ArtistDetailQuery,
        responses: { 200: ArtistDetail, 404: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/albums",
        operationId: "listAlbums",
        tag: "library",
        summary: "One page of library albums",
        description: "400 for an unknown `origin`.",
        query: AlbumListQuery,
        responses: { 200: AlbumListResponse, 400: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/albums/{id}",
        operationId: "getAlbum",
        tag: "library",
        summary: "An album with its tracks",
        description:
            "`id` is a library album id or a release-group MBID. `includeTracks` defaults to true; without it `tracks` is empty.",
        params: IdParams,
        query: AlbumDetailQuery,
        responses: { 200: AlbumDetail, 404: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/tracks",
        operationId: "listTracks",
        tag: "library",
        summary: "One page of library tracks (the Songs list)",
        description:
            "Merges library tracks with the user's liked TIDAL and YouTube Music tracks that are not in the library, unless `albumId` or `origin=local|peers` is given. With `albumId` the tracks are in disc and track order and `sortBy` is ignored. 400 for an unknown `origin`, or `origin=remote` with `albumId`.",
        query: LibraryTrackListQuery,
        responses: {
            200: LibraryTrackListResponse,
            400: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/liked",
        operationId: "listLikedTracks",
        tag: "library",
        summary: "One page of the user's liked tracks",
        description:
            "Library and streaming likes merged, newest first, with duplicates of one recording collapsed. `cursorLikedAt` and `cursorTrackId` must be sent together (400 otherwise, or when `cursorLikedAt` is not a timestamp).",
        query: LikedTracksQuery,
        responses: {
            200: LikedTracksResponse,
            400: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/recently-listened",
        operationId: "listRecentlyListened",
        tag: "library",
        summary: "Recently listened artists, audiobooks and podcasts",
        description: "`limit` defaults to 10 and is clamped to 1 to 100.",
        query: RecentShelfQuery,
        responses: { 200: RecentlyListenedResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/recently-added",
        operationId: "listRecentlyAdded",
        tag: "library",
        summary: "Artists of the most recently added library albums",
        description:
            "`limit` defaults to 10; at most the 20 most recently added albums are considered.",
        query: RecentShelfQuery,
        responses: { 200: RecentlyAddedResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/cover-art",
        operationId: "getCoverArtByUrl",
        tag: "library",
        summary: "The cover image at `url`, proxied and cached",
        description: `400 without \`url\` or for a URL that is not allowed. ${COVER_ART_DESCRIPTION}`,
        query: CoverArtQuery,
        responses: coverArtResponses,
    }),
    defineOperation({
        method: "get",
        path: "/api/library/cover-art/{id}",
        operationId: "getCoverArt",
        tag: "library",
        summary: "A cover image by album id, cover id or cover path",
        description: COVER_ART_DESCRIPTION,
        params: IdParams,
        query: CoverArtQuery,
        responses: coverArtResponses,
    }),
];
