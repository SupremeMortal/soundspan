/**
 * Guards the playbackId contract at the documentation level: any OpenAPI
 * schema that describes a track-shaped object (one that carries a legacy
 * provider identifier plus a title or stream source) must also declare `playbackId`, so a new track-returning
 * route cannot ship without it.
 *
 * To satisfy this test for a new route, add `playbackId` (type string) next to
 * `streamSource` / `tidalTrackId` / `youtubeVideoId` in its `@openapi` schema.
 * Behavioural emission coverage lives in
 * `routes/__tests__/playbackIdEmission.test.ts`.
 */
jest.mock("../../config", () => ({ config: { port: 3006 } }));

const LEGACY_TRACK_FIELDS = ["streamSource", "tidalTrackId", "youtubeVideoId"];

type Json = Record<string, unknown>;

function isObject(value: unknown): value is Json {
    return typeof value === "object" && value !== null;
}

/** Collects the JSON-pointer-like path of every offending track-shaped schema. */
function findTracksMissingPlaybackId(node: unknown, path: string): string[] {
    if (Array.isArray(node)) {
        return node.flatMap((item, index) =>
            findTracksMissingPlaybackId(item, `${path}[${index}]`),
        );
    }
    if (!isObject(node)) return [];

    const offenders: string[] = [];
    const properties = node.properties;
    if (isObject(properties)) {
        const hasLegacy = LEGACY_TRACK_FIELDS.some((f) => f in properties);
        // A bare identifier holder (e.g. `provider: { tidalTrackId, ... }`)
        // is not a track: a track also carries its own title or stream source.
        const isTrack =
            hasLegacy &&
            ("title" in properties || "streamSource" in properties);
        if (isTrack && !("playbackId" in properties)) {
            offenders.push(path);
        }
    }
    for (const [key, value] of Object.entries(node)) {
        offenders.push(...findTracksMissingPlaybackId(value, `${path}/${key}`));
    }
    return offenders;
}

describe("OpenAPI playbackId coverage", () => {
    test("every track-shaped response schema declares playbackId", () => {
        const { swaggerSpec } = require("../swagger");
        const offenders: string[] = [];

        for (const [route, methods] of Object.entries(
            (swaggerSpec.paths || {}) as Json,
        )) {
            for (const [method, operation] of Object.entries(methods as Json)) {
                if (!isObject(operation)) continue;
                offenders.push(
                    ...findTracksMissingPlaybackId(
                        operation.responses,
                        `${method.toUpperCase()} ${route}`,
                    ),
                );
            }
        }
        offenders.push(
            ...findTracksMissingPlaybackId(
                swaggerSpec.components?.schemas,
                "components.schemas",
            ),
        );

        expect(offenders).toEqual([]);
    });
});
