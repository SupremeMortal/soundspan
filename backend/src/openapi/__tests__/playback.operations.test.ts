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

/** Every property name declared anywhere under `value`. */
function propertyNames(value: unknown, out = new Set<string>()): Set<string> {
    if (Array.isArray(value)) {
        value.forEach((child) => propertyNames(child, out));
    } else if (typeof value === "object" && value !== null) {
        const record = value as JsonObject;
        if (
            typeof record.properties === "object" &&
            record.properties !== null
        ) {
            Object.keys(record.properties).forEach((name) => out.add(name));
        }
        Object.values(record).forEach((child) => propertyNames(child, out));
    }
    return out;
}

function jsonSchema(path: string, method: string, status: number): JsonObject {
    return emitted().paths[path][method].responses[String(status)].content[
        "application/json"
    ].schema;
}

describe("playback operations in the emitted client spec", () => {
    test("the playback tag holds every JSON playback operation and not the binary stream", () => {
        expect(operationIdsByTag(emitted(), "playback")).toEqual([
            "clearPlaybackState",
            "getLyrics",
            "getPlaybackState",
            "getStreamInfo",
            "recordPlay",
            "savePlaybackState",
        ]);
    });

    test("no schema in the file declares a provider-specific field", () => {
        const names = propertyNames(emitted());

        expect(names.has("streamSource")).toBe(false);
        expect(names.has("tidalTrackId")).toBe(false);
        expect(names.has("youtubeVideoId")).toBe(false);
    });

    test("the request and response components are named", () => {
        expect(Object.keys(emitted().components.schemas)).toEqual(
            expect.arrayContaining([
                "StreamInfo",
                "PlaybackState",
                "PlaybackQueueItem",
                "PlayRecord",
                "PlayNotRecorded",
                "RecordPlayRequest",
                "PlaybackMetadata",
                "Lyrics",
            ]),
        );
    });

    test("recordPlay answers either a play row or { recorded: false }", () => {
        const schema = jsonSchema("/api/plays", "post", 200);
        const variants = (schema.oneOf ?? schema.anyOf) as JsonObject[];

        expect(variants).toEqual(
            expect.arrayContaining([
                { $ref: "#/components/schemas/PlayRecord" },
                { $ref: "#/components/schemas/PlayNotRecorded" },
            ]),
        );
    });

    test("the recordPlay body declares only the playbackId form", () => {
        const body = emitted().components.schemas.RecordPlayRequest;

        expect(Object.keys(body.properties).sort()).toEqual([
            "listenedMs",
            "metadata",
            "playbackId",
            "playedAt",
        ]);
    });

    test("getPlaybackState may answer null", () => {
        const schema = jsonSchema("/api/playback-state", "get", 200);

        expect(JSON.stringify(schema)).toContain(
            "#/components/schemas/PlaybackState",
        );
        expect(schema.nullable ?? false).toBe(true);
    });

    test.each([
        ["/api/playback/stream-info/{playbackId}", ["quality"]],
        ["/api/lyrics/{trackId}", ["album", "artist", "duration", "title"]],
    ])("%s declares the query parameters %j", (path, names) => {
        const parameters = (
            emitted().paths[path].get.parameters as JsonObject[]
        ).filter((parameter) => parameter.in === "query");

        expect(parameters.map((parameter) => parameter.name).sort()).toEqual(
            names,
        );
    });

    test.each([
        [
            "/api/playback/stream-info/{playbackId}",
            "get",
            [400, 404, 409, 429, 502, 504],
        ],
        ["/api/plays", "post", [400, 404, 409]],
        ["/api/lyrics/{trackId}", "get", [503, 504]],
    ])(
        "%s %s declares the error statuses %j as ApiError",
        (path, method, statuses) => {
            for (const status of statuses) {
                expect(jsonSchema(path, method, status)).toEqual({
                    $ref: "#/components/schemas/ApiError",
                });
            }
        },
    );
});
