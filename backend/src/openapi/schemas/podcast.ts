import { z } from "zod";

/**
 * A podcast from the iTunes directory, not subscribed on this server. `id`
 * is the iTunes collection id as a string; `itunesId` is the same id as a
 * number.
 */
export const PodcastSummary = z
    .object({
        id: z.string(),
        title: z.string(),
        author: z.string(),
        coverUrl: z.string().optional(),
        feedUrl: z.string().optional(),
        genres: z.array(z.string()),
        episodeCount: z.number().int(),
        itunesId: z.number().int(),
        isExternal: z.boolean(),
    })
    .meta({ id: "PodcastSummary" });

/** Query of `GET /api/podcasts/discover/top`. */
export const TopPodcastsQuery = z.object({
    limit: z.number().int().optional(),
});
