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

/** Path of the podcast operations addressed by podcast id. */
export const PodcastIdParams = z.object({ id: z.string() });

/** Path of the episode stream and progress operations. */
export const PodcastEpisodeParams = z.object({
    podcastId: z.string(),
    episodeId: z.string(),
});

/**
 * Playback progress of one episode as just saved. `currentTime` is in
 * seconds; `progress` is the percentage of the stored duration played (0
 * when the duration is 0).
 */
export const SavedEpisodeProgress = z
    .object({
        currentTime: z.number(),
        progress: z.number(),
        isFinished: z.boolean(),
    })
    .meta({ id: "SavedEpisodeProgress" });

/** The user's playback progress of one episode. */
export const EpisodeProgress = SavedEpisodeProgress.extend({
    lastPlayedAt: z.iso.datetime(),
}).meta({ id: "EpisodeProgress" });

/**
 * One of the latest episodes of a subscribed podcast. `coverUrl` is the
 * cached cover path (`/podcasts/episodes/{id}/cover`) when the cover is
 * cached, otherwise the feed's image URL. `duration` is in seconds.
 */
export const SubscribedPodcastEpisode = z
    .object({
        id: z.string(),
        title: z.string(),
        description: z.string().nullable(),
        duration: z.number().int(),
        publishedAt: z.iso.datetime(),
        coverUrl: z.string().nullable(),
        progress: EpisodeProgress.nullable(),
    })
    .meta({ id: "SubscribedPodcastEpisode" });

/**
 * A podcast the user is subscribed to, with its five latest episodes.
 * `coverUrl` is the cached cover path (`/podcasts/{id}/cover`) when the cover
 * is cached, otherwise the feed's image URL.
 */
export const SubscribedPodcast = z
    .object({
        id: z.string(),
        title: z.string(),
        author: z.string().nullable(),
        description: z.string().nullable(),
        coverUrl: z.string().nullable(),
        episodeCount: z.number().int(),
        autoDownloadEpisodes: z.boolean(),
        episodes: z.array(SubscribedPodcastEpisode),
    })
    .meta({ id: "SubscribedPodcast" });

/** An episode of a subscribed podcast. `duration` is in seconds. */
export const PodcastEpisode = z
    .object({
        id: z.string(),
        title: z.string(),
        description: z.string().nullable(),
        duration: z.number().int(),
        publishedAt: z.iso.datetime(),
        episodeNumber: z.number().int().nullable(),
        season: z.number().int().nullable(),
        imageUrl: z.string().nullable(),
        isDownloaded: z.boolean(),
        progress: EpisodeProgress.nullable(),
    })
    .meta({ id: "PodcastEpisode" });

/** A subscribed podcast with all its episodes, newest first. */
export const PodcastDetail = z
    .object({
        id: z.string(),
        title: z.string(),
        author: z.string().nullable(),
        description: z.string().nullable(),
        coverUrl: z.string().nullable(),
        feedUrl: z.string(),
        genres: z.array(z.string()),
        autoDownloadEpisodes: z.boolean(),
        isSubscribed: z.boolean(),
        episodes: z.array(PodcastEpisode),
    })
    .meta({ id: "PodcastDetail" });

/** Body of `POST /api/podcasts/{podcastId}/episodes/{episodeId}/progress`. */
export const UpdateEpisodeProgressRequest = z
    .object({
        currentTime: z.number(),
        duration: z.number(),
        isFinished: z.boolean().optional(),
    })
    .meta({ id: "UpdateEpisodeProgressRequest" });

/** Answer of `updateEpisodeProgress`. */
export const UpdateEpisodeProgressResponse = z
    .object({
        success: z.boolean(),
        progress: SavedEpisodeProgress,
    })
    .meta({ id: "UpdateEpisodeProgressResponse" });

/**
 * Body of `POST /api/podcasts/subscribe`. The route also requires one of
 * `feedUrl` and `itunesId`.
 */
export const SubscribePodcastRequest = z
    .object({
        feedUrl: z.string().url().optional(),
        itunesId: z.string().min(1).optional(),
    })
    .meta({ id: "SubscribePodcastRequest" });

/** The podcast a subscribe request resolved to. */
export const SubscribedPodcastRef = z
    .object({ id: z.string(), title: z.string() })
    .meta({ id: "SubscribedPodcastRef" });

/** Answer of `subscribePodcast`. */
export const SubscribePodcastResponse = z
    .object({
        success: z.boolean(),
        podcast: SubscribedPodcastRef,
        message: z.string(),
    })
    .meta({ id: "SubscribePodcastResponse" });

/** Answer of `unsubscribePodcast`. */
export const UnsubscribePodcastResponse = z
    .object({ success: z.boolean(), message: z.string() })
    .meta({ id: "UnsubscribePodcastResponse" });
