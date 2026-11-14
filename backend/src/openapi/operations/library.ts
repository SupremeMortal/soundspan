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

const IdParams = z.object({ id: z.string() });

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
];
