import { clientSurfaceOperations, getOperation } from "../clientSurface";
import { renderClientSurfaceSpec } from "../emit";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

function emitted(): JsonObject {
    return JSON.parse(
        renderClientSurfaceSpec(clientSurfaceOperations, "0.0.0-test"),
    ) as JsonObject;
}

function operation(path: string, method: string): JsonObject {
    const item = emitted().paths[path] as JsonObject | undefined;
    if (!item?.[method]) throw new Error(`${method} ${path} is not emitted`);
    return item[method] as JsonObject;
}

function jsonSchema(path: string, method: string, status: number): JsonObject {
    return operation(path, method).responses[String(status)].content[
        "application/json"
    ].schema;
}

function component(name: string): JsonObject {
    return emitted().components.schemas[name] as JsonObject;
}

function bodyProperties(path: string, method: string): string[] {
    const ref: string = operation(path, method).requestBody.content[
        "application/json"
    ].schema.$ref;
    return Object.keys(
        component(ref.replace("#/components/schemas/", "")).properties,
    ).sort();
}

describe("podcast operations in the emitted client spec", () => {
    test.each([
        ["/api/podcasts", "get", "listPodcasts"],
        ["/api/podcasts/{id}", "get", "getPodcast"],
        [
            "/api/podcasts/{podcastId}/episodes/{episodeId}/progress",
            "post",
            "updateEpisodeProgress",
        ],
        ["/api/podcasts/subscribe", "post", "subscribePodcast"],
        ["/api/podcasts/{id}/unsubscribe", "delete", "unsubscribePodcast"],
    ])("%s %s is %s under podcasts", (path, method, operationId) => {
        const emittedOperation = operation(path, method);

        expect(emittedOperation.operationId).toBe(operationId);
        expect(emittedOperation.tags).toEqual(["podcasts"]);
    });

    test("unsubscribe is emitted as DELETE only", () => {
        expect(
            Object.keys(emitted().paths["/api/podcasts/{id}/unsubscribe"]),
        ).toEqual(["delete"]);
    });

    test("the binary episode stream stays out of the emitted file", () => {
        expect(
            emitted().paths[
                "/api/podcasts/{podcastId}/episodes/{episodeId}/stream"
            ],
        ).toBeUndefined();
        expect(getOperation("streamPodcastEpisode").responses).toEqual(
            expect.objectContaining({
                200: { binary: "audio/*" },
                206: { binary: "audio/*" },
            }),
        );
    });

    test("listPodcasts answers a bare array of subscribed podcasts", () => {
        expect(jsonSchema("/api/podcasts", "get", 200)).toEqual({
            type: "array",
            items: { $ref: "#/components/schemas/SubscribedPodcast" },
        });
    });

    test("podcast detail declares its episodes with nullable progress", () => {
        const detail = component("PodcastDetail");
        const episode = component("PodcastEpisode");

        expect(jsonSchema("/api/podcasts/{id}", "get", 200)).toEqual({
            $ref: "#/components/schemas/PodcastDetail",
        });
        expect(detail.properties.episodes.items).toEqual({
            $ref: "#/components/schemas/PodcastEpisode",
        });
        expect(episode.required).toEqual(
            expect.arrayContaining([
                "id",
                "title",
                "duration",
                "publishedAt",
                "progress",
            ]),
        );
        expect(episode.properties.publishedAt.format).toBe("date-time");
        expect(episode.properties.duration.type).toBe("integer");
        expect(episode.properties.progress.nullable).toBe(true);
    });

    test("episode progress carries position, percentage, finished flag and last play", () => {
        expect(
            Object.keys(component("EpisodeProgress").properties).sort(),
        ).toEqual(["currentTime", "isFinished", "lastPlayedAt", "progress"]);
    });

    test("request bodies declare the documented fields", () => {
        expect(
            bodyProperties(
                "/api/podcasts/{podcastId}/episodes/{episodeId}/progress",
                "post",
            ),
        ).toEqual(["currentTime", "duration", "isFinished"]);
        expect(bodyProperties("/api/podcasts/subscribe", "post")).toEqual([
            "feedUrl",
            "itunesId",
        ]);
    });

    test.each([
        ["/api/podcasts", "get", []],
        ["/api/podcasts/{id}", "get", [404]],
        ["/api/podcasts/{podcastId}/episodes/{episodeId}/progress", "post", []],
        ["/api/podcasts/subscribe", "post", [400, 404]],
        ["/api/podcasts/{id}/unsubscribe", "delete", [404]],
    ])(
        "%s %s declares the error statuses %j as ApiError",
        (path, method, statuses) => {
            for (const status of [401, 500, 503, ...statuses]) {
                expect(jsonSchema(path, method, status)).toEqual({
                    $ref: "#/components/schemas/ApiError",
                });
            }
        },
    );
});
