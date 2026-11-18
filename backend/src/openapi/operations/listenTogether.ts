import { z } from "zod";
import { defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";
import {
    CreateListenGroupRequest,
    EndListenGroupResponse,
    JoinListenGroupRequest,
    LeaveListenGroupResponse,
    ListenGroupIdParams,
    ListenGroupSnapshot,
    ListenGroupSummary,
} from "../schemas/listenTogether";

const CONFLICT =
    "409 when a concurrent change to the group wins; the request can be retried.";

/** Listen Together REST operations; live playback sync runs over the socket. */
export const listenTogetherOperations = [
    defineOperation({
        method: "post",
        path: "/api/listen-together",
        operationId: "createListenGroup",
        tag: "listenTogether",
        summary: "Create a Listen Together group hosted by the user",
        description: `Each \`queueTracks\` entry needs a \`playbackId\`, which wins over the legacy queue item fields (\`trackId\` and display fields), still accepted and not described here. 400 with code \`INVALID_PLAYBACK_ID\` for a \`playbackId\` that cannot be parsed, and without a code for an invalid body. ${CONFLICT}`,
        body: CreateListenGroupRequest,
        responses: {
            201: ListenGroupSnapshot,
            400: ApiError,
            409: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "post",
        path: "/api/listen-together/join",
        operationId: "joinListenGroup",
        tag: "listenTogether",
        summary: "Join a group by its join code",
        description: `400 for an invalid join code. 403 when the user may not join. 404 when no active group has the code. ${CONFLICT}`,
        body: JoinListenGroupRequest,
        responses: {
            200: ListenGroupSnapshot,
            400: ApiError,
            403: ApiError,
            404: ApiError,
            409: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "get",
        path: "/api/listen-together/discover",
        operationId: "discoverListenGroups",
        tag: "listenTogether",
        summary: "Active public groups, most recently updated first",
        description: "At most 50 groups.",
        responses: { 200: z.array(ListenGroupSummary), ...standardErrors },
    }),
    defineOperation({
        method: "get",
        path: "/api/listen-together/mine",
        operationId: "getMyListenGroup",
        tag: "listenTogether",
        summary: "The active group the user is a member of",
        description: "Answers `null` when the user is in no active group.",
        responses: { 200: ListenGroupSnapshot.nullable(), ...standardErrors },
    }),
    defineOperation({
        method: "post",
        path: "/api/listen-together/{groupId}/leave",
        operationId: "leaveListenGroup",
        tag: "listenTogether",
        summary: "Leave a group",
        description: `403 when the user is not a member. 404 when the group does not exist. ${CONFLICT}`,
        params: ListenGroupIdParams,
        responses: {
            200: LeaveListenGroupResponse,
            403: ApiError,
            404: ApiError,
            409: ApiError,
            ...standardErrors,
        },
    }),
    defineOperation({
        method: "post",
        path: "/api/listen-together/{groupId}/end",
        operationId: "endListenGroup",
        tag: "listenTogether",
        summary: "End a group for every member",
        description: `403 when the user is not the host. 404 when the group does not exist. ${CONFLICT}`,
        params: ListenGroupIdParams,
        responses: {
            200: EndListenGroupResponse,
            403: ApiError,
            404: ApiError,
            409: ApiError,
            ...standardErrors,
        },
    }),
];
