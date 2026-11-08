import {
    formatUnifiedTrackItem,
    normalizeLocalTrack,
    normalizeTidalTrack,
    normalizeYtMusicTrack,
} from "../unifiedTrackResponse";
import { parsePlaybackId } from "../playback/playbackId";

describe("unifiedTrackResponse", () => {
    it("normalizes local tracks into canonical unified shape", () => {
        const result = normalizeLocalTrack({
            id: "track-1",
            title: "Local Song",
            duration: 180,
            trackNo: 3,
            loudnessLufs: -17.4,
            truePeakDb: -1.2,
            filePath: "/music/local-song.flac",
            displayTitle: "Local Song (Deluxe)",
            album: {
                id: "album-1",
                title: "Local Album",
                coverUrl: "native:albums/a1.jpg",
                albumLoudnessLufs: -18.1,
                albumTruePeakDb: -0.8,
                artist: {
                    id: "artist-1",
                    name: "Local Artist",
                    mbid: "mbid-artist-1",
                },
            },
        });

        expect(result).toEqual({
            id: "track-1",
            playbackId: "t.track-1",
            title: "Local Song",
            duration: 180,
            trackNo: 3,
            loudnessLufs: -17.4,
            truePeakDb: -1.2,
            artist: {
                id: "artist-1",
                name: "Local Artist",
            },
            album: {
                id: "album-1",
                title: "Local Album",
                coverArt: "native:albums/a1.jpg",
                albumLoudnessLufs: -18.1,
                albumTruePeakDb: -0.8,
            },
            source: "local",
            provider: {
                tidalTrackId: null,
                youtubeVideoId: null,
            },
            filePath: "/music/local-song.flac",
            displayTitle: "Local Song (Deluxe)",
        });
    });

    it("normalizes federated tracks with peer provenance and online status", () => {
        const result = normalizeLocalTrack({
            id: "fed-track-1",
            title: "Federated Song",
            duration: 181,
            trackNo: 4,
            loudnessLufs: null,
            truePeakDb: null,
            origin: "FEDERATED",
            album: {
                id: "fed-album-1",
                title: "Federated Album",
                coverUrl: null,
                albumLoudnessLufs: null,
                albumTruePeakDb: null,
                artist: { id: "fed-artist-1", name: "Remote Artist" },
            },
            federationPeer: {
                id: "peer-1",
                name: "Peer One",
                outboundStatus: "ACTIVE",
            },
        });

        expect(result).toEqual({
            id: "fed-track-1",
            playbackId: "t.fed-track-1",
            title: "Federated Song",
            duration: 181,
            trackNo: 4,
            loudnessLufs: null,
            truePeakDb: null,
            artist: { id: "fed-artist-1", name: "Remote Artist" },
            album: {
                id: "fed-album-1",
                title: "Federated Album",
                coverArt: null,
                albumLoudnessLufs: null,
                albumTruePeakDb: null,
            },
            source: "federated",
            peer: { id: "peer-1", name: "Peer One", online: true },
            provider: { tidalTrackId: null, youtubeVideoId: null },
            displayTitle: null,
        });
    });

    it("normalizes tidal tracks into canonical unified shape", () => {
        const result = normalizeTidalTrack({
            id: "tt-1",
            tidalId: 991,
            title: "Tidal Song",
            artist: "Tidal Artist",
            album: "Tidal Album",
            duration: 245,
        });

        expect(result).toEqual({
            id: "tidal:991",
            playbackId: "td.991",
            title: "Tidal Song",
            duration: 245,
            trackNo: null,
            artist: {
                id: null,
                name: "Tidal Artist",
            },
            album: {
                id: null,
                title: "Tidal Album",
                coverArt: null,
            },
            source: "tidal",
            provider: {
                tidalTrackId: 991,
                youtubeVideoId: null,
            },
        });
    });

    it("normalizes youtube tracks into canonical unified shape", () => {
        const result = normalizeYtMusicTrack({
            id: "yt-1",
            videoId: "yt-video-7",
            title: "YT Song",
            artist: "YT Artist",
            album: "YT Album",
            duration: 199,
            thumbnailUrl: "https://yt/thumb.jpg",
        });

        expect(result).toEqual({
            id: "yt:yt-video-7",
            playbackId: "ym.yt-video-7",
            title: "YT Song",
            duration: 199,
            trackNo: null,
            artist: {
                id: null,
                name: "YT Artist",
            },
            album: {
                id: null,
                title: "YT Album",
                coverArt: "https://yt/thumb.jpg",
            },
            source: "youtube",
            provider: {
                tidalTrackId: null,
                youtubeVideoId: "yt-video-7",
            },
        });
    });

    it("formats local playlist items with compatibility wrapper", () => {
        const result = formatUnifiedTrackItem({
            id: "pli-local-1",
            playlistId: "pl-1",
            trackId: "track-1",
            trackTidalId: null,
            trackYtMusicId: null,
            sort: 1,
            track: {
                id: "track-1",
                title: "Local Song",
                duration: 180,
                album: {
                    title: "Local Album",
                    coverUrl: "native:albums/a1.jpg",
                    artist: {
                        id: "artist-1",
                        name: "Local Artist",
                    },
                },
            },
            trackTidal: null,
            trackYtMusic: null,
        });

        expect(result.provider.source).toBe("local");
        expect(result.playback.isPlayable).toBe(true);
        expect(result.track).toMatchObject({
            id: "track-1",
            source: "local",
            album: {
                title: "Local Album",
                coverArt: "native:albums/a1.jpg",
                artist: {
                    id: "artist-1",
                    name: "Local Artist",
                },
            },
        });
    });

    it("formats remote playlist items with compatibility wrapper and playback status", () => {
        const tidal = formatUnifiedTrackItem({
            id: "pli-tidal-1",
            playlistId: "pl-1",
            trackId: null,
            trackTidalId: "tt-1",
            trackYtMusicId: null,
            sort: 2,
            track: null,
            trackTidal: {
                id: "tt-1",
                tidalId: 991,
                title: "Tidal Song",
                artist: "Tidal Artist",
                album: "Tidal Album",
                duration: 245,
            },
            trackYtMusic: null,
        });
        expect(tidal.provider.source).toBe("tidal");
        expect(tidal.playback.isPlayable).toBe(true);
        expect(tidal.track).toMatchObject({
            id: "tidal:991",
            streamSource: "tidal",
            tidalTrackId: 991,
        });

        const youtubeMissingId = formatUnifiedTrackItem({
            id: "pli-yt-missing",
            playlistId: "pl-1",
            trackId: null,
            trackTidalId: null,
            trackYtMusicId: "yt-1",
            sort: 3,
            track: null,
            trackTidal: null,
            trackYtMusic: {
                id: "yt-1",
                videoId: "   ",
                title: "YT Unknown",
                artist: "Unknown Artist",
                album: "Unknown Album",
                duration: 200,
                thumbnailUrl: null,
            },
        });
        expect(youtubeMissingId.provider.source).toBe("youtube");
        expect(youtubeMissingId.playback.isPlayable).toBe(false);
        expect(youtubeMissingId.playback.reason).toBe(
            "missing_youtube_video_id",
        );
    });

    it("marks an offline federated playlist track unplayable", () => {
        const result = formatUnifiedTrackItem({
            id: "pli-fed-1",
            playlistId: "pl-1",
            trackId: "fed-track-1",
            trackTidalId: null,
            trackYtMusicId: null,
            sort: 4,
            track: {
                id: "fed-track-1",
                title: "Federated Song",
                duration: 181,
                origin: "FEDERATED",
                federationPeer: {
                    id: "peer-1",
                    name: "Peer One",
                    outboundStatus: "OFFLINE",
                },
                album: {
                    title: "Federated Album",
                    artist: { name: "Remote Artist" },
                },
            },
            trackTidal: null,
            trackYtMusic: null,
        });

        expect(result.provider).toMatchObject({
            source: "federated",
            label: "FEDERATED",
        });
        expect(result.playback).toEqual({
            isPlayable: false,
            reason: "peer_offline",
            message: "Playback is unavailable while Peer One is offline.",
        });
        expect(result.track).toMatchObject({
            source: "federated",
            streamSource: "peer",
            peer: { id: "peer-1", name: "Peer One", online: false },
        });
    });

    describe("playbackId emission", () => {
        const localRecord = {
            id: "ckabc123",
            title: "Local Song",
            duration: 180,
            album: { title: "A", artist: { name: "B" } },
        };

        it("emits t.<Track.id> for local and federated tracks", () => {
            const local = normalizeLocalTrack(localRecord);
            expect(parsePlaybackId(local.playbackId!)).toEqual({
                kind: "t",
                trackId: local.id,
            });

            const federated = normalizeLocalTrack({
                ...localRecord,
                id: "fed1",
                origin: "FEDERATED",
                federationPeer: {
                    id: "peer-1",
                    name: "Peer",
                    outboundStatus: "ACTIVE",
                },
            });
            expect(federated.source).toBe("federated");
            expect(parsePlaybackId(federated.playbackId!)).toEqual({
                kind: "t",
                trackId: "fed1",
            });
        });

        it("emits td.<tidalId>, using the external id rather than the row id", () => {
            const result = normalizeTidalTrack({
                id: "row-cuid",
                tidalId: 991,
                title: "T",
                artist: "A",
                album: "B",
                duration: 1,
            });
            expect(parsePlaybackId(result.playbackId!)).toEqual({
                kind: "td",
                tidalId: result.provider.tidalTrackId,
            });
        });

        it("omits playbackId for a TIDAL row without a valid tidal id", () => {
            const result = normalizeTidalTrack({
                id: "row-cuid",
                tidalId: 0,
                title: "T",
                artist: "A",
                album: "B",
                duration: 1,
            });
            expect(result.playbackId).toBeUndefined();
        });

        it("emits ym.<videoId>, using the external id rather than the row id", () => {
            const result = normalizeYtMusicTrack({
                id: "row-cuid",
                videoId: " vid_1-x ",
                title: "T",
                artist: "A",
                album: "B",
                duration: 1,
            });
            expect(parsePlaybackId(result.playbackId!)).toEqual({
                kind: "ym",
                videoId: result.provider.youtubeVideoId,
            });
        });

        it("omits playbackId for a YT Music row without a video id", () => {
            const result = normalizeYtMusicTrack({
                id: "row-cuid",
                videoId: "  ",
                title: "T",
                artist: "A",
                album: "B",
                duration: 1,
            });
            expect(result.playbackId).toBeUndefined();
        });

        it("carries playbackId into playlist items of every source", () => {
            const base = {
                id: "pli",
                playlistId: "pl",
                sort: 1,
                trackId: null,
                trackTidalId: null,
                trackYtMusicId: null,
                track: null,
                trackTidal: null,
                trackYtMusic: null,
            };
            const local = formatUnifiedTrackItem({
                ...base,
                trackId: "ckabc123",
                track: localRecord,
            });
            expect(
                parsePlaybackId(String(local.track?.playbackId)),
            ).toEqual({ kind: "t", trackId: local.track?.id });

            const tidal = formatUnifiedTrackItem({
                ...base,
                trackTidalId: "tt",
                trackTidal: {
                    id: "tt",
                    tidalId: 42,
                    title: "T",
                    artist: "A",
                    album: "B",
                    duration: 1,
                },
            });
            expect(
                parsePlaybackId(String(tidal.track?.playbackId)),
            ).toEqual({ kind: "td", tidalId: tidal.track?.tidalTrackId });

            const yt = formatUnifiedTrackItem({
                ...base,
                trackYtMusicId: "yy",
                trackYtMusic: {
                    id: "yy",
                    videoId: "vid9",
                    title: "T",
                    artist: "A",
                    album: "B",
                    duration: 1,
                },
            });
            expect(parsePlaybackId(String(yt.track?.playbackId))).toEqual({
                kind: "ym",
                videoId: yt.track?.youtubeVideoId,
            });
            expect(yt.track?.streamSource).toBe("youtube");
        });
    });
});
