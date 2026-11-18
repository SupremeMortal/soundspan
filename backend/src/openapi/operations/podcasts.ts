import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    PodcastDetail,
    PodcastEpisodeParams,
    PodcastIdParams,
    PodcastSummary,
    SubscribedPodcast,
    SubscribePodcastRequest,
    SubscribePodcastResponse,
    TopPodcastsQuery,
    UnsubscribePodcastResponse,
    UpdateEpisodeProgressRequest,
    UpdateEpisodeProgressResponse,
} from "../schemas/podcast";

/** Podcast operations. */
export const podcastOperations = [
    defineOperation({
        method: "get",
        path: "/api/podcasts",
        operationId: "listPodcasts",
        tag: "podcasts",
        summary: "Podcasts the user is subscribed to",
        description:
            "Most recently subscribed first, each with its five latest episodes and the user's progress on them.",
        responses: { 200: z.array(SubscribedPodcast), ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/podcasts/discover/top",
        operationId: "listTopPodcasts",
        tag: "podcasts",
        summary: "Popular podcasts from the iTunes directory",
        description:
            "`limit` defaults to 20 and is capped at 50. An empty list when the directory cannot be reached.",
        query: TopPodcastsQuery,
        responses: { 200: z.array(PodcastSummary), ...standardErrors },
    }),
    defineOperation({
        method: "post",
        path: "/api/podcasts/subscribe",
        operationId: "subscribePodcast",
        tag: "podcasts",
        summary: "Subscribe to a podcast by RSS feed URL or iTunes id",
        description:
            "One of `feedUrl` and `itunesId` is required (400 otherwise); `feedUrl` wins when both are sent. An `itunesId` the iTunes directory does not know, or knows without a feed URL, answers 404. A private or unsafe feed URL answers 400. Subscribing again answers 200 with `message` `Already subscribed`.",
        body: SubscribePodcastRequest,
        responses: {
            200: SubscribePodcastResponse,
            ...standardErrors,
            400: ApiError,
            404: ApiError,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/podcasts/{id}",
        operationId: "getPodcast",
        tag: "podcasts",
        summary: "A subscribed podcast with its episodes",
        description:
            "Episodes are newest first, with the user's progress and download state. A podcast the user is not subscribed to answers 404.",
        params: PodcastIdParams,
        responses: { 200: PodcastDetail, ...standardErrors, 404: ApiError },
    }),
    defineOperation({
        method: "delete",
        path: "/api/podcasts/{id}/unsubscribe",
        operationId: "unsubscribePodcast",
        tag: "podcasts",
        summary: "Unsubscribe from a podcast",
        description:
            "Also removes the user's progress and downloads of the podcast's episodes. A podcast the user is not subscribed to answers 404.",
        params: PodcastIdParams,
        responses: {
            200: UnsubscribePodcastResponse,
            ...standardErrors,
            404: ApiError,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/podcasts/{podcastId}/episodes/{episodeId}/stream",
        operationId: "streamPodcastEpisode",
        tag: "podcasts",
        summary: "Stream a podcast episode",
        description:
            "Served from the server's cache when the episode is cached, otherwise proxied from the feed's enclosure URL. Supports `Range` requests (`206` with `Content-Range`; an unsatisfiable range answers `416` with no body). An enclosure URL that resolves to a private or unsafe address answers 502.",
        params: PodcastEpisodeParams,
        responses: {
            200: { binary: "audio/*" },
            206: { binary: "audio/*" },
            ...standardErrors,
            404: ApiError,
            502: ApiError,
        },
    }),
    defineOperation({
        method: "post",
        path: "/api/podcasts/{podcastId}/episodes/{episodeId}/progress",
        operationId: "updateEpisodeProgress",
        tag: "podcasts",
        summary: "Save playback progress of a podcast episode",
        description:
            "`currentTime` and `duration` are in seconds; `isFinished` defaults to false. `progress` in the answer is the percentage of `duration` played.",
        params: PodcastEpisodeParams,
        body: UpdateEpisodeProgressRequest,
        responses: { 200: UpdateEpisodeProgressResponse, ...standardErrors },
    }),
];
