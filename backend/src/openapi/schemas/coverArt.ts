import { z } from "zod";

/**
 * Query of `GET /api/library/cover-art[/{id}]`. `size` is snapped to 64, 128,
 * 192, 320, 512 or 768; without it the original image is sent. `url` names
 * the image when there is no id.
 */
export const CoverArtQuery = z.object({
    size: z.number().int().optional(),
    url: z.string().optional(),
});
