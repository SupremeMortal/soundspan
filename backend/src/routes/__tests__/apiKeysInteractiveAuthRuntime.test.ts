process.env.SETTINGS_ENCRYPTION_KEY =
    process.env.SETTINGS_ENCRYPTION_KEY ||
    "api-keys-interactive-auth-test-pepper-123456";
process.env.JWT_SECRET = process.env.JWT_SECRET || "test-jwt-secret";

jest.mock("../../middleware/auth", () => ({
    requireAuth: (_req: any, _res: any, next: () => void) => next(),
    requireInteractiveSession: jest.requireActual("../../middleware/auth")
        .requireInteractiveSession,
}));

const prisma = {
    apiKey: {
        create: jest.fn(),
        findMany: jest.fn(),
        deleteMany: jest.fn(),
    },
};
jest.mock("../../utils/db", () => ({ prisma }));

const scopedLogger = {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    child: jest.fn(),
};
scopedLogger.child.mockReturnValue(scopedLogger);
jest.mock("../../utils/logger", () => ({ logger: scopedLogger }));

import express from "express";
import request from "supertest";
import router from "../apiKeys";

function createRes() {
    const res: any = {
        statusCode: 200,
        body: undefined,
        status: jest.fn((statusCode: number) => {
            res.statusCode = statusCode;
            return res;
        }),
        json: jest.fn((body: unknown) => {
            res.body = body;
            return res;
        }),
    };
    return res;
}

async function executeRoute(
    method: "post" | "delete",
    path: string,
    req: any,
    res: any,
): Promise<void> {
    const layer = (router as any).stack.find(
        (entry: any) =>
            entry.route?.path === path && entry.route?.methods?.[method],
    );
    if (!layer) throw new Error(`Missing route ${method} ${path}`);

    const dispatch = async (index: number): Promise<void> => {
        const handler = layer.route.stack[index]?.handle;
        if (!handler) return;
        await handler(req, res, (error?: unknown) => {
            if (error) throw error;
            return dispatch(index + 1);
        });
    };
    await dispatch(0);
}

function interactiveRequest(body: Record<string, unknown> = {}): any {
    return {
        body,
        headers: { authorization: "Bearer access-token" },
        user: { id: "u1", username: "alice", role: "user" },
        params: { id: "key-1" },
    };
}

describe("API key management interactive authentication", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        prisma.apiKey.create.mockResolvedValue({
            name: "Laptop",
            createdAt: new Date("2026-01-01T00:00:00.000Z"),
        });
        prisma.apiKey.deleteMany.mockResolvedValue({ count: 1 });
    });

    test.each([
        ["post", "/", { deviceName: "Laptop" }],
        ["delete", "/:id", {}],
    ] as const)(
        "rejects X-API-Key authentication for %s %s",
        async (method, path, body) => {
            const req = interactiveRequest(body);
            req.headers["x-api-key"] = "stolen-key";
            const res = createRes();

            await executeRoute(method, path, req, res);

            expect(res.statusCode).toBe(403);
            expect(res.body).toEqual({
                error: "Interactive session authentication required",
            });
            expect(prisma.apiKey.create).not.toHaveBeenCalled();
            expect(prisma.apiKey.deleteMany).not.toHaveBeenCalled();
        },
    );

    it("creates a bounded key from the shipping device-name payload", async () => {
        const res = createRes();

        await executeRoute(
            "post",
            "/",
            interactiveRequest({ deviceName: "Laptop" }),
            res,
        );

        expect(res.statusCode).toBe(201);
        expect(res.body).toEqual(
            expect.objectContaining({
                apiKey: expect.stringMatching(/^[0-9a-f]{64}$/),
                name: "Laptop",
                expiresAt: expect.any(Date),
            }),
        );
        expect(res.body.expiresAt.getTime()).toBeGreaterThan(
            res.body.createdAt.getTime(),
        );
    });

    it("revokes a key without adding a request body", async () => {
        const res = createRes();

        await executeRoute("delete", "/:id", interactiveRequest(), res);

        expect(res.statusCode).toBe(200);
        expect(res.body).toEqual({ message: "API key revoked successfully" });
    });

    describe("routing through the mounted router", () => {
        function createApp() {
            const app = express();
            app.use((req, _res, next) => {
                req.user = { id: "u1", username: "alice", role: "user" };
                if (req.headers["x-api-key"] !== undefined) {
                    req.apiKeyId = "self-key";
                }
                next();
            });
            app.use("/api/api-keys", router);
            return app;
        }

        it("routes DELETE /current with X-API-Key to the self-revoke handler", async () => {
            const res = await request(createApp())
                .delete("/api/api-keys/current")
                .set("X-API-Key", "device-key");

            expect(res.status).toBe(200);
            expect(res.body).toEqual({
                message: "API key revoked successfully",
            });
            expect(prisma.apiKey.deleteMany).toHaveBeenCalledWith({
                where: { id: "self-key", userId: "u1" },
            });
        });

        it("keeps rejecting DELETE /:id with X-API-Key", async () => {
            const res = await request(createApp())
                .delete("/api/api-keys/key-1")
                .set("X-API-Key", "device-key");

            expect(res.status).toBe(403);
            expect(prisma.apiKey.deleteMany).not.toHaveBeenCalled();
        });
    });
});
