import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    DiscoverSearchQuery,
    DiscoverSearchResponse,
    SearchQuery,
    SearchResponse,
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
];
