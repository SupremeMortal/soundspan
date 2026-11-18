import { clientSurfaceOperations } from "../clientSurface";
import { renderClientSurfaceSpec } from "../emit";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

function emitted(): JsonObject {
    return JSON.parse(
        renderClientSurfaceSpec(clientSurfaceOperations, "0.0.0-test"),
    ) as JsonObject;
}

function operationIdsByTag(spec: JsonObject, tag: string): string[] {
    return Object.values(spec.paths as JsonObject)
        .flatMap((item) => Object.values(item as JsonObject))
        .filter((operation: JsonObject) => operation.tags.includes(tag))
        .map((operation: JsonObject) => operation.operationId)
        .sort();
}

const PROVIDER_FIELDS = ["streamSource", "tidalTrackId", "youtubeVideoId"];

describe("Listen Together and presence operations in the emitted client spec", () => {
    test("the listenTogether tag holds the six group operations", () => {
        expect(operationIdsByTag(emitted(), "listenTogether")).toEqual([
            "createListenGroup",
            "discoverListenGroups",
            "endListenGroup",
            "getMyListenGroup",
            "joinListenGroup",
            "leaveListenGroup",
        ]);
    });

    test("the social tag holds the heartbeat and the online list", () => {
        expect(operationIdsByTag(emitted(), "social")).toEqual([
            "listOnlineUsers",
            "sendPresenceHeartbeat",
        ]);
    });

    test.each(["ListenQueueItem", "ListenQueueTrackInput", "OnlineUserTrack"])(
        "%s declares no provider field",
        (id) => {
            const properties = Object.keys(
                emitted().components.schemas[id].properties,
            );

            expect(properties).toContain("playbackId");
            for (const field of PROVIDER_FIELDS) {
                expect(properties).not.toContain(field);
            }
        },
    );

    test("a queue track input requires its playbackId", () => {
        expect(
            emitted().components.schemas.ListenQueueTrackInput.required,
        ).toEqual(["playbackId"]);
    });

    test("the group path parameter is groupId", () => {
        const spec = emitted();

        expect(
            spec.paths["/api/listen-together/{groupId}/leave"].post.parameters,
        ).toEqual([expect.objectContaining({ name: "groupId", in: "path" })]);
    });
});
