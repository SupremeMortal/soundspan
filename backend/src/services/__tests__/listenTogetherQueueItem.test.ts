import {
    withQueueItemPlaybackId,
    type SyncQueueItem,
} from "../listenTogetherQueueItem";
import { parsePlaybackId } from "../playback/playbackId";

function item(overrides: Partial<SyncQueueItem>): SyncQueueItem {
    return {
        id: "x",
        title: "Song",
        duration: 100,
        artist: { id: "ar", name: "Artist" },
        album: { id: "al", title: "Album", coverArt: null },
        ...overrides,
    };
}

describe("withQueueItemPlaybackId", () => {
    it("derives t.<id> for a local item", () => {
        const out = withQueueItemPlaybackId(
            item({ id: "ckz1", localTrackId: "ckz1", streamSource: undefined }),
        );
        expect(out.playbackId).toBe("t.ckz1");
    });

    it("derives t.<id> for a peer item", () => {
        const out = withQueueItemPlaybackId(
            item({ id: "ckz2", localTrackId: "ckz2", streamSource: "peer" }),
        );
        expect(out.playbackId).toBe("t.ckz2");
    });

    it("derives td.<id> for a TIDAL item", () => {
        const out = withQueueItemPlaybackId(
            item({
                id: "tidal:123",
                streamSource: "tidal",
                tidalTrackId: 123,
            }),
        );
        expect(out.playbackId).toBe("td.123");
    });

    it("derives ym.<videoId> for a YouTube Music item", () => {
        const out = withQueueItemPlaybackId(
            item({
                id: "yt:abc_DEF-1",
                streamSource: "youtube",
                youtubeVideoId: "abc_DEF-1",
            }),
        );
        expect(out.playbackId).toBe("ym.abc_DEF-1");
    });

    it("derives yt.<videoId> for a youtube-direct item", () => {
        const out = withQueueItemPlaybackId(
            item({
                id: "yt:abc_DEF-1",
                streamSource: "youtube-direct",
                youtubeVideoId: "abc_DEF-1",
            }),
        );
        expect(out.playbackId).toBe("yt.abc_DEF-1");
    });

    it("derives the id for a stored item that never carried playbackId", () => {
        const stored = JSON.parse(
            JSON.stringify(item({ id: "ckz3", localTrackId: "ckz3" })),
        ) as SyncQueueItem;
        expect(stored.playbackId).toBeUndefined();
        const out = withQueueItemPlaybackId(stored);
        expect(parsePlaybackId(out.playbackId!)).toEqual({
            kind: "t",
            trackId: "ckz3",
        });
    });

    it("keeps all other fields and does not mutate the input", () => {
        const input = item({ id: "ckz4", localTrackId: "ckz4" });
        const out = withQueueItemPlaybackId(input);
        expect(out).toEqual({ ...input, playbackId: "t.ckz4" });
        expect(input.playbackId).toBeUndefined();
    });

    it("omits playbackId when no usable identity exists", () => {
        const out = withQueueItemPlaybackId(
            item({ id: "bad id!", streamSource: "tidal" }),
        );
        expect(out.playbackId).toBeUndefined();
    });
});
