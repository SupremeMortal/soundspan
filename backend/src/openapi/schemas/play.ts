import { z } from "zod";

/**
 * Display metadata a client sends with a track that may not be stored yet.
 * Read only when a TIDAL or YouTube Music track row must be created.
 */
export const PlaybackMetadata = z
    .object({
        title: z.string().trim().min(1),
        artist: z.string().trim().min(1),
        album: z.string().trim().min(1),
        durationSec: z.number().int().nonnegative(),
        artworkUrl: z.string().trim().min(1).optional(),
        isrc: z.string().trim().min(1).optional(),
    })
    .meta({ id: "PlaybackMetadata" });

/** Body of `POST /api/plays` in its `playbackId` form. */
export const RecordPlayRequest = z
    .object({
        playbackId: z
            .string()
            .min(1)
            .describe("Opaque track identifier. Do not parse."),
        metadata: PlaybackMetadata.optional(),
        playedAt: z.iso
            .datetime()
            .optional()
            .describe(
                "ISO-8601 UTC instant (Z suffix) the play began, from 14 days ago to 5 minutes ahead of the server clock. Absent means the current time.",
            ),
        listenedMs: z
            .number()
            .int()
            .min(0)
            .max(86_400_000)
            .optional()
            .describe(
                "Total time the track was audibly playing, in milliseconds; may exceed the track's duration. Below 5000 the play is not recorded. Absent means not measured.",
            ),
    })
    .meta({ id: "RecordPlayRequest" });

/** A recorded play. */
export const PlayRecord = z
    .object({
        id: z.string(),
        playedAt: z.iso.datetime(),
        source: z.enum([
            "LIBRARY",
            "DISCOVERY",
            "DISCOVERY_KEPT",
            "TIDAL",
            "YOUTUBE_MUSIC",
        ]),
        listenedMs: z
            .number()
            .int()
            .nullable()
            .describe("Audible time in milliseconds; null when not measured"),
    })
    .meta({ id: "PlayRecord" });

/** The answer for a play below the minimum listen: nothing was recorded. */
export const PlayNotRecorded = z
    .object({ recorded: z.literal(false) })
    .meta({ id: "PlayNotRecorded" });
