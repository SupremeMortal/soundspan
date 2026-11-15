import { defineOperation } from "../defineOperation";
import { standardErrors } from "../schemas/common";
import {
    OnlineUsersResponse,
    PresenceHeartbeatResponse,
} from "../schemas/social";

/** Presence operations. */
export const socialOperations = [
    defineOperation({
        method: "post",
        path: "/api/social/presence/heartbeat",
        operationId: "sendPresenceHeartbeat",
        tag: "social",
        summary: "Mark the user online",
        description:
            "Takes no body. The presence lasts `ttlSeconds`; clients send a heartbeat well within it. What the user is playing is read from the stored playback state, not from the heartbeat. 503 when presence cannot be stored.",
        responses: { 200: PresenceHeartbeatResponse, ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/social/online",
        operationId: "listOnlineUsers",
        tag: "social",
        summary: "Online users who share their presence",
        description:
            "When federation is on the answer also carries `peers`, the presence of federated servers, which is not described here.",
        responses: { 200: OnlineUsersResponse, ...standardErrors },
    }),
];
