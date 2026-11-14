import { z } from "zod";

/** The shared error envelope every route error response uses. */
export const ApiError = z
    .object({ error: z.string(), code: z.string().optional() })
    .meta({ id: "ApiError" });

/** Error statuses every authenticated operation can return. */
export const standardErrors = {
    401: ApiError,
    500: ApiError,
    503: ApiError,
} as const;
