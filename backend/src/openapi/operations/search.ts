import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    DiscoverSearchQuery,
    DiscoverSearchResponse,
    SearchQuery,
    SearchResponse,
    UnifiedSearchQuery,
    UnifiedSearchResponse,
} from "../schemas/search";

/** Library and catalog search operations. */
export const searchOperations = [
    defineOperation({
        method: "get",
        path: "/api/search",
        operationId: "search",
        tag: "search",
        summary: "Search the library and the user's liked streaming tracks",
        description:
            "A blank `q` returns every group empty. `type` defaults to `all`, which ignores `offset`; `limit` defaults to 20 and is clamped to 1 to 100 per group. `source` limits library results to local files or federated peers. `remoteTracks` and `remoteAlbums` (liked streaming tracks and albums that are not in the library) are loaded per user, are not cached, and are filled only for `source=all` without `genre`: `type=all` returns up to 5 remote tracks and 6 remote albums, and the first page of `type=tracks` or `type=albums` returns its own group. 400 for an unknown `type` or `source`, or a `q` over 500 characters.",
        query: SearchQuery,
        responses: { 200: SearchResponse, 400: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/search/discover",
        operationId: "searchDiscover",
        tag: "search",
        summary:
            "Search catalogs outside the library for artists, tracks and podcasts",
        description:
            "`type` defaults to `music`; `limit` defaults to 20 and is clamped to 1 to 50. A blank `q` returns no results. Artists already in the library are left out. Results are cached for 15 minutes.",
        query: DiscoverSearchQuery,
        responses: { 200: DiscoverSearchResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/search/unified",
        operationId: "searchUnified",
        tag: "search",
        summary:
            "Search the library, playlists and catalogs as one list ordered by relevance",
        description:
            "Merges library artists, albums, tracks and podcasts, the user's liked streaming tracks and albums that are not in the library, playlists the user can see (their own and public ones), and catalog artists, tracks and podcasts, sorted by `score`. A catalog item that duplicates a library item is left out. `type` defaults to `all`, which ignores `offset`; another `type` returns only that kind and pages by `offset` (at most 1000). `limit` defaults to 30 (1 to 100). A blank `q` returns no items. A disabled or failing catalog degrades to the other sources. Results are cached per user for 2 minutes. 400 for a missing `q`, a `q` over 500 characters, an unknown `type`, or a `limit` or `offset` out of range.",
        query: UnifiedSearchQuery,
        responses: {
            200: UnifiedSearchResponse,
            400: ApiError,
            ...standardErrors,
        },
    }),
];
