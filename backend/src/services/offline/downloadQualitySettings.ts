import { z } from "zod";

/** System-settings payload fields for the admin download source qualities. */
export const downloadQualityFields = {
    tidalQuality: z
        .enum(["LOW", "HIGH", "LOSSLESS", "HI_RES_LOSSLESS"])
        .optional(),
    ytMusicQuality: z.enum(["LOW", "MEDIUM", "HIGH", "LOSSLESS"]).optional(),
};
