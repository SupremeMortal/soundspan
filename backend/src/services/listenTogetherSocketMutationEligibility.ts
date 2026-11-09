import type { Namespace } from "socket.io";
import { GroupError, groupManager } from "./listenTogetherManager";
import { prisma } from "../utils/db";
import { isApiKeyExpired } from "../utils/apiKeyHash";
import {
    revokeApiKeySockets,
    revokeUserSockets,
} from "./listenTogetherSocketRevocation";
import { assertUserNotPendingDeletion } from "./listenTogetherUserEligibility";

type BeforeSocketRevocation = (groupId: string, userId: string) => void;

/**
 * Re-check the key an API-key socket authenticated with. An expired or deleted
 * key disconnects every socket using it, mirroring the handshake rules.
 * Costs one primary-key read per mutation, alongside the user check.
 */
async function assertApiKeyStillValid(apiKeyId: string): Promise<void> {
    const record = await prisma.apiKey.findUnique({
        where: { id: apiKeyId },
        select: { createdAt: true },
    });
    if (record && !isApiKeyExpired(record.createdAt)) return;
    await revokeApiKeySockets(apiKeyId);
    throw new GroupError("NOT_ALLOWED", "API key expired or revoked");
}

/**
 * Reject and locally revoke a lock-owning socket actor marked for deletion, or
 * whose authenticating API key (when `apiKeyId` is set) has expired or gone.
 */
export async function assertSocketMutationUserEligible(
    namespace: Namespace | null,
    groupId: string,
    userId: string | undefined,
    beforeRevoke: BeforeSocketRevocation,
    apiKeyId?: string,
): Promise<void> {
    if (!userId) return;
    try {
        await assertUserNotPendingDeletion(userId);
        if (apiKeyId) await assertApiKeyStillValid(apiKeyId);
    } catch (error) {
        if (
            error instanceof GroupError &&
            (error.code === "NOT_ALLOWED" || error.code === "NOT_FOUND")
        ) {
            if (namespace) {
                await revokeUserSockets(
                    namespace,
                    userId,
                    [groupId],
                    undefined,
                    beforeRevoke,
                );
            }
            groupManager.evictLocalMember(groupId, userId);
        }
        throw error;
    }
}
