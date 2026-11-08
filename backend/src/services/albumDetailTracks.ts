import { prisma, Prisma } from "../utils/db";
import { encodePlaybackId } from "./playback/playbackId";
import { collapseProviderDuplicateSets } from "./remoteLibrary";

/** Remote-album track filters: the rows a user has liked, plus the detail-page variants. */
export function buildRemoteAlbumTrackWheres(userId: string | undefined) {
    const likedTidal: Prisma.TrackTidalWhereInput = userId
        ? { likedBy: { some: { userId } } }
        : { id: { in: [] } };
    const likedYt: Prisma.TrackYtMusicWhereInput = userId
        ? { likedBy: { some: { userId } } }
        : { id: { in: [] } };
    return {
        likedTidal,
        likedYt,
        includedTidal: {
            ...likedTidal,
            albumEntity: { is: { location: "REMOTE" as const } },
        },
        includedYt: {
            ...likedYt,
            albumEntity: { is: { location: "REMOTE" as const } },
        },
    };
}

/** The album-detail lookup: id or release-group MBID with at least one visible track. */
export function buildAlbumDetailWhere(
    id: string,
    browseTrackWhere: Prisma.TrackWhereInput,
    likedTidal: Prisma.TrackTidalWhereInput,
    likedYt: Prisma.TrackYtMusicWhereInput,
): Prisma.AlbumWhereInput {
    return {
        AND: [
            { OR: [{ id }, { rgMbid: id }] },
            {
                OR: [
                    { tracks: { some: browseTrackWhere } },
                    {
                        location: "REMOTE",
                        tracksTidal: { some: likedTidal },
                    },
                    {
                        location: "REMOTE",
                        tracksYtMusic: { some: likedYt },
                    },
                ],
            },
        ],
    };
}

/** Loads an album with its visible local tracks and the included remote tracks. */
export async function findAlbumWithTracks(
    where: Prisma.AlbumWhereInput,
    browseTrackWhere: Prisma.TrackWhereInput,
    tidalTrackWhere: Prisma.TrackTidalWhereInput,
    ytTrackWhere: Prisma.TrackYtMusicWhereInput,
) {
    return prisma.album.findFirst({
        where,
        include: {
            artist: { select: { id: true, mbid: true, name: true } },
            federationPeer: {
                select: { id: true, name: true, outboundStatus: true },
            },
            tracks: {
                where: browseTrackWhere,
                include: {
                    federationPeer: {
                        select: {
                            id: true,
                            name: true,
                            outboundStatus: true,
                        },
                    },
                },
                orderBy: [
                    { discNo: Prisma.SortOrder.asc },
                    { trackNo: Prisma.SortOrder.asc },
                ],
            },
            tracksTidal: {
                where: tidalTrackWhere,
                include: {
                    mappings: {
                        where: { stale: false },
                        select: { id: true, trackId: true },
                    },
                },
                orderBy: { title: Prisma.SortOrder.asc },
            },
            tracksYtMusic: {
                where: ytTrackWhere,
                include: {
                    mappings: {
                        where: { stale: false },
                        select: { id: true, trackId: true },
                    },
                },
                orderBy: { title: Prisma.SortOrder.asc },
            },
        },
    });
}

/** An album as returned by {@link findAlbumWithTracks}. */
export type AlbumWithTracks = NonNullable<
    Awaited<ReturnType<typeof findAlbumWithTracks>>
>;

function formatLocalAlbumTracks(album: AlbumWithTracks) {
    return album.tracks.map(({ federationPeer, ...track }) => ({
        ...track,
        playbackId: encodePlaybackId({ kind: "t", trackId: track.id }),
        ...(track.origin === "FEDERATED" && federationPeer
            ? {
                  source: "federated" as const,
                  streamSource: "peer" as const,
                  peer: {
                      id: federationPeer.id,
                      name: federationPeer.name,
                      online: federationPeer.outboundStatus === "ACTIVE",
                  },
              }
            : {}),
    }));
}

function formatTidalAlbumTracks(album: AlbumWithTracks) {
    return album.tracksTidal.map((track) => ({
        id: `tidal:${track.tidalId}`,
        playbackId: encodePlaybackId({ kind: "td", tidalId: track.tidalId }),
        title: track.title,
        duration: track.duration,
        trackNo: null,
        artist: {
            id: track.artistId ?? album.artist.id,
            name: track.artist || album.artist.name,
        },
        album: {
            id: album.id,
            title: track.album || album.title,
            coverArt: album.coverUrl,
            artist: album.artist,
        },
        source: "tidal" as const,
        streamSource: "tidal" as const,
        tidalTrackId: track.tidalId,
        provider: {
            tidalTrackId: track.tidalId,
            youtubeVideoId: null,
        },
    }));
}

function formatYtAlbumTracks(album: AlbumWithTracks) {
    return album.tracksYtMusic.map((track) => ({
        id: `yt:${track.videoId}`,
        playbackId: encodePlaybackId({ kind: "ym", videoId: track.videoId }),
        title: track.title,
        duration: track.duration,
        trackNo: null,
        artist: {
            id: track.artistId ?? album.artist.id,
            name: track.artist || album.artist.name,
        },
        album: {
            id: album.id,
            title: track.album || album.title,
            coverArt: track.thumbnailUrl ?? album.coverUrl,
            artist: album.artist,
        },
        source: "youtube" as const,
        streamSource: "youtube" as const,
        youtubeVideoId: track.videoId,
        thumbnailUrl: track.thumbnailUrl ?? undefined,
        provider: {
            tidalTrackId: null,
            youtubeVideoId: track.videoId,
        },
    }));
}

function formatRemoteAlbumTracks(album: AlbumWithTracks) {
    const unique = collapseProviderDuplicateSets(
        album.tracksTidal,
        album.tracksYtMusic,
        "tidal",
    );
    return [
        ...formatTidalAlbumTracks({ ...album, tracksTidal: unique.tidalRows }),
        ...formatYtAlbumTracks({ ...album, tracksYtMusic: unique.youtubeRows }),
    ];
}

/** The album's tracks in detail-page order, each with its `playbackId`. */
export function formatAlbumTracks(album: AlbumWithTracks | null) {
    if (!album) return [];
    const localTracks = formatLocalAlbumTracks(album);
    if (album.location !== "REMOTE") return localTracks;
    return [...localTracks, ...formatRemoteAlbumTracks(album)];
}
