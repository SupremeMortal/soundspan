jest.mock("../../utils/db", () => ({ prisma: {} }));

import { toLikedResponseTrack } from "../libraryTrackPreferences";
import { parsePlaybackId } from "../playback/playbackId";
import type { UnifiedTrackResponse } from "../unifiedTrackResponse";

const base = (overrides: Partial<UnifiedTrackResponse>) =>
    ({
        id: "x",
        title: "T",
        duration: 1,
        trackNo: 1,
        filePath: null,
        source: "local",
        provider: {},
        artist: { id: "a", name: "A" },
        album: { id: "b", title: "B" },
        ...overrides,
    }) as unknown as UnifiedTrackResponse;

const likedAt = new Date("2026-01-01T00:00:00.000Z");

describe("toLikedResponseTrack playbackId", () => {
    it("carries a local track's playbackId", () => {
        const out = toLikedResponseTrack(
            base({ id: "ck1", playbackId: "t.ck1" }),
            likedAt,
        );
        expect(parsePlaybackId(out.playbackId as string)).toEqual({
            kind: "t",
            trackId: out.id,
        });
    });

    it("carries a TIDAL track's playbackId", () => {
        const out = toLikedResponseTrack(
            base({
                id: "tidal:42",
                source: "tidal",
                playbackId: "td.42",
                provider: { tidalTrackId: 42 },
            } as Partial<UnifiedTrackResponse>),
            likedAt,
        );
        expect(out.playbackId).toBe("td.42");
        expect(out).toMatchObject({ tidalTrackId: 42 });
    });

    it("carries a YT Music track's playbackId", () => {
        const out = toLikedResponseTrack(
            base({
                id: "yt:vid1",
                source: "youtube",
                playbackId: "ym.vid1",
                provider: { youtubeVideoId: "vid1" },
            } as Partial<UnifiedTrackResponse>),
            likedAt,
        );
        expect(out.playbackId).toBe("ym.vid1");
    });

    it("carries a federated track's playbackId", () => {
        const out = toLikedResponseTrack(
            base({ id: "ckf", source: "federated", playbackId: "t.ckf" }),
            likedAt,
        );
        expect(out.playbackId).toBe("t.ckf");
        expect(out).toMatchObject({ streamSource: "peer" });
    });

    it("omits playbackId when the source has none", () => {
        const out = toLikedResponseTrack(
            base({
                id: "tidal:missing:r",
                source: "tidal",
            } as Partial<UnifiedTrackResponse>),
            likedAt,
        );
        expect("playbackId" in out).toBe(false);
    });
});
