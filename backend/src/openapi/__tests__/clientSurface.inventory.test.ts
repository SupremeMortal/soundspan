import { clientSurfaceOperations, type ClientSurface } from "../clientSurface";

/**
 * The endpoint inventory of docs/designs/flutter-client/03-api-layer.md, as
 * `METHOD path` pairs. `GET /library/cover-art[/:id]` is two operations.
 */
const INVENTORY = [
    // Connection and session
    "GET /api/health",
    "GET /api/auth/config",
    "GET /api/onboarding/status",
    "POST /api/auth/login",
    "POST /api/auth/refresh",
    "POST /api/auth/logout",
    "GET /api/auth/me",
    "POST /api/device-link/verify",
    "GET /api/api-keys",
    "DELETE /api/api-keys/current",
    "GET /api/docs.json",
    "GET /api/system/features",
    "GET /api/settings",
    "POST /api/settings",
    // Library and browse
    "GET /api/library/artists",
    "GET /api/library/artists/{id}",
    "GET /api/library/albums",
    "GET /api/library/albums/{id}",
    "GET /api/library/tracks",
    "GET /api/library/tracks/shuffle",
    "GET /api/library/liked",
    "POST /api/library/preferences",
    "POST /api/library/albums/{id}/preference",
    "GET /api/library/recently-listened",
    "GET /api/library/recently-added",
    "GET /api/library/cover-art",
    "GET /api/library/cover-art/{id}",
    "GET /api/playlists",
    "GET /api/playlists/{id}",
    "POST /api/playlists",
    "PUT /api/playlists/{id}",
    "DELETE /api/playlists/{id}",
    "POST /api/playlists/{id}/items",
    "DELETE /api/playlists/{id}/items/{playbackId}",
    "PUT /api/playlists/{id}/items/reorder",
    "GET /api/search",
    "GET /api/search/discover",
    "GET /api/search/unified",
    // Playback, plays, state, lyrics
    "GET /api/playback/stream/{playbackId}",
    "GET /api/playback/stream-info/{playbackId}",
    "POST /api/plays",
    "GET /api/playback-state",
    "POST /api/playback-state",
    "DELETE /api/playback-state",
    "GET /api/lyrics/{trackId}",
    // Offline
    "POST /api/offline/items",
    "POST /api/offline/items/complete",
    "DELETE /api/offline/items",
    "GET /api/offline/items",
    "GET /api/offline/stats",
    // Podcasts
    "GET /api/podcasts",
    "GET /api/podcasts/{id}",
    "GET /api/podcasts/{podcastId}/episodes/{episodeId}/stream",
    "POST /api/podcasts/{podcastId}/episodes/{episodeId}/progress",
    "GET /api/podcasts/discover/top",
    "POST /api/podcasts/subscribe",
    "DELETE /api/podcasts/{id}/unsubscribe",
    // Home, discovery, social
    "GET /api/mixes",
    "GET /api/mixes/{id}",
    "GET /api/recommendations/for-you",
    "GET /api/discover/current",
    "GET /api/discover/popular-artists",
    "GET /api/library/radio",
    "GET /api/library/genres",
    "GET /api/library/decades",
    "GET /api/vibe/similar/{trackId}",
    "POST /api/vibe/search",
    "POST /api/listen-together",
    "POST /api/listen-together/join",
    "GET /api/listen-together/discover",
    "GET /api/listen-together/mine",
    "POST /api/listen-together/{groupId}/leave",
    "POST /api/listen-together/{groupId}/end",
    "POST /api/social/presence/heartbeat",
    "GET /api/social/online",
];

function registeredPairs(surface: ClientSurface): string[] {
    return surface
        .map(({ method, path }) => `${method.toUpperCase()} ${path}`)
        .sort();
}

describe("the client surface equals the doc 03 endpoint inventory", () => {
    test("the inventory lists each operation once", () => {
        expect(new Set(INVENTORY).size).toBe(INVENTORY.length);
    });

    test("every registered operation is in the inventory and every inventory row is registered", () => {
        expect(registeredPairs(clientSurfaceOperations)).toEqual(
            [...INVENTORY].sort(),
        );
    });

    test("adding or removing a registration breaks the equality", () => {
        const [first, ...rest] = clientSurfaceOperations;
        const extra = { ...first, path: "/api/listen-together/active-count" };

        expect(registeredPairs(rest)).not.toEqual([...INVENTORY].sort());
        expect(
            registeredPairs([...clientSurfaceOperations, extra]),
        ).not.toEqual([...INVENTORY].sort());
    });
});
