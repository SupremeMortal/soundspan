import { z } from "zod";
import { TrackSummary } from "./track";

/** Path parameters of `GET /api/vibe/similar/{trackId}`. */
export const VibeTrackIdParams = z.object({ trackId: z.string() });

/** Query of `GET /api/vibe/similar/{trackId}`. */
export const SimilarTracksQuery = z.object({
    limit: z
        .number()
        .int()
        .min(1)
        .max(100)
        .optional()
        .describe("Defaults to 20."),
});

/** The audio values a vibe match compares; null where not analysed. */
export const VibeAudioFeatures = z
    .object({
        energy: z.number().nullable(),
        valence: z.number().nullable(),
        danceability: z.number().nullable(),
        arousal: z.number().nullable(),
    })
    .meta({ id: "VibeAudioFeatures" });

/**
 * A track that sounds like the seed. `similarity` is 0 to 1, after the
 * user's likes and dislikes are applied; `distance` is the raw distance.
 */
export const SimilarTrack = TrackSummary.extend({
    distance: z.number(),
    similarity: z.number(),
    audioFeatures: VibeAudioFeatures,
}).meta({ id: "SimilarTrack" });

/** Tracks similar to `sourceTrackId`, most similar first. */
export const SimilarTracksResponse = z
    .object({
        sourceTrackId: z.string(),
        sourceFeatures: VibeAudioFeatures.nullable(),
        tracks: z.array(SimilarTrack),
    })
    .meta({ id: "SimilarTracksResponse" });

/** Body of `POST /api/vibe/search`. */
export const VibeSearchRequest = z
    .object({
        query: z
            .string()
            .min(2)
            .max(512)
            .describe(
                "Natural language, for example `chill acoustic guitar`; at least 2 characters after trimming.",
            ),
        limit: z
            .number()
            .int()
            .min(1)
            .max(100)
            .optional()
            .describe("Defaults to 20."),
        minSimilarity: z
            .number()
            .min(0)
            .max(1)
            .optional()
            .describe("Defaults to 0.6."),
    })
    .meta({ id: "VibeSearchRequest" });

/** A track matching a vibe search; `similarity` is 0 to 1. */
export const VibeSearchTrack = TrackSummary.extend({
    trackNo: z.number().int(),
    distance: z.number(),
    similarity: z.number(),
}).meta({ id: "VibeSearchTrack" });

/** Tracks matching a vibe search, best match first. */
export const VibeSearchResponse = z
    .object({
        query: z.string(),
        tracks: z.array(VibeSearchTrack),
        minSimilarity: z.number(),
        totalAboveThreshold: z.number().int(),
    })
    .meta({ id: "VibeSearchResponse" });
