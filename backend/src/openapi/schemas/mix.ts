import { z } from "zod";
import { TrackSummary } from "./track";

/**
 * A generated mix. `type` names the generator (for example `era`, `genre`,
 * `top-tracks`, `mood`); clients must tolerate types added later. `coverUrls`
 * holds up to four album covers for a mosaic; `color` is a CSS background.
 */
export const MixSummary = z
    .object({
        id: z.string(),
        type: z.string(),
        name: z.string(),
        description: z.string(),
        trackIds: z.array(z.string()),
        coverUrls: z.array(z.string()),
        trackCount: z.number().int(),
        color: z.string(),
    })
    .meta({ id: "MixSummary" });

/**
 * A generated mix with its tracks, in mix order. A track id of `trackIds`
 * that is no longer visible in the library has no entry in `tracks`.
 */
export const MixDetail = MixSummary.extend({
    tracks: z.array(TrackSummary),
}).meta({ id: "MixDetail" });

/** Path parameters of `GET /api/mixes/{id}`. */
export const MixIdParams = z.object({
    id: z.string().describe('Mix id, for example "era-2000" or "top-tracks".'),
});
