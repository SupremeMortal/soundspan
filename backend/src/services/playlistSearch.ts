import { prisma } from "../utils/db";
import { TRACK_VISIBLE_WHERE } from "../utils/librarySorting";
import { escapeLikePattern } from "../utils/likePattern";
import {
    RADIO_PLAYLIST_MIX_ID_PREFIX,
    standardPlaylistListWhere,
} from "./radioPlaylistIdentity";

/** Cover seeds per playlist, as in the playlist list. */
const PLAYLIST_PREVIEW_ITEMS = 12;

/** A playlist in the shape of the playlist list (`PlaylistSummary`). */
export interface PlaylistSearchSummary {
    id: string;
    userId: string;
    name: string;
    isPublic: boolean;
    createdAt: Date;
    updatedAt: Date;
    user: { username: string };
    isOwner: boolean;
    isHidden: boolean;
    trackCount: number;
    items: Array<{
        id: string;
        track: { album: { coverArt: string | null } } | null;
    }>;
}

/** A playlist matching a search, with its trigram similarity to the query. */
export interface PlaylistSearchHit {
    playlist: PlaylistSearchSummary;
    similarity: number;
}

/**
 * Searches playlist names the user can see (their own and public ones, not
 * ephemeral radio playlists) by `ILIKE` substring or the pg_trgm `%`
 * operator, best `similarity` first.
 */
export async function searchPlaylists(input: {
    userId: string;
    query: string;
    limit: number;
    offset: number;
}): Promise<PlaylistSearchHit[]> {
    const query = input.query.trim();
    if (!query || input.limit < 1) return [];
    const pattern = `%${escapeLikePattern(query)}%`;
    const radioPattern = `${escapeLikePattern(RADIO_PLAYLIST_MIX_ID_PREFIX)}%`;
    const rows = await prisma.$queryRaw<
        Array<{ id: string; similarity: number }>
    >`
        SELECT p.id, similarity(p.name, ${query})::float8 AS similarity
        FROM "Playlist" p
        WHERE (p."userId" = ${input.userId} OR p."isPublic" = true)
          AND (p."mixId" IS NULL OR p."mixId" NOT LIKE ${radioPattern} ESCAPE '\\')
          AND (p.name ILIKE ${pattern} ESCAPE '\\' OR p.name % ${query})
        ORDER BY similarity DESC, p.name ASC, p.id ASC
        LIMIT ${input.limit}
        OFFSET ${input.offset}
    `;
    if (rows.length === 0) return [];

    const playlists = await prisma.playlist.findMany({
        where: {
            AND: [
                { id: { in: rows.map((row) => row.id) } },
                standardPlaylistListWhere(input.userId),
            ],
        },
        include: {
            user: { select: { username: true } },
            hiddenByUsers: {
                where: { userId: input.userId },
                select: { id: true },
            },
            _count: { select: { items: true } },
            items: {
                where: {
                    OR: [{ trackId: null }, { track: TRACK_VISIBLE_WHERE }],
                },
                select: {
                    id: true,
                    track: {
                        select: { album: { select: { coverUrl: true } } },
                    },
                },
                orderBy: { sort: "asc" },
                take: PLAYLIST_PREVIEW_ITEMS,
            },
        },
    });
    const byId = new Map(playlists.map((playlist) => [playlist.id, playlist]));

    return rows.flatMap((row) => {
        const playlist = byId.get(row.id);
        if (!playlist) return [];
        return [
            {
                similarity: Number(row.similarity) || 0,
                playlist: {
                    id: playlist.id,
                    userId: playlist.userId,
                    name: playlist.name,
                    isPublic: playlist.isPublic,
                    createdAt: playlist.createdAt,
                    updatedAt: playlist.updatedAt,
                    user: { username: playlist.user.username },
                    isOwner: playlist.userId === input.userId,
                    isHidden: playlist.hiddenByUsers.length > 0,
                    trackCount: playlist._count.items,
                    items: playlist.items.map((item) => ({
                        id: item.id,
                        track: item.track
                            ? {
                                  album: {
                                      coverArt: item.track.album.coverUrl,
                                  },
                              }
                            : null,
                    })),
                },
            },
        ];
    });
}
