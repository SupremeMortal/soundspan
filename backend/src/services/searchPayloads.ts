import { tryEncodePlaybackId } from "./playback/playbackId";
import type {
    AlbumSearchResult,
    ArtistSearchResult,
    TrackSearchResult,
} from "./search";

/** A library artist in the response shape of `SearchArtist`. */
export function toSearchArtistPayload(artist: ArtistSearchResult) {
    const { matchedBy: _matchedBy, ...payload } = artist;
    return payload;
}

/** A library album in the response shape of `SearchAlbum`. */
export function toSearchAlbumPayload(album: AlbumSearchResult) {
    return {
        id: album.id,
        title: album.title,
        artistId: album.artistId,
        year: album.year,
        coverUrl: album.coverUrl,
        source: album.source,
        peer: album.peer,
        artist: {
            id: album.artistId,
            name: album.artistName,
            mbid: "",
        },
    };
}

/** A library track in the response shape of `SearchTrack`. */
export function toSearchTrackPayload(track: TrackSearchResult) {
    return {
        id: track.id,
        playbackId: tryEncodePlaybackId({ kind: "t", trackId: track.id }),
        title: track.title,
        albumId: track.albumId,
        duration: track.duration,
        trackNo: 0,
        loudnessLufs: track.loudnessLufs ?? null,
        truePeakDb: track.truePeakDb ?? null,
        source: track.source,
        peer: track.peer,
        album: {
            id: track.albumId,
            title: track.albumTitle,
            artistId: track.artistId,
            coverUrl: track.albumCoverUrl ?? null,
            albumLoudnessLufs: track.albumLoudnessLufs ?? null,
            albumTruePeakDb: track.albumTruePeakDb ?? null,
            artist: {
                id: track.artistId,
                name: track.artistName,
                mbid: "",
            },
        },
    };
}
