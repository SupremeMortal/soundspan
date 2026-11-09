import { tryEncodePlaybackId } from "./playback/playbackId";

/** Adds a `td.` playbackId to every TIDAL browse track and tags the source. */
export function withTidalPlaybackIds<
    T extends { tracks: Array<{ trackId: number }> },
>(detail: T) {
    return {
        ...detail,
        tracks: detail.tracks.map((track) => ({
            ...track,
            playbackId: tryEncodePlaybackId({
                kind: "td",
                tidalId: track.trackId,
            }),
        })),
        source: "tidal" as const,
    };
}

/** Adds a `ym.` playbackId to every YT Music browse track and tags the source. */
export function withYtMusicPlaybackIds<
    T extends { tracks: Array<{ videoId: string }> },
>(detail: T) {
    return {
        ...detail,
        tracks: detail.tracks.map((track) => ({
            ...track,
            playbackId: tryEncodePlaybackId({
                kind: "ym",
                videoId: track.videoId,
            }),
        })),
        source: "ytmusic" as const,
    };
}

interface YtMusicBrowseAlbum {
    title: string;
    artist: string;
    year: string | null;
    trackCount: number | null;
    coverUrl: string | null;
    tracks: Array<{
        videoId: string;
        title: string;
        artist: string;
        artists: string[];
        duration_seconds: number | null;
    }>;
}

/**
 * Normalizes a YT Music album to the YtMusicBrowsePlaylist shape so the
 * frontend detail page can render it without knowing whether it is an album
 * or a playlist.
 */
export function toYtMusicBrowseAlbum(id: string, album: YtMusicBrowseAlbum) {
    const description = [album.artist, album.year].filter(Boolean).join(" · ");
    return {
        ...withYtMusicPlaybackIds({
            id,
            title: album.title,
            description,
            trackCount: album.trackCount ?? album.tracks.length,
            thumbnailUrl: album.coverUrl,
            tracks: album.tracks.map((t) => ({
                videoId: t.videoId,
                title: t.title,
                artist: t.artist,
                artists: t.artists,
                album: album.title ?? "",
                duration: t.duration_seconds ?? 0,
                thumbnailUrl: album.coverUrl,
            })),
        }),
        type: "album" as const,
    };
}
