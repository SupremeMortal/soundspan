import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import { MixSummary } from "../schemas/mix";

/** Home and discovery operations. */
export const discoveryOperations = [
    defineOperation({
        method: "get",
        path: "/api/mixes",
        operationId: "listMixes",
        tag: "discovery",
        summary: "The user's generated mixes",
        description:
            "Cached for an hour per user. 404 with code `FEATURE_DISABLED` when automatic playlists are turned off.",
        responses: {
            200: z.array(MixSummary),
            404: ApiError,
            ...standardErrors,
        },
    }),
];
