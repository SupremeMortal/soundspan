import { withLibraryTrackPlayback } from "../federatedTrackPayload";
import { parsePlaybackId } from "../playback/playbackId";

describe("federated track playback payload", () => {
    it("adds peer stream source and persisted health provenance", () => {
        expect(
            withLibraryTrackPlayback(
                { id: "track-1", origin: "FEDERATED" },
                {
                    id: "peer-1",
                    name: "Peer One",
                    outboundStatus: "ACTIVE",
                },
            ),
        ).toEqual({
            id: "track-1",
            playbackId: "t.track-1",
            origin: "FEDERATED",
            source: "federated",
            streamSource: "peer",
            peer: { id: "peer-1", name: "Peer One", online: true },
        });
    });

    it("emits a parseable playbackId consistent with the track id", () => {
        const payload = withLibraryTrackPlayback(
            { id: "ckfed1", origin: "FEDERATED" },
            { id: "p", name: "P", outboundStatus: null },
        );
        expect(parsePlaybackId(payload.playbackId as string)).toEqual({
            kind: "t",
            trackId: "ckfed1",
        });
    });

    it("emits playbackId for a federated track whose peer is unknown", () => {
        const payload = withLibraryTrackPlayback(
            { id: "ckfed2", origin: "FEDERATED" },
            null,
        );
        expect(payload.playbackId).toBe("t.ckfed2");
        expect("streamSource" in payload).toBe(false);
    });

    it("emits playbackId for a local track without peer provenance", () => {
        const payload = withLibraryTrackPlayback(
            { id: "ckloc", origin: "LOCAL" },
            null,
        );
        expect(payload).toEqual({
            id: "ckloc",
            origin: "LOCAL",
            playbackId: "t.ckloc",
        });
        expect(parsePlaybackId(payload.playbackId)).toEqual({
            kind: "t",
            trackId: "ckloc",
        });
    });

    it("ignores a peer on a local track", () => {
        const payload = withLibraryTrackPlayback(
            { id: "ckloc2", origin: "LOCAL" },
            { id: "p", name: "P", outboundStatus: "ACTIVE" },
        );
        expect(payload).toEqual({
            id: "ckloc2",
            origin: "LOCAL",
            playbackId: "t.ckloc2",
        });
    });
});
