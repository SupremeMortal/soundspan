jest.mock("../../middleware/auth", () => ({
    requireAuth: (req: any, _res: any, next: () => void) => {
        req.user = { id: "u1", username: "u1", role: "user" };
        next();
    },
}));

jest.mock("../../utils/logger", () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));

const prisma = {
    userSettings: { findUnique: jest.fn() },
    cachedTrack: { aggregate: jest.fn() },
};
jest.mock("../../utils/db", () => ({ prisma }));

const mockResolveOfflineItems = jest.fn();

jest.mock("../../services/offline/offlinePolicy", () => ({
    resolveOfflinePolicy: jest.fn(),
}));

jest.mock("../../services/offline/resolveOfflineItems", () => {
    class OfflineItemsError extends Error {
        constructor(
            readonly status: number,
            readonly code: string,
            message: string,
        ) {
            super(message);
        }
    }
    return {
        OfflineItemsError,
        resolveOfflineItems: (...args: unknown[]) =>
            mockResolveOfflineItems(...args),
    };
});

import router from "../offline";
import { OfflineItemsError } from "../../services/offline/resolveOfflineItems";

const MB = 1024 * 1024;
const DEVICE = "6f1d2c9e-8a3b-4c57-9d0e-1b2a3c4d5e6f";

function getHandler(method: "post", path: string) {
    const layer = (router as any).stack.find(
        (entry: any) =>
            entry.route?.path === path && entry.route?.methods?.[method],
    );
    if (!layer) throw new Error(`Route not found: ${method} ${path}`);
    return layer.route.stack[layer.route.stack.length - 1].handle;
}

function createRes() {
    const res: any = {
        statusCode: 200,
        body: undefined as unknown,
        status: jest.fn((code: number) => {
            res.statusCode = code;
            return res;
        }),
        json: jest.fn((payload: unknown) => {
            res.body = payload;
            return res;
        }),
    };
    return res;
}

const item = (playbackId: string, expectedSize: number) => ({
    playbackId,
    downloadable: true,
    downloadUrl: `/api/playback/stream/${playbackId}?quality=high`,
    expectedSize,
    quality: "high",
    contentType: "audio/mpeg",
});

describe("POST /api/offline/items", () => {
    const post = getHandler("post", "/items");

    beforeEach(() => {
        jest.clearAllMocks();
        prisma.userSettings.findUnique.mockResolvedValue({
            maxCacheSizeMb: 100,
        });
        prisma.cachedTrack.aggregate.mockResolvedValue({
            _sum: { fileSizeMb: 10 },
        });
    });

    it.each(["track", "album", "playlist"])(
        "resolves a %s request and reports cache numbers",
        async (kind) => {
            const id = kind === "track" ? "t.abc" : "x1";
            mockResolveOfflineItems.mockResolvedValue({
                items: [item("t.abc", 5 * MB)],
                estimatedTotalBytes: 5 * MB,
            });
            const res = createRes();
            await post(
                {
                    user: { id: "u1" },
                    body: { kind, id, deviceId: DEVICE, quality: "high" },
                },
                res,
            );

            expect(mockResolveOfflineItems).toHaveBeenCalledWith({
                userId: "u1",
                kind,
                id,
                quality: "high",
            });
            expect(res.statusCode).toBe(200);
            expect(res.body).toEqual({
                items: [item("t.abc", 5 * MB)],
                estimatedTotalBytes: 5 * MB,
                cacheLimitBytes: 100 * MB,
                cacheUsedBytes: 10 * MB,
            });
        },
    );

    it("counts every device of the user toward the used total", async () => {
        mockResolveOfflineItems.mockResolvedValue({
            items: [],
            estimatedTotalBytes: 0,
        });
        await post(
            {
                user: { id: "u1" },
                body: { kind: "track", id: "t.a", deviceId: DEVICE },
            },
            createRes(),
        );
        expect(prisma.cachedTrack.aggregate).toHaveBeenCalledWith({
            where: { userId: "u1" },
            _sum: { fileSizeMb: true },
        });
    });

    it("answers 409 CACHE_LIMIT_EXCEEDED when used plus estimate is over the limit", async () => {
        mockResolveOfflineItems.mockResolvedValue({
            items: [item("t.a", 95 * MB)],
            estimatedTotalBytes: 95 * MB,
        });
        const res = createRes();
        await post(
            {
                user: { id: "u1" },
                body: { kind: "track", id: "t.a", deviceId: DEVICE },
            },
            res,
        );
        expect(res.statusCode).toBe(409);
        expect(res.body).toMatchObject({
            code: "CACHE_LIMIT_EXCEEDED",
            cacheLimitBytes: 100 * MB,
            cacheUsedBytes: 10 * MB,
            estimatedTotalBytes: 95 * MB,
        });
    });

    it("allows a request that lands exactly on the limit", async () => {
        mockResolveOfflineItems.mockResolvedValue({
            items: [],
            estimatedTotalBytes: 90 * MB,
        });
        const res = createRes();
        await post(
            {
                user: { id: "u1" },
                body: { kind: "album", id: "a1", deviceId: DEVICE },
            },
            res,
        );
        expect(res.statusCode).toBe(200);
    });

    it.each([
        ["bad kind", { kind: "artist", id: "x", deviceId: DEVICE }],
        ["missing id", { kind: "track", deviceId: DEVICE }],
        ["missing deviceId", { kind: "track", id: "t.a" }],
        ["non-UUID deviceId", { kind: "track", id: "t.a", deviceId: "phone" }],
        [
            "bad quality",
            { kind: "track", id: "t.a", deviceId: DEVICE, quality: "ultra" },
        ],
    ])("rejects %s with 400 INVALID_REQUEST", async (_name, body) => {
        const res = createRes();
        await post({ user: { id: "u1" }, body }, res);
        expect(res.statusCode).toBe(400);
        expect(res.body).toMatchObject({ code: "INVALID_REQUEST" });
        expect(mockResolveOfflineItems).not.toHaveBeenCalled();
    });

    it.each([
        [400, "INVALID_PLAYBACK_ID"],
        [404, "ALBUM_NOT_FOUND"],
        [404, "PLAYLIST_NOT_FOUND"],
    ] as const)("maps resolver error %s %s", async (status, code) => {
        mockResolveOfflineItems.mockRejectedValue(
            new OfflineItemsError(status, code, "nope"),
        );
        const res = createRes();
        await post(
            {
                user: { id: "u1" },
                body: { kind: "track", id: "t.a", deviceId: DEVICE },
            },
            res,
        );
        expect(res.statusCode).toBe(status);
        expect(res.body).toMatchObject({ code });
    });

    it("answers 500 for an unexpected failure", async () => {
        mockResolveOfflineItems.mockRejectedValue(new Error("boom"));
        const res = createRes();
        await post(
            {
                user: { id: "u1" },
                body: { kind: "track", id: "t.a", deviceId: DEVICE },
            },
            res,
        );
        expect(res.statusCode).toBe(500);
    });
});
