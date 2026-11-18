import { toSearchTrackPayload } from "../searchPayloads";
import type { TrackSearchResult } from "../search";

function track(overrides: Partial<TrackSearchResult> = {}): TrackSearchResult {
    return {
        id: "track-1",
        title: "pacifico",
        albumId: "album-1",
        albumTitle: "portals//polarities",
        artistId: "artist-1",
        artistName: "Night Tapes",
        duration: 210,
        rank: 1,
        ...overrides,
    };
}

describe("toSearchTrackPayload", () => {
    it("emits the album cover on a library track", () => {
        const payload = toSearchTrackPayload(
            track({ albumCoverUrl: "native:albums/album-1.jpg" }),
        );

        expect(payload.album.coverUrl).toBe("native:albums/album-1.jpg");
    });

    it("emits a null cover when the album has none", () => {
        expect(toSearchTrackPayload(track()).album.coverUrl).toBeNull();
        expect(
            toSearchTrackPayload(track({ albumCoverUrl: null })).album.coverUrl,
        ).toBeNull();
    });
});
