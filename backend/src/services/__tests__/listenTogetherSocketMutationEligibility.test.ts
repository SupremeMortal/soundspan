import type { Namespace } from "socket.io";

describe("Listen Together socket mutation eligibility for API-key sockets", () => {
    const DAY_MS = 24 * 60 * 60 * 1000;

    afterEach(() => {
        jest.resetModules();
        jest.restoreAllMocks();
    });

    function load(apiKeyRow: { createdAt: Date } | null) {
        jest.resetModules();
        const prisma = {
            user: {
                findUnique: jest.fn(async () => ({ pendingDeletionAt: null })),
            },
            apiKey: { findUnique: jest.fn(async () => apiKeyRow) },
        };
        const groupManager = { evictLocalMember: jest.fn() };
        const revokeApiKeySockets = jest.fn(async () => undefined);
        const revokeUserSockets = jest.fn(async () => undefined);
        jest.doMock("../../utils/db", () => ({ prisma }));
        jest.doMock("../listenTogetherManager", () => ({
            // eslint-disable-next-line @typescript-eslint/no-var-requires
            GroupError: require("../listenTogetherGroupError").GroupError,
            groupManager,
        }));
        jest.doMock("../listenTogetherSocketRevocation", () => ({
            revokeApiKeySockets,
            revokeUserSockets,
        }));
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const mod = require("../listenTogetherSocketMutationEligibility");
        return { mod, prisma, groupManager, revokeApiKeySockets };
    }

    const ns = {} as Namespace;

    it("allows a mutation while the authenticating key is still valid", async () => {
        const { mod, revokeApiKeySockets } = load({ createdAt: new Date() });
        await expect(
            mod.assertSocketMutationUserEligible(
                ns,
                "g1",
                "u1",
                jest.fn(),
                "key-1",
            ),
        ).resolves.toBeUndefined();
        expect(revokeApiKeySockets).not.toHaveBeenCalled();
    });

    it("rejects the mutation and disconnects the key's sockets once the key has expired", async () => {
        const { mod, groupManager, revokeApiKeySockets } = load({
            createdAt: new Date(Date.now() - 3650 * DAY_MS),
        });
        await expect(
            mod.assertSocketMutationUserEligible(
                ns,
                "g1",
                "u1",
                jest.fn(),
                "key-1",
            ),
        ).rejects.toMatchObject({ code: "NOT_ALLOWED" });
        expect(revokeApiKeySockets).toHaveBeenCalledWith("key-1");
        expect(groupManager.evictLocalMember).toHaveBeenCalledWith("g1", "u1");
    });

    it("rejects the mutation and disconnects the key's sockets when the key no longer exists", async () => {
        const { mod, revokeApiKeySockets } = load(null);
        await expect(
            mod.assertSocketMutationUserEligible(
                ns,
                "g1",
                "u1",
                jest.fn(),
                "key-1",
            ),
        ).rejects.toMatchObject({ code: "NOT_ALLOWED" });
        expect(revokeApiKeySockets).toHaveBeenCalledWith("key-1");
    });

    it("does not consult API keys for JWT sockets", async () => {
        const { mod, prisma } = load(null);
        await expect(
            mod.assertSocketMutationUserEligible(ns, "g1", "u1", jest.fn()),
        ).resolves.toBeUndefined();
        expect(prisma.apiKey.findUnique).not.toHaveBeenCalled();
    });
});
