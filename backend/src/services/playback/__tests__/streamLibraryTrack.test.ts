const mockTrackFindUnique = jest.fn();
const mockPlayFindFirst = jest.fn();
const mockPlayCreate = jest.fn();
const mockUserSettingsFindUnique = jest.fn();
const mockLoadPeer = jest.fn();
const mockApplyFallback = jest.fn();
const mockProxyPeer = jest.fn();
const mockServeNative = jest.fn();

jest.mock("../../../utils/db", () => ({
    prisma: {
        track: { findUnique: (...a: unknown[]) => mockTrackFindUnique(...a) },
        play: {
            findFirst: (...a: unknown[]) => mockPlayFindFirst(...a),
            create: (...a: unknown[]) => mockPlayCreate(...a),
        },
        userSettings: {
            findUnique: (...a: unknown[]) => mockUserSettingsFindUnique(...a),
        },
    },
}));
jest.mock("../../../config", () => ({
    config: { features: { federation: true } },
}));
jest.mock("../../../utils/logger", () => {
    const l: any = {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    };
    l.child = () => l;
    return { logger: l };
});
jest.mock("../../../routes/library/federationStreamPeer", () => ({
    loadActiveFederationStreamPeer: (...a: unknown[]) => mockLoadPeer(...a),
}));
jest.mock("../../../routes/library/libraryPeerStream", () => ({
    applyLibraryPeerFallback: (...a: unknown[]) => mockApplyFallback(...a),
    proxyLibraryPeerStream: (...a: unknown[]) => mockProxyPeer(...a),
}));
jest.mock("../../../routes/library/libraryNativeTrackStream", () => ({
    serveNativeLibraryTrack: (...a: unknown[]) => mockServeNative(...a),
}));

import { streamLibraryTrack } from "../streamLibraryTrack";

function createRes() {
    const res: any = { statusCode: 200, body: undefined };
    res.status = (code: number) => {
        res.statusCode = code;
        return res;
    };
    res.json = (body: unknown) => {
        res.body = body;
        return res;
    };
    return res;
}

const req = { headers: {} } as any;

const nativeTrack = (over: Record<string, unknown> = {}) => ({
    id: "track-1",
    title: "Song",
    origin: "LOCAL",
    peerId: null,
    remoteId: null,
    filePath: "a.mp3",
    fileModified: new Date(0),
    mime: "audio/mpeg",
    ...over,
});

describe("streamLibraryTrack", () => {
    beforeEach(() => {
        jest.resetAllMocks();
        mockTrackFindUnique.mockResolvedValue(nativeTrack());
        mockPlayFindFirst.mockResolvedValue(null);
        mockPlayCreate.mockResolvedValue({ id: "p" });
        mockUserSettingsFindUnique.mockResolvedValue({
            playbackQuality: "high",
        });
        mockLoadPeer.mockResolvedValue(null);
    });

    it("responds 404 for a missing track without recording a play", async () => {
        mockTrackFindUnique.mockResolvedValue(null);
        const res = createRes();
        await streamLibraryTrack({
            userId: "u1",
            trackId: "x",
            quality: undefined,
            req,
            res,
        });
        expect(res.statusCode).toBe(404);
        expect(res.body).toEqual({ error: "Track not found" });
        expect(mockPlayCreate).not.toHaveBeenCalled();
        expect(mockServeNative).not.toHaveBeenCalled();
    });

    it("records a play and serves the native file at the requested quality", async () => {
        const res = createRes();
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res,
        });
        expect(mockPlayCreate).toHaveBeenCalledWith({
            data: { userId: "u1", trackId: "track-1" },
        });
        expect(mockServeNative).toHaveBeenCalledWith(
            expect.objectContaining({
                req,
                res,
                requestedQuality: "low",
                track: expect.objectContaining({ id: "track-1" }),
            }),
        );
        expect(mockUserSettingsFindUnique).not.toHaveBeenCalled();
    });

    it("passes the playbackId through so the native stream can send an ETag", async () => {
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res: createRes(),
            playbackId: "t.track-1",
        });
        expect(mockServeNative).toHaveBeenCalledWith(
            expect.objectContaining({ playbackId: "t.track-1" }),
        );
    });

    it("falls back to the user's playback quality preference", async () => {
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: undefined,
            req,
            res: createRes(),
        });
        expect(mockServeNative).toHaveBeenCalledWith(
            expect.objectContaining({ requestedQuality: "high" }),
        );
    });

    it("does not record a duplicate play within 30 seconds", async () => {
        mockPlayFindFirst.mockResolvedValue({ id: "recent" });
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res: createRes(),
        });
        expect(mockPlayCreate).not.toHaveBeenCalled();
        expect(mockServeNative).toHaveBeenCalled();
    });

    it("stops after the peer proxy serves a federated track", async () => {
        mockTrackFindUnique.mockResolvedValue(
            nativeTrack({ origin: "FEDERATED", peerId: "p1", remoteId: "r1" }),
        );
        mockLoadPeer.mockResolvedValue({ id: "p1" });
        mockProxyPeer.mockResolvedValue(true);
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res: createRes(),
        });
        expect(mockProxyPeer).toHaveBeenCalledWith(
            expect.objectContaining({
                remoteId: "r1",
                requestedQuality: "low",
            }),
        );
        expect(mockServeNative).not.toHaveBeenCalled();
        expect(mockApplyFallback).not.toHaveBeenCalled();
    });

    it("serves the local twin when the peer proxy cannot serve", async () => {
        mockTrackFindUnique.mockResolvedValue(
            nativeTrack({ origin: "FEDERATED", peerId: "p1", remoteId: "r1" }),
        );
        mockLoadPeer.mockResolvedValue({ id: "p1" });
        mockProxyPeer.mockResolvedValue(false);
        mockApplyFallback.mockResolvedValue(nativeTrack({ id: "twin" }));
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res: createRes(),
        });
        expect(mockServeNative).toHaveBeenCalledWith(
            expect.objectContaining({
                track: expect.objectContaining({ id: "twin" }),
            }),
        );
    });

    it("stops when the fallback already served a provider stream", async () => {
        mockTrackFindUnique.mockResolvedValue(
            nativeTrack({ origin: "FEDERATED", peerId: "p1", remoteId: null }),
        );
        mockApplyFallback.mockResolvedValue(null);
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res: createRes(),
        });
        expect(mockPlayCreate).not.toHaveBeenCalled();
        expect(mockServeNative).not.toHaveBeenCalled();
    });

    describe("recordPlay", () => {
        it("records no play and still serves the file when recordPlay is false", async () => {
            const res = createRes();
            await streamLibraryTrack({
                userId: "u1",
                trackId: "track-1",
                quality: "low",
                req,
                res,
                recordPlay: false,
            });
            expect(mockPlayFindFirst).not.toHaveBeenCalled();
            expect(mockPlayCreate).not.toHaveBeenCalled();
            expect(mockServeNative).toHaveBeenCalledWith(
                expect.objectContaining({
                    requestedQuality: "low",
                    track: expect.objectContaining({ id: "track-1" }),
                }),
            );
        });

        it.each([
            ["omitted", undefined],
            ["true", true],
        ])(
            "records one play when recordPlay is %s and none exists in the last 30 seconds",
            async (_label, recordPlay) => {
                await streamLibraryTrack({
                    userId: "u1",
                    trackId: "track-1",
                    quality: "low",
                    req,
                    res: createRes(),
                    ...(recordPlay === undefined ? {} : { recordPlay }),
                });
                expect(mockPlayCreate).toHaveBeenCalledTimes(1);
                expect(mockPlayCreate).toHaveBeenCalledWith({
                    data: { userId: "u1", trackId: "track-1" },
                });
            },
        );

        it("records no play when the federated peer serves and recordPlay is false", async () => {
            mockTrackFindUnique.mockResolvedValue(
                nativeTrack({
                    origin: "FEDERATED",
                    peerId: "p1",
                    remoteId: "r1",
                }),
            );
            mockLoadPeer.mockResolvedValue({ id: "p1" });
            mockProxyPeer.mockResolvedValue(true);
            await streamLibraryTrack({
                userId: "u1",
                trackId: "track-1",
                quality: "low",
                req,
                res: createRes(),
                recordPlay: false,
            });
            expect(mockProxyPeer).toHaveBeenCalled();
            expect(mockPlayCreate).not.toHaveBeenCalled();
        });

        it("records no play when a fallback twin serves and recordPlay is false", async () => {
            mockTrackFindUnique.mockResolvedValue(
                nativeTrack({
                    origin: "FEDERATED",
                    peerId: "p1",
                    remoteId: null,
                }),
            );
            mockApplyFallback.mockResolvedValue(nativeTrack({ id: "twin" }));
            await streamLibraryTrack({
                userId: "u1",
                trackId: "track-1",
                quality: "low",
                req,
                res: createRes(),
                recordPlay: false,
            });
            expect(mockServeNative).toHaveBeenCalledWith(
                expect.objectContaining({
                    track: expect.objectContaining({ id: "twin" }),
                }),
            );
            expect(mockPlayCreate).not.toHaveBeenCalled();
        });
    });

    it("responds 500 when a lookup throws", async () => {
        mockTrackFindUnique.mockRejectedValue(new Error("db down"));
        const res = createRes();
        await streamLibraryTrack({
            userId: "u1",
            trackId: "track-1",
            quality: "low",
            req,
            res,
        });
        expect(res.statusCode).toBe(500);
        expect(res.body).toEqual({ error: "Failed to stream track" });
    });
});
