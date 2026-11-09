import type { Namespace } from "socket.io";
import {
    registerApiKeyRevocationNamespace,
    revokeApiKeySockets,
    revokeGroupSockets,
    revokeUserSockets,
} from "../listenTogetherSocketRevocation";

function socket(userId: string, groupId: string | null) {
    return {
        data: { userId, groupId },
        emit: jest.fn(),
        leave: jest.fn(async () => undefined),
    };
}

describe("Listen Together socket revocation", () => {
    it("evicts a departed user by identity after captured socket IDs are lost", async () => {
        const departed = socket("deleted-user", "group-1");
        const retained = socket("retained-user", "group-1");
        const namespace = {
            sockets: new Map([
                ["departed-socket", departed],
                ["retained-socket", retained],
            ]),
        } as unknown as Namespace;
        const beforeRevoke = jest.fn();

        await revokeGroupSockets(
            namespace,
            "group-1",
            [],
            { membershipVersion: 7 },
            "deleted-user",
            beforeRevoke,
        );

        expect(beforeRevoke).toHaveBeenCalledWith("group-1", "deleted-user");
        expect(departed.emit).toHaveBeenCalledWith("group:membership-revoked", {
            groupId: "group-1",
            membershipVersion: 7,
        });
        expect(departed.leave).toHaveBeenCalledWith("group-1");
        expect(departed.data.groupId).toBeNull();
        expect(retained.emit).not.toHaveBeenCalled();
        expect(retained.leave).not.toHaveBeenCalled();
    });

    it("fails closed when captured socket work exceeds the fixed bound", async () => {
        const namespace = {
            sockets: new Map(),
        } as unknown as Namespace;
        const socketIds = Array.from(
            { length: 10_001 },
            (_, index) => `socket-${index}`,
        );

        await expect(
            revokeGroupSockets(
                namespace,
                "group-1",
                socketIds,
                undefined,
                "deleted-user",
                jest.fn(),
            ),
        ).rejects.toThrow("socket revocation exceeded its bound");
    });

    it("evicts every socket for a user and makes replay a no-op", async () => {
        const first = socket("deleted-user", "group-1");
        const second = socket("deleted-user", "group-2");
        const retained = socket("retained-user", "group-1");
        const namespace = {
            sockets: new Map([
                ["first", first],
                ["second", second],
                ["retained", retained],
            ]),
        } as unknown as Namespace;
        const beforeRevoke = jest.fn();

        await revokeUserSockets(
            namespace,
            "deleted-user",
            "all-for-user",
            { membershipVersion: 9 },
            beforeRevoke,
        );
        await revokeUserSockets(
            namespace,
            "deleted-user",
            "all-for-user",
            { membershipVersion: 9 },
            beforeRevoke,
        );

        expect(beforeRevoke).toHaveBeenCalledTimes(2);
        expect(first.leave).toHaveBeenCalledTimes(1);
        expect(second.leave).toHaveBeenCalledTimes(1);
        expect(first.data.groupId).toBeNull();
        expect(second.data.groupId).toBeNull();
        expect(retained.leave).not.toHaveBeenCalled();
    });
});

describe("Listen Together API-key socket revocation", () => {
    function keySocket(userId: string, apiKeyId: string | undefined) {
        return {
            data: { userId, groupId: null, apiKeyId },
            disconnect: jest.fn(),
        };
    }

    function namespaceOf(sockets: ReturnType<typeof keySocket>[]) {
        return {
            fetchSockets: jest.fn(async () => sockets),
        } as unknown as Namespace;
    }

    afterEach(() => registerApiKeyRevocationNamespace(null));

    it("disconnects only the sockets authenticated with the deleted key", async () => {
        const keyA1 = keySocket("user-1", "key-a");
        const keyA2 = keySocket("user-1", "key-a");
        const keyB = keySocket("user-1", "key-b");
        const jwt = keySocket("user-1", undefined);
        registerApiKeyRevocationNamespace(
            namespaceOf([keyA1, keyB, jwt, keyA2]),
        );

        await revokeApiKeySockets("key-a");

        expect(keyA1.disconnect).toHaveBeenCalledWith(true);
        expect(keyA2.disconnect).toHaveBeenCalledWith(true);
        expect(keyB.disconnect).not.toHaveBeenCalled();
        expect(jwt.disconnect).not.toHaveBeenCalled();
    });

    it("is a no-op before the namespace exists", async () => {
        await expect(revokeApiKeySockets("key-a")).resolves.toBeUndefined();
    });

    it("fails closed when the socket scan exceeds the fixed bound", async () => {
        registerApiKeyRevocationNamespace(
            namespaceOf(
                Array.from({ length: 10_001 }, () => keySocket("u", "k")),
            ),
        );

        await expect(revokeApiKeySockets("key-a")).rejects.toThrow(
            "exceeded its bound",
        );
    });
});
