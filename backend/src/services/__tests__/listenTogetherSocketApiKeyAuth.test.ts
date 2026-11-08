import { hashApiKey, API_KEY_LIFETIME_MS } from "../../utils/apiKeyHash";

const findUnique = jest.fn();
const update = jest.fn();

jest.mock("../../utils/db", () => ({
    prisma: { apiKey: { findUnique, update } },
}));
jest.mock("../../utils/logger", () => {
    const logger: any = {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    };
    logger.child = () => logger;
    return { logger };
});

import {
    authenticateSocketApiKey,
    resolveApiKeySocketData,
} from "../listenTogetherSocketApiKeyAuth";

const RAW_KEY = "a".repeat(64);

function record(overrides: Record<string, unknown> = {}) {
    return {
        id: "key-1",
        createdAt: new Date(),
        user: { id: "user-1", username: "User One", pendingDeletionAt: null },
        ...overrides,
    };
}

describe("authenticateSocketApiKey", () => {
    beforeEach(() => {
        process.env.API_KEY_PEPPER = "test-pepper";
        findUnique.mockReset();
        update.mockReset();
        update.mockResolvedValue({});
    });

    it("resolves a valid key to its user and key id and records last use", async () => {
        findUnique.mockImplementation(async ({ where }: any) =>
            where.key === hashApiKey(RAW_KEY) ? record() : null,
        );
        await expect(authenticateSocketApiKey(RAW_KEY)).resolves.toEqual({
            userId: "user-1",
            username: "User One",
            apiKeyId: "key-1",
        });
        expect(update).toHaveBeenCalledWith({
            where: { id: "key-1" },
            data: { lastUsed: expect.any(Date) },
        });
    });

    it("does not fail the handshake when the last-used update fails", async () => {
        findUnique.mockResolvedValue(record());
        update.mockRejectedValue(new Error("db down"));
        await expect(authenticateSocketApiKey(RAW_KEY)).resolves.toMatchObject({
            apiKeyId: "key-1",
        });
    });

    it("rejects an unknown key", async () => {
        findUnique.mockResolvedValue(null);
        await expect(authenticateSocketApiKey(RAW_KEY)).rejects.toThrow(
            "Invalid API key",
        );
        expect(update).not.toHaveBeenCalled();
    });

    it("rejects an expired key", async () => {
        findUnique.mockResolvedValue(
            record({
                createdAt: new Date(Date.now() - API_KEY_LIFETIME_MS - 1000),
            }),
        );
        await expect(authenticateSocketApiKey(RAW_KEY)).rejects.toThrow(
            "Invalid API key",
        );
        expect(update).not.toHaveBeenCalled();
    });

    it("rejects a key whose user is pending deletion", async () => {
        findUnique.mockResolvedValue(
            record({
                user: {
                    id: "user-1",
                    username: "User One",
                    pendingDeletionAt: new Date(),
                },
            }),
        );
        await expect(authenticateSocketApiKey(RAW_KEY)).rejects.toThrow(
            "User deletion is pending",
        );
        expect(update).not.toHaveBeenCalled();
    });

    it("rejects a key record without a user", async () => {
        findUnique.mockResolvedValue(record({ user: null }));
        await expect(authenticateSocketApiKey(RAW_KEY)).rejects.toThrow(
            "Invalid API key",
        );
    });

    it.each([
        ["empty", ""],
        ["numeric", 12345],
        ["object", { key: "x" }],
        ["oversized", "b".repeat(1000)],
    ])("rejects a malformed (%s) key without querying", async (_n, value) => {
        await expect(authenticateSocketApiKey(value)).rejects.toThrow(
            "Invalid API key",
        );
        expect(findUnique).not.toHaveBeenCalled();
    });

    it("refuses a stored hash presented as the raw key", async () => {
        findUnique.mockResolvedValue(null);
        await expect(
            authenticateSocketApiKey(hashApiKey(RAW_KEY)),
        ).rejects.toThrow("Invalid API key");
        expect(findUnique).toHaveBeenCalledTimes(1);
    });
});

describe("resolveApiKeySocketData", () => {
    beforeEach(() => {
        process.env.API_KEY_PEPPER = "test-pepper";
        findUnique.mockReset();
        update.mockReset();
        update.mockResolvedValue({});
    });

    it("returns socket data with the key id and no group", async () => {
        findUnique.mockResolvedValue(record());
        await expect(resolveApiKeySocketData(RAW_KEY)).resolves.toEqual({
            userId: "user-1",
            username: "User One",
            groupId: null,
            apiKeyId: "key-1",
        });
    });

    it("passes through client-safe rejections", async () => {
        findUnique.mockResolvedValue(null);
        await expect(resolveApiKeySocketData(RAW_KEY)).rejects.toThrow(
            "Invalid API key",
        );
    });

    it("hides internal lookup failures behind a generic message", async () => {
        findUnique.mockRejectedValue(
            new Error("connect ECONNREFUSED 10.0.0.5:5432"),
        );
        await expect(resolveApiKeySocketData(RAW_KEY)).rejects.toThrow(
            /^Invalid API key$/,
        );
    });
});
