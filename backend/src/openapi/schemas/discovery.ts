import { z } from "zod";

/** Query of `GET /api/recommendations/for-you`. */
export const RecommendationsForYouQuery = z.object({
    limit: z.number().int().optional().describe("Defaults to 10."),
});

/**
 * An artist similar to the ones the user plays most, not in the library.
 * `coverArt` is the artist image (`heroUrl` or a cached image), null when
 * none is known yet.
 */
export const RecommendedArtist = z
    .object({
        id: z.string(),
        mbid: z.string().nullable(),
        name: z.string(),
        heroUrl: z.string().nullable(),
        coverArt: z.string().nullable(),
        albumCount: z.number().int(),
    })
    .meta({ id: "RecommendedArtist" });

/** Artist recommendations; empty when the user has no listening history. */
export const RecommendationsForYou = z
    .object({ artists: z.array(RecommendedArtist) })
    .meta({ id: "RecommendationsForYou" });

/** How far a Discover recommendation is from the user's taste. */
export const RecommendationTier = z
    .enum(["high", "medium", "explore", "wildcard"])
    .meta({ id: "RecommendationTier" });

/**
 * A track of the week's Discover playlist. `artist` and `album` are names;
 * `albumId` is the album's MusicBrainz release-group id. `playbackId` streams
 * the track.
 */
export const DiscoverTrack = z
    .object({
        id: z.string(),
        title: z.string(),
        artist: z.string(),
        album: z.string(),
        albumId: z.string(),
        isLiked: z.boolean(),
        likedAt: z.iso.datetime().nullable(),
        similarity: z.number(),
        tier: RecommendationTier,
        coverUrl: z.string().nullable(),
        available: z.boolean(),
        duration: z.number().int(),
        sourceType: z.enum(["local"]),
        loudnessLufs: z.number().nullable().optional(),
        truePeakDb: z.number().nullable().optional(),
        albumLoudnessLufs: z.number().nullable().optional(),
        albumTruePeakDb: z.number().nullable().optional(),
        playbackId: z
            .string()
            .optional()
            .describe("Opaque track identifier. Do not parse."),
    })
    .meta({ id: "DiscoverTrack" });

/**
 * The current week's Discover playlist (Monday to Sunday). `tracks` is empty
 * before the week's playlist has been generated.
 */
export const DiscoverCurrent = z
    .object({
        weekStart: z.iso.datetime(),
        weekEnd: z.iso.datetime(),
        tracks: z.array(DiscoverTrack),
        totalCount: z.number().int(),
        unavailableCount: z.number().int(),
    })
    .meta({ id: "DiscoverCurrent" });

/** Query of `GET /api/discover/popular-artists`. */
export const PopularArtistsQuery = z.object({
    limit: z
        .number()
        .int()
        .min(1)
        .max(100)
        .optional()
        .describe("Defaults to 20."),
});

/**
 * An artist of the Last.fm chart. `id` is the MusicBrainz id, or the name
 * when Last.fm has none.
 */
export const PopularArtist = z
    .object({
        id: z.string(),
        name: z.string(),
        listeners: z.number().int(),
        playCount: z.number().int(),
        image: z.string().nullable(),
        mbid: z.string().optional(),
        url: z.string().optional(),
    })
    .meta({ id: "PopularArtist" });

/** Popular artists; empty when Last.fm is not configured or fails. */
export const PopularArtistsResponse = z
    .object({ artists: z.array(PopularArtist) })
    .meta({ id: "PopularArtistsResponse" });
