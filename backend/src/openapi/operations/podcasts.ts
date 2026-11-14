import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { standardErrors } from "../schemas/common";
import { PodcastSummary, TopPodcastsQuery } from "../schemas/podcast";

/** Podcast operations. */
export const podcastOperations = [
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
];
