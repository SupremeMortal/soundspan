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

/** The federation peer a federated artist, album or track comes from. */
export const PeerRef = z
    .object({
        id: z.string(),
        name: z.string(),
        online: z.boolean(),
    })
    .meta({ id: "PeerRef" });

/** Streaming providers a remote (liked TIDAL / YouTube Music) row comes from. */
export const RemoteProvider = z
    .enum(["tidal", "youtube"])
    .meta({ id: "RemoteProvider" });

/**
 * The `origin` query filter of library lists: local files, federated peers,
 * or liked TIDAL / YouTube Music tracks that are not in the library.
 */
export const LibraryOriginQuery = z.enum(["all", "local", "peers", "remote"]);
