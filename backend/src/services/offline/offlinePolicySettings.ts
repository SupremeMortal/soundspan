import { z } from "zod";

/** System-settings payload fields for the per-source offline download switches. */
export const offlinePolicyFields = {
    offlineAllowLocal: z.boolean().optional(),
    offlineAllowFederated: z.boolean().optional(),
    offlineAllowTidal: z.boolean().optional(),
    offlineAllowYtMusic: z.boolean().optional(),
    offlineAllowYouTube: z.boolean().optional(),
};
