import { parsePlaybackId } from "../playbackId";
import { derivePlaybackIdFromStoredItem } from "../storedPlaybackId";

describe("derivePlaybackIdFromStoredItem", () => {
    it("maps a local item to a t. id", () => {
        const id = derivePlaybackIdFromStoredItem({ id: "ckabc123" });
        expect(id).toBe("t.ckabc123");
        expect(parsePlaybackId(id!)).toEqual({
            kind: "t",
            trackId: "ckabc123",
        });
    });

    it("maps a peer item to a t. id", () => {
        expect(
            derivePlaybackIdFromStoredItem({
                id: "ckpeer1",
                streamSource: "peer",
            }),
        ).toBe("t.ckpeer1");
    });

    it("maps a TIDAL item to a td. id from tidalTrackId", () => {
        expect(
            derivePlaybackIdFromStoredItem({
                id: "tidal:99",
                streamSource: "tidal",
                tidalTrackId: 99,
            }),
        ).toBe("td.99");
    });

    it("reads the TIDAL id from the provider object", () => {
        expect(
            derivePlaybackIdFromStoredItem({
                id: "tidal:5",
                provider: { source: "tidal", tidalTrackId: 5 },
            }),
        ).toBe("td.5");
    });

    it("maps a YouTube Music item to ym. and youtube-direct to yt.", () => {
        expect(
            derivePlaybackIdFromStoredItem({
                id: "yt:abc",
                streamSource: "youtube",
                youtubeVideoId: "abc",
            }),
        ).toBe("ym.abc");
        expect(
            derivePlaybackIdFromStoredItem({
                id: "yt:abc",
                streamSource: "youtube-direct",
                youtubeVideoId: "abc",
            }),
        ).toBe("yt.abc");
    });

    it("returns undefined when the identity is unusable", () => {
        expect(derivePlaybackIdFromStoredItem({ id: "" })).toBeUndefined();
        expect(
            derivePlaybackIdFromStoredItem({ id: "bad id!" }),
        ).toBeUndefined();
        expect(
            derivePlaybackIdFromStoredItem({ id: "x", streamSource: "tidal" }),
        ).toBeUndefined();
        expect(
            derivePlaybackIdFromStoredItem({
                id: "x",
                streamSource: "youtube",
            }),
        ).toBeUndefined();
    });
});
