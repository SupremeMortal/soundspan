// API-key hashing needs a pepper (API_KEY_PEPPER → SETTINGS_ENCRYPTION_KEY →
// SESSION_SECRET); provide one for the real apiKeyHash util used on create.
process.env.SETTINGS_ENCRYPTION_KEY =
    process.env.SETTINGS_ENCRYPTION_KEY ||
    "api-keys-test-pepper-1234567890123456";

jest.mock("../../middleware/auth", () => ({
    requireAuth: (_req: any, _res: any, next: () => void) => next(),
    requireInteractiveSession: (_req: any, _res: any, next: () => void) =>
        next(),
}));

const mockLogger = {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    child: jest.fn(),
};
mockLogger.child.mockReturnValue(mockLogger);
jest.mock("../../utils/logger", () => ({ logger: mockLogger }));

const prisma = {
    apiKey: {
        create: jest.fn(),
        findMany: jest.fn(),
        deleteMany: jest.fn(),
    },
};

jest.mock("../../utils/db", () => ({
    prisma,
}));

const mockRevokeApiKeySockets = jest.fn();
jest.mock("../../services/listenTogetherSocketRevocation", () => ({
    revokeApiKeySockets: (id: string) => mockRevokeApiKeySockets(id),
}));

import router from "../apiKeys";
import { prisma as prismaClient } from "../../utils/db";

const mockCreateApiKey = prismaClient.apiKey.create as jest.Mock;
const mockFindManyApiKeys = prismaClient.apiKey.findMany as jest.Mock;
const mockDeleteManyApiKeys = prismaClient.apiKey.deleteMany as jest.Mock;

function getHandler(method: "get" | "post" | "delete", path: string) {
    const layer = (router as any).stack.find(
        (entry: any) =>
            entry.route?.path === path && entry.route?.methods?.[method],
    );

    if (!layer) {
        throw new Error(`Route not found: ${method.toUpperCase()} ${path}`);
    }

    return layer.route.stack[layer.route.stack.length - 1].handle;
}

function createRes() {
    const res: any = {
        statusCode: 200,
        body: undefined as unknown,
        status: jest.fn(function (code: number) {
            res.statusCode = code;
            return res;
        }),
        json: jest.fn(function (payload: unknown) {
            res.body = payload;
            return res;
        }),
    };

    return res;
}

describe("apiKeys routes runtime", () => {
    const postCreate = getHandler("post", "/");
    const getList = getHandler("get", "/");
    const deleteKey = getHandler("delete", "/:id");

    beforeEach(() => {
        jest.clearAllMocks();

        mockCreateApiKey.mockResolvedValue({
            id: "k1",
            key: "a".repeat(64),
            name: "My Phone",
            createdAt: new Date("2026-02-17T00:00:00.000Z"),
        });
        mockFindManyApiKeys.mockResolvedValue([
            {
                id: "k1",
                name: "My Phone",
                lastUsed: null,
                createdAt: new Date("2026-02-16T00:00:00.000Z"),
            },
        ]);
        mockDeleteManyApiKeys.mockResolvedValue({ count: 1 });
    });

    it("validates create payload and requires authentication identity", async () => {
        const missingNameReq = {
            body: { deviceName: "   " },
            user: { id: "u1" },
        } as any;
        const missingNameRes = createRes();

        await postCreate(missingNameReq, missingNameRes);

        expect(missingNameRes.statusCode).toBe(400);
        expect(missingNameRes.body).toEqual({
            error: "Device name is required",
        });

        const unauthReq = { body: { deviceName: "Phone" } } as any;
        const unauthRes = createRes();

        await postCreate(unauthReq, unauthRes);

        expect(unauthRes.statusCode).toBe(401);
        expect(unauthRes.body).toEqual({ error: "Not authenticated" });
    });

    it("creates a key for the authenticated user and trims device name", async () => {
        const req = {
            body: { deviceName: "  Tablet  " },
            user: { id: "authenticated-user" },
        } as any;
        const res = createRes();

        await postCreate(req, res);

        // Persisted key is hashed (hmac:<hex>); the raw key is returned in the
        // response only.
        expect(mockCreateApiKey).toHaveBeenCalledWith({
            data: {
                userId: "authenticated-user",
                name: "Tablet",
                key: expect.stringMatching(/^hmac:[0-9a-f]{64}$/),
            },
        });
        expect(res.statusCode).toBe(201);
        expect(res.body).toEqual(
            expect.objectContaining({
                apiKey: expect.stringMatching(/^[0-9a-f]{64}$/),
                name: "My Phone",
                message:
                    "API key created successfully. Save this key - you won't see it again!",
                expiresAt: expect.any(Date),
            }),
        );
        expect(res.body.expiresAt.getTime()).toBeGreaterThan(
            res.body.createdAt.getTime(),
        );
    });

    it("returns 500 when key creation fails", async () => {
        mockCreateApiKey.mockRejectedValueOnce(new Error("db down"));
        const req = {
            body: { deviceName: "Laptop" },
            user: { id: "u1" },
        } as any;
        const res = createRes();

        await postCreate(req, res);

        expect(res.statusCode).toBe(500);
        expect(res.body).toEqual({ error: "Failed to create API key" });
    });

    it("lists keys for the authenticated user and handles failures", async () => {
        const req = { user: { id: "authenticated-user" } } as any;
        const res = createRes();

        await getList(req, res);

        expect(mockFindManyApiKeys).toHaveBeenCalledWith({
            where: { userId: "authenticated-user" },
            select: {
                id: true,
                name: true,
                lastUsed: true,
                createdAt: true,
            },
            orderBy: { createdAt: "desc" },
        });
        expect(res.statusCode).toBe(200);
        expect(res.body).toEqual({
            apiKeys: expect.arrayContaining([
                expect.objectContaining({
                    id: "k1",
                    name: "My Phone",
                    expiresAt: expect.any(Date),
                }),
            ]),
        });

        const unauthReq = {} as any;
        const unauthRes = createRes();
        await getList(unauthReq, unauthRes);
        expect(unauthRes.statusCode).toBe(401);
        expect(unauthRes.body).toEqual({ error: "Not authenticated" });

        mockFindManyApiKeys.mockRejectedValueOnce(new Error("db down"));
        const errorReq = { user: { id: "u1" } } as any;
        const errorRes = createRes();
        await getList(errorReq, errorRes);
        expect(errorRes.statusCode).toBe(500);
        expect(errorRes.body).toEqual({ error: "Failed to list API keys" });
    });

    it("deletes owned keys, returns 404 for missing keys, and handles failures", async () => {
        const req = { params: { id: "k1" }, user: { id: "u1" } } as any;
        const res = createRes();

        await deleteKey(req, res);

        expect(mockDeleteManyApiKeys).toHaveBeenCalledWith({
            where: { id: "k1", userId: "u1" },
        });
        expect(res.statusCode).toBe(200);
        expect(res.body).toEqual({ message: "API key revoked successfully" });
        expect(mockRevokeApiKeySockets).toHaveBeenCalledWith("k1");

        mockRevokeApiKeySockets.mockClear();
        mockDeleteManyApiKeys.mockResolvedValueOnce({ count: 0 });
        const notFoundRes = createRes();
        await deleteKey(req, notFoundRes);
        expect(notFoundRes.statusCode).toBe(404);
        expect(notFoundRes.body).toEqual({
            error: "API key not found or already deleted",
        });

        const unauthReq = { params: { id: "k1" } } as any;
        const unauthRes = createRes();
        await deleteKey(unauthReq, unauthRes);
        expect(unauthRes.statusCode).toBe(401);
        expect(unauthRes.body).toEqual({ error: "Not authenticated" });
        expect(mockRevokeApiKeySockets).not.toHaveBeenCalled();

        mockDeleteManyApiKeys.mockRejectedValueOnce(new Error("db down"));
        const errorRes = createRes();
        await deleteKey(req, errorRes);
        expect(errorRes.statusCode).toBe(500);
        expect(errorRes.body).toEqual({ error: "Failed to revoke API key" });
    });

    it("still reports success when socket revocation fails", async () => {
        mockRevokeApiKeySockets.mockRejectedValueOnce(new Error("redis down"));
        const res = createRes();

        await deleteKey(
            { params: { id: "k1" }, user: { id: "u1" } } as any,
            res,
        );

        expect(res.statusCode).toBe(200);
    });

    describe("DELETE /current", () => {
        const deleteCurrent = getHandler("delete", "/current");

        it("lets an API key delete itself and revokes its sockets", async () => {
            const res = createRes();

            await deleteCurrent(
                { user: { id: "u1" }, apiKeyId: "self-key" } as any,
                res,
            );

            expect(mockDeleteManyApiKeys).toHaveBeenCalledWith({
                where: { id: "self-key", userId: "u1" },
            });
            expect(mockRevokeApiKeySockets).toHaveBeenCalledWith("self-key");
            expect(res.statusCode).toBe(200);
            expect(res.body).toEqual({
                message: "API key revoked successfully",
            });
        });

        it("rejects a request not authenticated with an API key", async () => {
            const res = createRes();

            await deleteCurrent({ user: { id: "u1" } } as any, res);

            expect(res.statusCode).toBe(400);
            expect(res.body).toEqual({
                error: "This request is not authenticated with an API key",
                code: "NOT_API_KEY_SESSION",
            });
            expect(mockDeleteManyApiKeys).not.toHaveBeenCalled();
            expect(mockRevokeApiKeySockets).not.toHaveBeenCalled();
        });

        it("scopes the delete to the requesting user's keys", async () => {
            await deleteCurrent(
                { user: { id: "other-user" }, apiKeyId: "self-key" } as any,
                createRes(),
            );

            expect(mockDeleteManyApiKeys).toHaveBeenCalledTimes(1);
            expect(mockDeleteManyApiKeys.mock.calls[0][0].where.userId).toBe(
                "other-user",
            );
        });

        it("still answers 200 when the key is already gone", async () => {
            mockDeleteManyApiKeys.mockResolvedValueOnce({ count: 0 });
            const res = createRes();

            await deleteCurrent(
                { user: { id: "u1" }, apiKeyId: "self-key" } as any,
                res,
            );

            expect(res.statusCode).toBe(200);
            expect(res.body).toEqual({
                message: "API key revoked successfully",
            });
            expect(mockRevokeApiKeySockets).toHaveBeenCalledWith("self-key");
        });

        it("still answers 200 and logs when socket revocation fails", async () => {
            mockRevokeApiKeySockets.mockRejectedValueOnce(
                new Error("redis down"),
            );
            const res = createRes();

            await deleteCurrent(
                { user: { id: "u1" }, apiKeyId: "self-key" } as any,
                res,
            );

            expect(res.statusCode).toBe(200);
            expect(mockLogger.error).toHaveBeenCalledWith(
                "API key socket revocation failed",
                expect.objectContaining({ keyId: "self-key" }),
            );
        });

        it("answers 500 when the delete fails", async () => {
            mockDeleteManyApiKeys.mockRejectedValueOnce(new Error("db down"));
            const res = createRes();

            await deleteCurrent(
                { user: { id: "u1" }, apiKeyId: "self-key" } as any,
                res,
            );

            expect(res.statusCode).toBe(500);
            expect(res.body).toEqual({ error: "Failed to revoke API key" });
        });
    });
});
