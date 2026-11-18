import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    DiscoverCurrent,
    PopularArtistsQuery,
    PopularArtistsResponse,
    RecommendationsForYou,
    RecommendationsForYouQuery,
} from "../schemas/discovery";
import { MixDetail, MixIdParams, MixSummary } from "../schemas/mix";
import {
    RadioDecadesResponse,
    RadioGenresResponse,
    RadioQuery,
    RadioResponse,
} from "../schemas/radio";
import {
    SimilarTracksQuery,
    SimilarTracksResponse,
    VibeSearchRequest,
    VibeSearchResponse,
    VibeTrackIdParams,
} from "../schemas/vibe";

const DISCOVERY_DISABLED =
    "404 with code `FEATURE_DISABLED` when discovery is turned off.";
const AUDIO_ANALYSIS_DISABLED =
    "404 with code `FEATURE_DISABLED` when audio analysis is turned off.";

/** Home and discovery operations. */
export const discoveryOperations = [
    defineOperation({
        method: "get",
        path: "/api/mixes",
        operationId: "listMixes",
        tag: "discovery",
        summary: "The user's generated mixes",
        description:
            "Cached for an hour per user. 404 with code `FEATURE_DISABLED` when automatic playlists are turned off.",
        responses: {
            200: z.array(MixSummary),
            404: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/mixes/{id}",
        operationId: "getMix",
        tag: "discovery",
        summary: "A generated mix with its tracks",
        description:
            "Answered from the hour-long mix cache. 404 when the user has no mix with this id, and with code `FEATURE_DISABLED` when automatic playlists are turned off.",
        params: MixIdParams,
        responses: { 200: MixDetail, 404: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/recommendations/for-you",
        operationId: "getRecommendationsForYou",
        tag: "discovery",
        summary: "Artists similar to the ones the user plays most",
        description: DISCOVERY_DISABLED,
        query: RecommendationsForYouQuery,
        responses: {
            200: RecommendationsForYou,
            404: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/discover/current",
        operationId: "getCurrentDiscover",
        tag: "discovery",
        summary: "The current week's Discover playlist",
        description: DISCOVERY_DISABLED,
        responses: { 200: DiscoverCurrent, 404: ApiError, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/discover/popular-artists",
        operationId: "listPopularArtists",
        tag: "discovery",
        summary: "Popular artists from the Last.fm chart",
        description: DISCOVERY_DISABLED,
        query: PopularArtistsQuery,
        responses: {
            200: PopularArtistsResponse,
            404: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/radio",
        operationId: "getRadio",
        tag: "discovery",
        summary: "A radio queue built from the library",
        description:
            "Any other `type` is treated as `all`. 400 when `type` is missing or a type that needs `value` has none. 401 for `liked`, or `playlist` radio of the My Liked playlist, without a user. 403 for another user's private playlist. 404 when the `vibe` seed track or the playlist does not exist.",
        query: RadioQuery,
        responses: {
            200: RadioResponse,
            400: ApiError,
            403: ApiError,
            404: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/genres",
        operationId: "listRadioGenres",
        tag: "discovery",
        summary: "Library genres with track counts, for genre radio",
        responses: { 200: RadioGenresResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/library/decades",
        operationId: "listRadioDecades",
        tag: "discovery",
        summary: "Library decades with track counts, for decade radio",
        responses: { 200: RadioDecadesResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/vibe/similar/{trackId}",
        operationId: "getSimilarTracks",
        tag: "discovery",
        summary: "Tracks that sound like a track",
        description: `404 when no similar track is found. ${AUDIO_ANALYSIS_DISABLED}`,
        params: VibeTrackIdParams,
        query: SimilarTracksQuery,
        responses: {
            200: SimilarTracksResponse,
            404: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "post",
        path: "/api/vibe/search",
        operationId: "searchVibe",
        tag: "discovery",
        summary: "Tracks matching a natural-language description",
        description: `A \`limit\` or \`minSimilarity\` out of range is clamped. 400 for a query shorter than 2 or longer than 512 characters. 502 when the text embedding provider answers with an invalid response, 503 when it is unavailable, 504 when it times out. ${AUDIO_ANALYSIS_DISABLED}`,
        body: VibeSearchRequest,
        responses: {
            200: VibeSearchResponse,
            400: ApiError,
            404: ApiError,
            502: ApiError,
            504: ApiError,
            ...standardErrors,
        },
    }),
];
