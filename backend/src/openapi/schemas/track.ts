import { z } from "zod";
import { PeerRef } from "./common";

/** An artist as embedded in a track; Last.fm-only tracks carry no `id`. */
export const TrackArtistRef = z
    .object({
        id: z.string().optional(),
        name: z.string(),
    })
    .meta({ id: "TrackArtistRef" });

/** An artist reference with its library id. */
export const ArtistRef = z
    .object({
        id: z.string(),
        name: z.string(),
        mbid: z.string().nullable().optional(),
    })
    .meta({ id: "ArtistRef" });

/** The album a track belongs to; a track not in the library has no `id`. */
export const TrackAlbumRef = z
    .object({
        id: z.string().optional(),
        title: z.string(),
        coverArt: z.string().nullable().optional(),
        coverUrl: z.string().nullable().optional(),
        albumLoudnessLufs: z.number().nullable().optional(),
        albumTruePeakDb: z.number().nullable().optional(),
        artist: ArtistRef.optional(),
    })
    .meta({ id: "TrackAlbumRef" });

/**
 * A track row as embedded in album and artist detail. `playbackId` is absent
 * when the track cannot be played (no stream source).
 */
export const TrackSummary = z
    .object({
        id: z.string(),
        title: z.string(),
        duration: z.number().int(),
        trackNo: z.number().int().nullable().optional(),
        discNo: z.number().int().optional(),
        playbackId: z.string().optional(),
        albumId: z.string().optional(),
        isrc: z.string().nullable().optional(),
        loudnessLufs: z.number().nullable().optional(),
        truePeakDb: z.number().nullable().optional(),
        artist: TrackArtistRef.optional(),
        album: TrackAlbumRef.optional(),
        peer: PeerRef.optional(),
    })
    .meta({ id: "TrackSummary" });
