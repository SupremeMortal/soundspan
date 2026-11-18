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

function component(spec: JsonObject, id: string): JsonObject {
    return spec.components.schemas[id] as JsonObject;
}

describe("offline operations in the emitted client spec", () => {
    test("the offline tag holds the five source-agnostic offline operations", () => {
        expect(operationIdsByTag(emitted(), "offline")).toEqual([
            "completeOfflineItem",
            "deleteOfflineItems",
            "getOfflineStats",
            "listOfflineItems",
            "requestOfflineItems",
        ]);
    });

    test("the legacy album-based offline routes are not registered", () => {
        const paths = Object.keys(emitted().paths).filter((path) =>
            path.startsWith("/api/offline/"),
        );

        expect(paths.sort()).toEqual([
            "/api/offline/items",
            "/api/offline/items/complete",
            "/api/offline/stats",
        ]);
    });

    test("an offline item is one object whose blocked reasons are enumerated", () => {
        const item = component(emitted(), "OfflineItem");

        expect(item.type).toBe("object");
        expect([...item.required].sort()).toEqual([
            "downloadable",
            "playbackId",
        ]);
        expect(item.properties.downloadable).toEqual({ type: "boolean" });
        expect(item.properties.reason.enum).toEqual([
            "SOURCE_DOWNLOADS_DISABLED",
            "TRACK_UNAVAILABLE",
            "SOURCE_UNAVAILABLE",
        ]);
    });

    test("the 409 of requestOfflineItems is the cache-limit error with integer totals", () => {
        const spec = emitted();
        const conflict =
            spec.paths["/api/offline/items"].post.responses["409"].content[
                "application/json"
            ].schema;
        const error = component(spec, "CacheLimitExceededError");

        expect(conflict).toEqual({
            $ref: "#/components/schemas/CacheLimitExceededError",
        });
        for (const key of [
            "cacheLimitBytes",
            "cacheUsedBytes",
            "estimatedTotalBytes",
        ]) {
            expect(error.properties[key].type).toBe("integer");
            expect(error.required).toContain(key);
        }
    });

    test("deleteOfflineItems carries its body on the DELETE", () => {
        const body = emitted().paths["/api/offline/items"].delete.requestBody;

        expect(body.required).toBe(true);
        expect(body.content["application/json"].schema).toEqual({
            $ref: "#/components/schemas/DeleteOfflineItemsRequest",
        });
    });

    test("getOfflineStats takes an optional deviceId and answers an optional device", () => {
        const spec = emitted();
        const operation = spec.paths["/api/offline/stats"].get;
        const stats = component(spec, "OfflineStats");

        expect(operation.parameters).toEqual([
            expect.objectContaining({
                name: "deviceId",
                in: "query",
                required: false,
            }),
        ]);
        expect(stats.required).not.toContain("device");
        expect(stats.properties.device).toBeDefined();
    });
});
