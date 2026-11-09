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

type Row = {
    id: string;
    userId: string;
    deviceId: string | null;
    playbackId: string;
    trackId: string | null;
    localPath: string;
    quality: string;
    fileSizeMb: number;
    lastAccessedAt: Date;
};

let rows: Row[] = [];
let nextId = 1;

function matches(row: Row, where: any): boolean {
    if (where.userId !== undefined && row.userId !== where.userId) return false;
    if (where.deviceId !== undefined && row.deviceId !== where.deviceId) {
        return false;
    }
    if (where.playbackId !== undefined) {
        if (typeof where.playbackId === "string") {
            if (row.playbackId !== where.playbackId) return false;
        } else if (!where.playbackId.in.includes(row.playbackId)) {
            return false;
        }
    }
    return true;
}

const prisma = {
    userSettings: { findUnique: jest.fn() },
    track: { findFirst: jest.fn(), findUnique: jest.fn() },
    album: { findUnique: jest.fn() },
    cachedTrack: {
        findFirst: jest.fn(
            async ({ where }: any) =>
                rows.find((r) => matches(r, where)) ?? null,
        ),
        findMany: jest.fn(async ({ where }: any) =>
            rows.filter((r) => matches(r, where)),
        ),
        create: jest.fn(async ({ data }: any) => {
            const row = {
                id: `c${nextId++}`,
                lastAccessedAt: new Date(),
                ...data,
            };
            rows.push(row);
            return row;
        }),
        update: jest.fn(async ({ where, data }: any) => {
            const row = rows.find((r) => r.id === where.id)!;
            Object.assign(row, data);
            return row;
        }),
        deleteMany: jest.fn(async ({ where }: any) => {
            const before = rows.length;
            rows = rows.filter((r) => !matches(r, where));
            return { count: before - rows.length };
        }),
        aggregate: jest.fn(async ({ where }: any) => {
            const matched = rows.filter((r) => matches(r, where));
            return {
                _sum: {
                    fileSizeMb: matched.reduce((s, r) => s + r.fileSizeMb, 0),
                },
                _count: matched.length,
            };
        }),
    },
};
jest.mock("../../utils/db", () => ({ prisma }));

const mockResolveOfflinePolicy = jest.fn();
jest.mock("../../services/offline/offlinePolicy", () => ({
    resolveOfflinePolicy: (...args: unknown[]) =>
        mockResolveOfflinePolicy(...args),
}));

jest.mock("../../services/offline/resolveOfflineItems", () => ({
    OfflineItemsError: class OfflineItemsError extends Error {},
    resolveOfflineItems: jest.fn(),
}));

import router from "../offline";

const MB = 1024 * 1024;
const DEV_A = "6f1d2c9e-8a3b-4c57-9d0e-1b2a3c4d5e6f";
const DEV_B = "7a2e3d0f-9b4c-4d68-8e1f-2c3b4d5e6f70";

function getHandler(method: "get" | "post" | "delete", path: string) {
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

async function call(handler: any, req: { body?: unknown; query?: unknown }) {
    const res = createRes();
    await handler({ user: { id: "u1" }, body: {}, query: {}, ...req }, res);
    return res;
}

const complete = getHandler("post", "/items/complete");
const remove = getHandler("delete", "/items");
const list = getHandler("get", "/items");
const stats = getHandler("get", "/stats");

beforeEach(() => {
    jest.clearAllMocks();
    rows = [];
    nextId = 1;
    prisma.userSettings.findUnique.mockResolvedValue({ maxCacheSizeMb: 100 });
    prisma.track.findUnique.mockResolvedValue({ id: "abc" });
    mockResolveOfflinePolicy.mockResolvedValue({ downloadable: true });
});

describe("POST /api/offline/items/complete", () => {
    it("records a library track with its trackId and size", async () => {
        const res = await call(complete, {
            body: {
                deviceId: DEV_A,
                playbackId: "t.abc",
                quality: "high",
                sizeBytes: 5 * MB,
            },
        });
        expect(res.statusCode).toBe(200);
        expect(rows).toHaveLength(1);
        expect(rows[0]).toMatchObject({
            userId: "u1",
            deviceId: DEV_A,
            playbackId: "t.abc",
            trackId: "abc",
            quality: "high",
            fileSizeMb: 5,
        });
    });

    it("records a remote item without a trackId", async () => {
        const res = await call(complete, {
            body: {
                deviceId: DEV_A,
                playbackId: "ym.dQw4w9WgXcQ",
                quality: "high",
                sizeBytes: 3 * MB,
            },
        });
        expect(res.statusCode).toBe(200);
        expect(rows[0]).toMatchObject({
            playbackId: "ym.dQw4w9WgXcQ",
            trackId: null,
        });
        expect(prisma.track.findUnique).not.toHaveBeenCalled();
    });

    it("is idempotent: completing twice updates one row", async () => {
        const body = {
            deviceId: DEV_A,
            playbackId: "t.abc",
            quality: "high",
            sizeBytes: 5 * MB,
        };
        await call(complete, { body });
        const res = await call(complete, {
            body: { ...body, sizeBytes: 6 * MB },
        });
        expect(res.statusCode).toBe(200);
        expect(rows).toHaveLength(1);
        expect(rows[0].fileSizeMb).toBe(6);
    });

    it("answers 404 for an unknown library track", async () => {
        prisma.track.findUnique.mockResolvedValue(null);
        const res = await call(complete, {
            body: {
                deviceId: DEV_A,
                playbackId: "t.gone",
                quality: "high",
                sizeBytes: MB,
            },
        });
        expect(res.statusCode).toBe(404);
        expect(res.body.code).toBe("TRACK_UNAVAILABLE");
        expect(rows).toHaveLength(0);
    });

    it.each([
        { playbackId: "bogus" },
        { deviceId: "not-a-uuid" },
        { sizeBytes: -1 },
        { quality: "ultra" },
    ])("answers 400 for invalid input %j", async (override) => {
        const res = await call(complete, {
            body: {
                deviceId: DEV_A,
                playbackId: "t.abc",
                quality: "high",
                sizeBytes: MB,
                ...override,
            },
        });
        expect(res.statusCode).toBe(400);
        expect(res.body.code).toBe("INVALID_REQUEST");
    });
});

describe("DELETE /api/offline/items", () => {
    it("removes only the named items of the named device", async () => {
        for (const deviceId of [DEV_A, DEV_B]) {
            for (const playbackId of ["t.abc", "yt.aaaaaaaaaaa"]) {
                await call(complete, {
                    body: {
                        deviceId,
                        playbackId,
                        quality: "high",
                        sizeBytes: MB,
                    },
                });
            }
        }
        const res = await call(remove, {
            body: { deviceId: DEV_A, playbackIds: ["t.abc"] },
        });
        expect(res.statusCode).toBe(200);
        expect(res.body).toEqual({ deletedCount: 1 });
        expect(
            rows.map(
                (r) => `${r.deviceId === DEV_A ? "A" : "B"}:${r.playbackId}`,
            ),
        ).toEqual(["A:yt.aaaaaaaaaaa", "B:t.abc", "B:yt.aaaaaaaaaaa"]);
    });

    it("succeeds as a no-op for unknown ids", async () => {
        const res = await call(remove, {
            body: { deviceId: DEV_A, playbackIds: ["t.nope"] },
        });
        expect(res.statusCode).toBe(200);
        expect(res.body).toEqual({ deletedCount: 0 });
    });

    it("answers 400 for an invalid body", async () => {
        const res = await call(remove, { body: { deviceId: DEV_A } });
        expect(res.statusCode).toBe(400);
    });
});

describe("GET /api/offline/items", () => {
    const seed = async () => {
        await call(complete, {
            body: {
                deviceId: DEV_A,
                playbackId: "t.abc",
                quality: "high",
                sizeBytes: 5 * MB,
            },
        });
        await call(complete, {
            body: {
                deviceId: DEV_B,
                playbackId: "t.other",
                quality: "low",
                sizeBytes: 2 * MB,
            },
        });
    };

    it("lists only this device's rows (device isolation)", async () => {
        await seed();
        const a = await call(list, { query: { deviceId: DEV_A } });
        expect(a.body.items).toEqual([
            {
                playbackId: "t.abc",
                quality: "high",
                sizeBytes: 5 * MB,
                revoked: false,
            },
        ]);
        const b = await call(list, { query: { deviceId: DEV_B } });
        expect(b.body.items.map((i: any) => i.playbackId)).toEqual(["t.other"]);
    });

    it("marks items revoked after the source toggle goes off", async () => {
        await seed();
        mockResolveOfflinePolicy.mockResolvedValue({
            downloadable: false,
            reason: "SOURCE_DOWNLOADS_DISABLED",
        });
        const res = await call(list, { query: { deviceId: DEV_A } });
        expect(res.body.items[0].revoked).toBe(true);
    });

    it("marks items revoked when the track is gone", async () => {
        await seed();
        mockResolveOfflinePolicy.mockResolvedValue({
            downloadable: false,
            reason: "TRACK_UNAVAILABLE",
        });
        const res = await call(list, { query: { deviceId: DEV_A } });
        expect(res.body.items[0].revoked).toBe(true);
    });

    it("does not revoke when the source is merely unavailable", async () => {
        await seed();
        mockResolveOfflinePolicy.mockResolvedValue({
            downloadable: false,
            reason: "SOURCE_UNAVAILABLE",
        });
        const res = await call(list, { query: { deviceId: DEV_A } });
        expect(res.body.items[0].revoked).toBe(false);
    });

    it("answers 400 without a valid deviceId", async () => {
        const res = await call(list, { query: {} });
        expect(res.statusCode).toBe(400);
    });
});

describe("GET /api/offline/stats", () => {
    beforeEach(async () => {
        await call(complete, {
            body: {
                deviceId: DEV_A,
                playbackId: "t.abc",
                quality: "high",
                sizeBytes: 5 * MB,
            },
        });
        await call(complete, {
            body: {
                deviceId: DEV_B,
                playbackId: "t.other",
                quality: "low",
                sizeBytes: 2 * MB,
            },
        });
    });

    it("is unchanged without deviceId", async () => {
        const res = await call(stats, {});
        expect(res.body).toEqual({
            usedMb: 7,
            maxMb: 100,
            availableMb: 93,
            percentUsed: expect.closeTo(7),
            trackCount: 2,
        });
    });

    it("adds per-device totals when deviceId is given", async () => {
        const res = await call(stats, { query: { deviceId: DEV_A } });
        expect(res.body).toMatchObject({
            usedMb: 7,
            trackCount: 2,
            device: { deviceId: DEV_A, usedMb: 5, trackCount: 1 },
        });
    });
});
