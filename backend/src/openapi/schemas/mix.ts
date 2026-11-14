import { z } from "zod";

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
