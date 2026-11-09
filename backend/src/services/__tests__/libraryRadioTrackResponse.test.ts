import { transformRadioTrack } from "../libraryRadioTrackResponse";
import { parsePlaybackId } from "../playback/playbackId";

const row = {
    id: "ckradio1",
    title: "Song",
    duration: 200,
    trackNo: 1,
    filePath: "a/b.flac",
    loudnessLufs: -9,
    truePeakDb: -1,
    album: {
        id: "alb1",
        title: "Album",
        coverUrl: null,
        albumLoudnessLufs: null,
        albumTruePeakDb: null,
        artist: { id: "art1", name: "Artist" },
    },
};

describe("transformRadioTrack playbackId", () => {
    it("emits a parseable t.<id> playbackId matching the legacy id", () => {
        const payload = transformRadioTrack(row, null);
        expect(payload.playbackId).toBe("t.ckradio1");
        expect(parsePlaybackId(payload.playbackId)).toEqual({
            kind: "t",
            trackId: payload.id,
        });
    });
});
