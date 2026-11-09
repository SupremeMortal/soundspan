import * as crypto from "crypto";

/** What identifies the exact bytes a unified stream response serves. */
export interface PlaybackEtagInput {
    playbackId: string;
    /** Opaque identifier of the exact file or encoding served. */
    variant: string;
    /** Size in bytes of the full body, not of a requested range. */
    contentLength: number;
}

/**
 * Strong ETag for one `(playbackId, variant, contentLength)`. Equal tags mean
 * byte-identical bodies, so a client can resume a download with `Range` plus
 * `If-Range`.
 */
export function buildPlaybackEtag(input: PlaybackEtagInput): string {
    const digest = crypto
        .createHash("sha256")
        .update(
            JSON.stringify([
                input.playbackId,
                input.variant,
                input.contentLength,
            ]),
        )
        .digest("hex")
        .slice(0, 32);
    return `"${digest}"`;
}

/**
 * Whether a `Range` request may be honoured given its `If-Range` header.
 * Without the header the range always applies. With it, only an exact match
 * of the current strong ETag does: a stale tag, a weak tag, or a date (the
 * server sends no `Last-Modified`) means the client gets the full body.
 */
export function ifRangeAllowsRange(
    ifRange: string | undefined,
    currentEtag: string,
): boolean {
    if (ifRange === undefined) return true;
    return ifRange.trim() === currentEtag;
}
