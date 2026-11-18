import { prisma } from "../utils/db";
import { TRACK_VISIBLE_WHERE } from "../utils/librarySorting";
import {
    resolveTrackPreference,
    normalizeTrackPreferenceSignal,
    TRACK_DISLIKE_ENTITY_TYPE,
    type ResolvedTrackPreference,
    type TrackPreferenceState,
} from "./trackPreference";
import type { UnifiedTrackResponse } from "./unifiedTrackResponse";

export const formatTrackPreferenceResponse = (
    trackId: string,
    preference: ResolvedTrackPreference,
) => ({
    trackId,
    signal: preference.signal,
    state: preference.state,
    score: preference.score,
    likedAt: preference.likedAt ? preference.likedAt.toISOString() : null,
    dislikedAt: preference.dislikedAt
        ? preference.dislikedAt.toISOString()
        : null,
    updatedAt: preference.updatedAt ? preference.updatedAt.toISOString() : null,
});

export type NormalizedTrackPreferenceSignal = Exclude<
    ReturnType<typeof normalizeTrackPreferenceSignal>,
    null
>;

export const formatAlbumPreferenceResponse = (
    albumId: string,
    trackCount: number,
    preference: ResolvedTrackPreference,
) => ({
    albumId,
    trackCount,
    signal: preference.signal,
    state: preference.state,
    score: preference.score,
    likedAt: preference.likedAt ? preference.likedAt.toISOString() : null,
    dislikedAt: preference.dislikedAt
        ? preference.dislikedAt.toISOString()
        : null,
    updatedAt: preference.updatedAt ? preference.updatedAt.toISOString() : null,
});

export const hasConnectedProviderToken = (
    value: string | null | undefined,
): boolean => typeof value === "string" && value.trim().length > 0;

export const toLikedResponseTrack = (
    normalized: UnifiedTrackResponse,
    likedAt: Date,
) => {
    const likedAtIso = likedAt.toISOString();
    const base = {
        id: normalized.id,
        ...(normalized.playbackId ? { playbackId: normalized.playbackId } : {}),
        title: normalized.title,
        duration: normalized.duration,
        trackNo: normalized.trackNo,
        filePath: normalized.filePath ?? null,
        likedAt: likedAtIso,
        source: normalized.source,
        provider: normalized.provider,
        artist: normalized.artist,
        album: normalized.album,
    };

    if (normalized.source === "tidal") {
        return {
            ...base,
            streamSource: "tidal" as const,
            tidalTrackId: normalized.provider.tidalTrackId,
        };
    }

    if (normalized.source === "youtube") {
        return {
            ...base,
            streamSource: "youtube" as const,
            youtubeVideoId: normalized.provider.youtubeVideoId,
        };
    }

    if (normalized.source === "federated") {
        return { ...base, streamSource: "peer" as const };
    }

    return base;
};

export const applyTrackPreferenceSignalToTrackIds = async (
    tx: {
        likedTrack: {
            deleteMany: typeof prisma.likedTrack.deleteMany;
            createMany: typeof prisma.likedTrack.createMany;
        };
        dislikedEntity: {
            deleteMany: typeof prisma.dislikedEntity.deleteMany;
            createMany: typeof prisma.dislikedEntity.createMany;
        };
    },
    userId: string,
    trackIds: string[],
    signal: NormalizedTrackPreferenceSignal,
    now: Date,
) => {
    if (trackIds.length === 0) {
        return;
    }

    if (signal === "thumbs_up") {
        await tx.dislikedEntity.deleteMany({
            where: {
                userId,
                entityType: TRACK_DISLIKE_ENTITY_TYPE,
                entityId: { in: trackIds },
            },
        });
        await tx.likedTrack.deleteMany({
            where: {
                userId,
                trackId: { in: trackIds },
            },
        });
        await tx.likedTrack.createMany({
            data: trackIds.map((trackId) => ({
                userId,
                trackId,
                likedAt: now,
            })),
            skipDuplicates: true,
        });
        return;
    }

    if (signal === "thumbs_down") {
        await tx.likedTrack.deleteMany({
            where: {
                userId,
                trackId: { in: trackIds },
            },
        });
        await tx.dislikedEntity.deleteMany({
            where: {
                userId,
                entityType: TRACK_DISLIKE_ENTITY_TYPE,
                entityId: { in: trackIds },
            },
        });
        await tx.dislikedEntity.createMany({
            data: trackIds.map((trackId) => ({
                userId,
                entityType: TRACK_DISLIKE_ENTITY_TYPE,
                entityId: trackId,
                dislikedAt: now,
            })),
            skipDuplicates: true,
        });
        return;
    }

    await tx.likedTrack.deleteMany({
        where: {
            userId,
            trackId: { in: trackIds },
        },
    });
    await tx.dislikedEntity.deleteMany({
        where: {
            userId,
            entityType: TRACK_DISLIKE_ENTITY_TYPE,
            entityId: { in: trackIds },
        },
    });
};

/** Loads per-track preference scores through the supplied database client. */
export const buildTrackPreferenceScoreMapForUser = async (
    userId: string | undefined,
    trackIds: string[],
    client: Pick<typeof prisma, "likedTrack" | "dislikedEntity"> = prisma,
): Promise<Map<string, number>> => {
    if (!userId || trackIds.length === 0) {
        return new Map<string, number>();
    }

    const uniqueTrackIds = Array.from(
        new Set(
            trackIds.filter(
                (trackId): trackId is string =>
                    typeof trackId === "string" && trackId.length > 0,
            ),
        ),
    );
    if (uniqueTrackIds.length === 0) {
        return new Map<string, number>();
    }

    const [likedEntries, dislikedEntries] = await Promise.all([
        client.likedTrack.findMany({
            where: {
                userId,
                trackId: { in: uniqueTrackIds },
            },
            select: {
                trackId: true,
                likedAt: true,
            },
        }),
        client.dislikedEntity.findMany({
            where: {
                userId,
                entityType: TRACK_DISLIKE_ENTITY_TYPE,
                entityId: { in: uniqueTrackIds },
            },
            select: {
                entityId: true,
                dislikedAt: true,
            },
        }),
    ]);

    const likedByTrackId = new Map<string, Date>();
    for (const entry of likedEntries) {
        likedByTrackId.set(entry.trackId, entry.likedAt);
    }

    const dislikedByTrackId = new Map<string, Date>();
    for (const entry of dislikedEntries) {
        dislikedByTrackId.set(entry.entityId, entry.dislikedAt);
    }

    const scoreMap = new Map<string, number>();
    for (const trackId of uniqueTrackIds) {
        const preference = resolveTrackPreference({
            likedAt: likedByTrackId.get(trackId) ?? null,
            dislikedAt: dislikedByTrackId.get(trackId) ?? null,
        });
        if (preference.score !== 0) {
            scoreMap.set(trackId, preference.score);
        }
    }

    return scoreMap;
};

/**
 * Resolves one user's preference for each album from the preferences of its
 * visible library tracks, the store `POST /library/albums/:id/preference`
 * writes: `liked` when every track is liked, `disliked` when every track is
 * disliked, and `neutral` otherwise, including albums with no library tracks.
 */
export const loadAlbumPreferenceStatesForUser = async (
    userId: string,
    albumIds: string[],
    client: Pick<
        typeof prisma,
        "track" | "likedTrack" | "dislikedEntity"
    > = prisma,
): Promise<Map<string, TrackPreferenceState>> => {
    const uniqueAlbumIds = Array.from(
        new Set(albumIds.filter((albumId) => albumId.length > 0)),
    );
    const states = new Map<string, TrackPreferenceState>(
        uniqueAlbumIds.map((albumId) => [albumId, "neutral"]),
    );
    if (uniqueAlbumIds.length === 0) {
        return states;
    }

    const tracks = await client.track.findMany({
        where: { albumId: { in: uniqueAlbumIds }, ...TRACK_VISIBLE_WHERE },
        select: { id: true, albumId: true },
    });
    const scores = await buildTrackPreferenceScoreMapForUser(
        userId,
        tracks.map((track) => track.id),
        client,
    );

    const scoresByAlbumId = new Map<string, number[]>();
    for (const track of tracks) {
        const albumScores = scoresByAlbumId.get(track.albumId) ?? [];
        albumScores.push(scores.get(track.id) ?? 0);
        scoresByAlbumId.set(track.albumId, albumScores);
    }
    for (const [albumId, albumScores] of scoresByAlbumId) {
        if (albumScores.every((score) => score > 0)) {
            states.set(albumId, "liked");
        } else if (albumScores.every((score) => score < 0)) {
            states.set(albumId, "disliked");
        }
    }
    return states;
};
