jest.mock("../../../utils/db", () => ({ prisma: {} }));

import {
    formatLibraryTrackRow,
    type LibraryTrackRow,
} from "../libraryTrackRows";
import { parsePlaybackId } from "../../playback/playbackId";

function row(origin: "LOCAL" | "FEDERATED"): LibraryTrackRow {
    return {
        id: "ckz0track",
        origin,
        title: "Song",
        album: { id: "alb", coverUrl: null, artist: { id: "a", name: "A" } },
        federationPeer: null,
    } as unknown as LibraryTrackRow;
}

describe("formatLibraryTrackRow playbackId", () => {
    it.each(["LOCAL", "FEDERATED"] as const)(
        "emits a parseable t.* playbackId for %s rows",
        (origin) => {
            const formatted = formatLibraryTrackRow(row(origin));
            expect(formatted.playbackId).toBe("t.ckz0track");
            expect(parsePlaybackId(formatted.playbackId)).toEqual({
                kind: "t",
                trackId: "ckz0track",
            });
        },
    );
});
