import { z } from "zod";
import { TrackSummary } from "./track";

/** Radio station types `GET /api/library/radio` accepts. */
export const RadioType = z
    .enum([
        "all",
        "liked",
        "discovery",
        "favorites",
        "decade",
        "genre",
        "mood",
        "workout",
        "artist",
        "artist-name",
        "vibe",
        "playlist",
        "tracks",
    ])
    .meta({ id: "RadioType" });

/** Query of `GET /api/library/radio`. */
export const RadioQuery = z.object({
    type: RadioType,
    value: z
        .string()
        .optional()
        .describe(
            "The station seed: a decade (`1990`), genre, mood, artist id, artist name, track id (`vibe`), playlist id, or comma-separated track ids (`tracks`).",
        ),
    limit: z
        .number()
        .int()
        .optional()
        .describe(
            "Defaults to 50; at most 100 (`liked`: the library maximum).",
        ),
});

/** Audio analysis values of a track; null where the track is not analysed. */
export const RadioAudioFeatures = z
    .object({
        bpm: z.number().nullable(),
        energy: z.number().nullable(),
        valence: z.number().nullable(),
        arousal: z.number().nullable(),
        danceability: z.number().nullable(),
        keyScale: z.string().nullable(),
        instrumentalness: z.number().nullable(),
        analysisMode: z.string().nullable(),
        moodHappy: z.number().nullable(),
        moodSad: z.number().nullable(),
        moodRelaxed: z.number().nullable(),
        moodAggressive: z.number().nullable(),
        moodParty: z.number().nullable(),
        moodAcoustic: z.number().nullable(),
        moodElectronic: z.number().nullable(),
    })
    .meta({ id: "RadioAudioFeatures" });

/** A radio track; `audioFeatures` is present on `vibe` stations only. */
export const RadioTrack = TrackSummary.extend({
    playbackId: z.string(),
    trackNo: z.number().int(),
    audioFeatures: RadioAudioFeatures.optional(),
}).meta({ id: "RadioTrack" });

/**
 * A radio queue. `sourceFeatures` (the seed track's analysis) is present on
 * `vibe` stations only.
 */
export const RadioResponse = z
    .object({
        tracks: z.array(RadioTrack),
        sourceFeatures: RadioAudioFeatures.optional(),
    })
    .meta({ id: "RadioResponse" });

/** A library genre with its track count. */
export const RadioGenre = z
    .object({ genre: z.string(), count: z.number().int() })
    .meta({ id: "RadioGenre" });

/** Genres for genre radio. */
export const RadioGenresResponse = z
    .object({ genres: z.array(RadioGenre) })
    .meta({ id: "RadioGenresResponse" });

/** A decade (its first year, for example `1990`) with its track count. */
export const RadioDecade = z
    .object({ decade: z.number().int(), count: z.number().int() })
    .meta({ id: "RadioDecade" });

/** Decades for decade radio. */
export const RadioDecadesResponse = z
    .object({ decades: z.array(RadioDecade) })
    .meta({ id: "RadioDecadesResponse" });
