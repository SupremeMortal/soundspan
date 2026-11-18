import { z } from "zod";
import { PlaybackMetadata } from "./play";

/** A like, a dislike, or clearing both. */
export const PreferenceSignal = z
    .enum(["thumbs_up", "thumbs_down", "clear"])
    .meta({ id: "PreferenceSignal" });

/** The preference that results from a signal. */
export const PreferenceState = z
    .enum(["liked", "disliked", "neutral"])
    .meta({ id: "PreferenceState" });

/** Body of `POST /api/library/preferences`. */
export const TrackPreferenceRequest = z
    .object({
        playbackId: z
            .string()
            .min(1)
            .describe("Opaque track identifier. Do not parse."),
        signal: PreferenceSignal,
        metadata: PlaybackMetadata.optional(),
    })
    .meta({ id: "TrackPreferenceRequest" });

/** Fields every preference answer carries. */
const preferenceFields = {
    signal: PreferenceSignal,
    state: PreferenceState,
    score: z.number().int().describe("1 liked, -1 disliked, 0 neutral"),
    likedAt: z.iso.datetime().nullable(),
    dislikedAt: z.iso.datetime().nullable(),
    updatedAt: z.iso.datetime().nullable(),
};

/** The stored preference of one track, with the request's `playbackId`. */
export const TrackPreferenceResponse = z
    .object({
        playbackId: z.string(),
        trackId: z
            .string()
            .describe(
                "Legacy identifier of the track; clients use `playbackId`.",
            ),
        ...preferenceFields,
    })
    .meta({ id: "TrackPreferenceResponse" });

/** Path parameter of `POST /api/library/albums/{id}/preference`. */
export const AlbumPreferenceParams = z.object({
    id: z.string().describe("Album id or release-group MBID"),
});

/** Body of `POST /api/library/albums/{id}/preference`. */
export const AlbumPreferenceRequest = z
    .object({ signal: PreferenceSignal })
    .meta({ id: "AlbumPreferenceRequest" });

/** The preference applied to every library track of an album. */
export const AlbumPreferenceResponse = z
    .object({
        albumId: z.string(),
        trackCount: z
            .number()
            .int()
            .describe("Library tracks the signal was applied to"),
        ...preferenceFields,
    })
    .meta({ id: "AlbumPreferenceResponse" });
