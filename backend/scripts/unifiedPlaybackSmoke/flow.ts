import crypto from "node:crypto";
import { io, type Socket } from "socket.io-client";
import {
    assertSmoke,
    bearer,
    fetchBounded,
} from "../backupRestoreSmoke/support";
import { asArray, asRecord, type Credentials, send, sendJson } from "./http";
import type { SeededLibrary } from "./fixtures";

const ADMIN_USERNAME = "playback-admin";
const ADMIN_PASSWORD = "playback-admin-password";
const PLAYBACK_DEVICE = "playback-smoke-device";

export async function bootstrapCredentials(
    baseUrl: string,
): Promise<Credentials> {
    await sendJson(
        baseUrl,
        "POST",
        "/api/onboarding/register",
        {},
        {
            username: ADMIN_USERNAME,
            password: ADMIN_PASSWORD,
        },
    );
    const login = await sendJson(
        baseUrl,
        "POST",
        "/api/auth/login",
        {},
        {
            username: ADMIN_USERNAME,
            password: ADMIN_PASSWORD,
        },
    );
    assertSmoke(typeof login.token === "string", "Login returned no token");
    const jwt = login.token;
    const created = await sendJson(
        baseUrl,
        "POST",
        "/api/api-keys",
        bearer(jwt),
        { deviceName: "playback-smoke" },
        201,
    );
    assertSmoke(typeof created.apiKey === "string", "No API key returned");
    const listed = await sendJson(
        baseUrl,
        "GET",
        "/api/api-keys",
        bearer(jwt),
        undefined,
    );
    const key = asArray(listed.apiKeys, "apiKeys")
        .map((entry) => asRecord(entry, "apiKey"))
        .find((entry) => entry.name === "playback-smoke");
    assertSmoke(key && typeof key.id === "string", "API key not listed");
    return { jwt, apiKey: created.apiKey, apiKeyId: key.id };
}

export async function assertTrackListing(
    baseUrl: string,
    creds: Credentials,
    library: SeededLibrary,
): Promise<string> {
    const listing = await sendJson(
        baseUrl,
        "GET",
        "/api/library/tracks?origin=local",
        bearer(creds.jwt),
        undefined,
    );
    const tracks = asArray(listing.tracks, "tracks").map((t) =>
        asRecord(t, "track"),
    );
    const track = tracks.find((t) => t.id === library.trackId);
    assertSmoke(track, "Seeded track missing from listing");
    assertSmoke(
        track.playbackId === `t.${library.trackId}`,
        `Unexpected playbackId ${String(track.playbackId)}`,
    );
    return track.playbackId as string;
}

async function rangeStatus(
    baseUrl: string,
    route: string,
    headers: Record<string, string>,
): Promise<{ status: number; length: number; contentRange: string | null }> {
    const response = await fetchBounded(`${baseUrl}${route}`, {
        headers: { ...headers, Range: "bytes=0-99" },
    });
    const bytes = Buffer.from(await response.arrayBuffer());
    return {
        status: response.status,
        length: bytes.length,
        contentRange: response.headers.get("content-range"),
    };
}

export async function assertStreaming(
    baseUrl: string,
    creds: Credentials,
    library: SeededLibrary,
    playbackId: string,
): Promise<void> {
    const route = `/api/playback/stream/${playbackId}?quality=original`;
    const variants: Array<[string, string, Record<string, string>]> = [
        ["Bearer", route, bearer(creds.jwt)],
        ["X-API-Key", route, { "X-API-Key": creds.apiKey }],
        ["?token=", `${route}&token=${creds.jwt}`, {}],
    ];
    for (const [label, path, headers] of variants) {
        const result = await rangeStatus(baseUrl, path, headers);
        assertSmoke(result.status === 206, `${label} stream: ${result.status}`);
        assertSmoke(result.length === 100, `${label} stream length`);
        assertSmoke(
            result.contentRange === `bytes 0-99/${library.wavBytes}`,
            `${label} Content-Range ${String(result.contentRange)}`,
        );
    }
    const unauthenticated = await rangeStatus(baseUrl, route, {});
    assertSmoke(unauthenticated.status === 401, "Unauthenticated stream");
    const info = await sendJson(
        baseUrl,
        "GET",
        `/api/playback/stream-info/${playbackId}?quality=original`,
        bearer(creds.jwt),
        undefined,
    );
    assertSmoke(info.playbackId === playbackId, "stream-info playbackId");
    assertSmoke(
        typeof info.contentType === "string",
        "stream-info contentType",
    );
    assertSmoke(info.quality === "original", "stream-info quality");
    for (const key of ["codec", "bitrate", "sampleRate", "bitDepth"]) {
        assertSmoke(key in info, `stream-info omits ${key}`);
    }
    const missing = await send(
        baseUrl,
        "GET",
        "/api/playback/stream/not-an-id",
        bearer(creds.jwt),
    );
    assertSmoke(missing.status === 400, "Malformed playbackId not 400");
}

export async function assertRemoteUnavailable(
    baseUrl: string,
    creds: Credentials,
): Promise<void> {
    for (const id of ["td.123456", "ym.dQw4w9WgXcQ"]) {
        for (const kind of ["stream", "stream-info"]) {
            const body = await sendJson(
                baseUrl,
                "GET",
                `/api/playback/${kind}/${id}`,
                bearer(creds.jwt),
                undefined,
                409,
            );
            assertSmoke(
                body.code === "SOURCE_UNAVAILABLE",
                `${kind}/${id} code ${String(body.code)}`,
            );
        }
    }
}

export async function assertWrites(
    baseUrl: string,
    creds: Credentials,
    playbackId: string,
): Promise<void> {
    const auth = bearer(creds.jwt);
    await sendJson(baseUrl, "POST", "/api/plays", auth, { playbackId });
    const playlist = await sendJson(baseUrl, "POST", "/api/playlists", auth, {
        name: "Playback Smoke",
        isPublic: false,
    });
    assertSmoke(typeof playlist.id === "string", "Playlist id missing");
    const items = `/api/playlists/${playlist.id}/items`;
    await sendJson(baseUrl, "POST", items, auth, { playbackId });
    const withTrack = await sendJson(
        baseUrl,
        "GET",
        `/api/playlists/${playlist.id}`,
        auth,
        undefined,
    );
    const held = asArray(withTrack.items, "playlist items").map((item) =>
        asRecord(item, "playlist item"),
    );
    assertSmoke(held.length === 1, `Playlist holds ${held.length} items`);
    await sendJson(
        baseUrl,
        "DELETE",
        `${items}/${playbackId}`,
        auth,
        undefined,
    );
    const emptied = await sendJson(
        baseUrl,
        "GET",
        `/api/playlists/${playlist.id}`,
        auth,
        undefined,
    );
    assertSmoke(
        asArray(emptied.items, "playlist items").length === 0,
        "Playlist item was not removed by playbackId",
    );
    const preference = await sendJson(
        baseUrl,
        "POST",
        "/api/library/preferences",
        auth,
        { playbackId, signal: "thumbs_up" },
    );
    assertSmoke(preference.playbackId === playbackId, "Preference id");
    const stateHeaders = { ...auth, "X-Playback-Device-Id": PLAYBACK_DEVICE };
    await sendJson(baseUrl, "POST", "/api/playback-state", stateHeaders, {
        playbackType: "track",
        playbackId,
        queue: [{ playbackId }],
        currentIndex: 0,
        isPlaying: false,
        currentTime: 0,
    });
    const state = await sendJson(
        baseUrl,
        "GET",
        "/api/playback-state",
        stateHeaders,
        undefined,
    );
    const queue = asArray(state.queue, "queue").map((q) =>
        asRecord(q, "queue item"),
    );
    assertSmoke(
        queue.length === 1 && queue[0].playbackId === playbackId,
        "Playback-state queue did not round-trip playbackId",
    );
}

export async function assertOffline(
    baseUrl: string,
    creds: Credentials,
    library: SeededLibrary,
    playbackId: string,
): Promise<void> {
    const auth = bearer(creds.jwt);
    const deviceId = crypto.randomUUID();
    const requested = await sendJson(
        baseUrl,
        "POST",
        "/api/offline/items",
        auth,
        {
            kind: "album",
            id: library.albumId,
            deviceId,
            quality: "original",
        },
    );
    const items = asArray(requested.items, "offline items").map((i) =>
        asRecord(i, "offline item"),
    );
    assertSmoke(items.length === 1, `Album resolved ${items.length} items`);
    assertSmoke(
        items[0].playbackId === playbackId && items[0].downloadable === true,
        `Offline item not downloadable: ${JSON.stringify(items[0])}`,
    );
    await sendJson(baseUrl, "POST", "/api/offline/items/complete", auth, {
        deviceId,
        playbackId,
        quality: "original",
        sizeBytes: library.wavBytes,
    });
    const listRoute = `/api/offline/items?deviceId=${deviceId}`;
    const held = await sendJson(baseUrl, "GET", listRoute, auth, undefined);
    const heldItems = asArray(held.items, "held items").map((i) =>
        asRecord(i, "held item"),
    );
    assertSmoke(
        heldItems.length === 1 &&
            heldItems[0].playbackId === playbackId &&
            heldItems[0].revoked === false,
        `Unexpected held items ${JSON.stringify(heldItems)}`,
    );
    await sendJson(baseUrl, "POST", "/api/system-settings", auth, {
        offlineDownloadsEnabled: false,
    });
    const revoked = await sendJson(baseUrl, "GET", listRoute, auth, undefined);
    const revokedItems = asArray(revoked.items, "revoked items").map((i) =>
        asRecord(i, "revoked item"),
    );
    assertSmoke(
        revokedItems[0]?.revoked === true,
        "Disabling offlineDownloadsEnabled did not report revoked: true",
    );
}

function connectSocket(baseUrl: string, apiKey: string): Promise<Socket> {
    return new Promise((resolve, reject) => {
        const socket = io(`${baseUrl}/listen-together`, {
            path: "/socket.io/listen-together",
            auth: { apiKey },
            transports: ["websocket"],
            reconnection: false,
            timeout: 15_000,
        });
        socket.once("connect", () => resolve(socket));
        socket.once("connect_error", (error) => {
            socket.close();
            reject(error);
        });
    });
}

export async function assertSocketApiKey(
    baseUrl: string,
    creds: Credentials,
): Promise<void> {
    const socket = await connectSocket(baseUrl, creds.apiKey);
    try {
        const disconnected = new Promise<string>((resolve, reject) => {
            const timer = setTimeout(
                () => reject(new Error("Socket was not disconnected")),
                15_000,
            );
            socket.once("disconnect", (reason) => {
                clearTimeout(timer);
                resolve(reason);
            });
        });
        const removed = await send(
            baseUrl,
            "DELETE",
            `/api/api-keys/${creds.apiKeyId}`,
            bearer(creds.jwt),
        );
        assertSmoke(removed.status === 200, `Key delete ${removed.status}`);
        await disconnected;
    } finally {
        socket.close();
    }
    await connectSocket(baseUrl, creds.apiKey).then(
        (extra) => {
            extra.close();
            throw new Error("Deleted API key still connects");
        },
        () => undefined,
    );
}
