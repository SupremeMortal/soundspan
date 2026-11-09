const mockGetStreamFilePath = jest.fn();
const mockStreamWithRange = jest.fn();

jest.mock("../../services/audioStreaming", () => ({
    AudioStreamingService: jest.fn().mockImplementation(() => ({
        getStreamFilePath: (...a: unknown[]) => mockGetStreamFilePath(...a),
        streamFileWithRangeSupport: (...a: unknown[]) =>
            mockStreamWithRange(...a),
        destroy: jest.fn(),
    })),
}));
jest.mock("../../config", () => ({
    config: {
        music: {
            musicPath: "/music",
            transcodeCachePath: "/cache",
            transcodeCacheMaxGb: 1,
        },
    },
}));
jest.mock("../../utils/logger", () => {
    const l: any = {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    };
    l.child = () => l;
    return { logger: l };
});

import { serveNativeLibraryTrack } from "../library/libraryNativeTrackStream";

const track: any = {
    id: "track-1",
    filePath: "Artist/song.flac",
    fileModified: new Date(0),
};
const req: any = { headers: {} };
const res: any = {};

describe("serveNativeLibraryTrack validators", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockGetStreamFilePath.mockResolvedValue({
            filePath: "/cache/medium.mp3",
            mimeType: "audio/mpeg",
        });
    });

    it("keeps the per-source call shape when no playbackId is given", async () => {
        await serveNativeLibraryTrack({
            req,
            res,
            track,
            requestedQuality: "medium",
        });
        expect(mockStreamWithRange).toHaveBeenCalledWith(
            req,
            res,
            "/cache/medium.mp3",
            "audio/mpeg",
        );
    });

    it("pins the variant to the file actually served when a playbackId is given", async () => {
        await serveNativeLibraryTrack({
            req,
            res,
            track,
            requestedQuality: "medium",
            playbackId: "t.track-1",
        });
        expect(mockStreamWithRange).toHaveBeenCalledWith(
            req,
            res,
            "/cache/medium.mp3",
            "audio/mpeg",
            undefined,
            { playbackId: "t.track-1", variant: "/cache/medium.mp3" },
        );
    });
});
