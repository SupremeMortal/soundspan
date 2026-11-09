import { z } from "zod";

/** System-settings payload field for the admin offline-download switch. */
export const offlinePolicyFields = {
    offlineDownloadsEnabled: z.boolean().optional(),
};
