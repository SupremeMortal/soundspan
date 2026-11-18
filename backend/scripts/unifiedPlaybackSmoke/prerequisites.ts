import type { Socket } from "socket.io-client";
import {
    assertSmoke,
    bearer,
    fetchBounded,
    readJson,
} from "../backupRestoreSmoke/support";
import {
    asArray,
    asRecord,
    assertNoSchemaMismatch,
    connectSocket,
    type Credentials,
    send,
    sendJson,
} from "./http";

const SOCKET_DISCONNECT_TIMEOUT_MS = 15_000;

/** Lists the user's play history (`GET /api/plays`). */
async function playHistory(
    baseUrl: string,
    auth: Record<string, string>,
): Promise<Record<string, unknown>[]> {
    const response = await send(baseUrl, "GET", "/api/plays", auth);
    const body = await readJson(response);
    assertSmoke(response.status === 200, `GET /api/plays: ${response.status}`);
    return asArray(body, "plays").map((play) => asRecord(play, "play"));
}

async function assertHistoryLength(
    baseUrl: string,
    auth: Record<string, string>,
    expected: number,
    step: string,
): Promise<Record<string, unknown>[]> {
    const plays = await playHistory(baseUrl, auth);
    assertSmoke(
        plays.length === expected,
        `${step}: history has ${plays.length} plays, expected ${expected}`,
    );
    return plays;
}

async function clearHistory(
    baseUrl: string,
    auth: Record<string, string>,
): Promise<void> {
    await sendJson(
        baseUrl,
        "DELETE",
        "/api/plays/history?range=all",
        auth,
        undefined,
    );
}

/** Requests the first 100 bytes of `route`, optionally conditional on `ifRange`. */
async function rangeRequest(
    baseUrl: string,
    route: string,
    auth: Record<string, string>,
    ifRange?: string,
): Promise<{ status: number; etag: string | null }> {
    const headers: Record<string, string> = { ...auth, Range: "bytes=0-99" };
    if (ifRange !== undefined) headers["If-Range"] = ifRange;
    const response = await fetchBounded(`${baseUrl}${route}`, { headers });
    await assertNoSchemaMismatch("GET", route, response);
    await response.arrayBuffer();
    return { status: response.status, etag: response.headers.get("etag") };
}

/**
 * P7 and P8 end to end: `report=0` streams record no play, `If-Range` is
 * unaffected by the parameter, `playedAt` and `listenedMs` are stored, a
 * repeat is not double-counted, a short listen is not recorded, invalid
 * values are rejected, and an explicit play is never dropped by the stream
 * dedupe. Leaves the history empty so later steps start from zero.
 */
export async function assertPlayReporting(
    baseUrl: string,
    creds: Credentials,
    playbackId: string,
): Promise<void> {
    const auth = bearer(creds.jwt);
    const stream = `/api/playback/stream/${playbackId}?quality=original`;
    const silent = `${stream}&report=0`;

    await clearHistory(baseUrl, auth);
    await assertHistoryLength(baseUrl, auth, 0, "cleared history");

    const first = await rangeRequest(baseUrl, silent, auth);
    assertSmoke(first.status === 206, `report=0 stream: ${first.status}`);
    assertSmoke(first.etag, "report=0 stream sent no ETag");
    await assertHistoryLength(baseUrl, auth, 0, "report=0 stream");
    const silentIfRange = await rangeRequest(baseUrl, silent, auth, first.etag);
    assertSmoke(
        silentIfRange.status === 206 && silentIfRange.etag === first.etag,
        `report=0 If-Range: ${silentIfRange.status} ${String(silentIfRange.etag)}`,
    );
    await assertHistoryLength(baseUrl, auth, 0, "report=0 If-Range stream");

    const reported = await rangeRequest(baseUrl, stream, auth);
    assertSmoke(reported.status === 206, `stream: ${reported.status}`);
    await assertHistoryLength(baseUrl, auth, 1, "stream without report=0");
    const reportedIfRange = await rangeRequest(
        baseUrl,
        stream,
        auth,
        first.etag,
    );
    assertSmoke(
        reportedIfRange.status === 206 && reportedIfRange.etag === first.etag,
        `If-Range: ${reportedIfRange.status} ${String(reportedIfRange.etag)}`,
    );
    await clearHistory(baseUrl, auth);

    const playedAt = new Date(Date.now() - 60 * 60 * 1_000).toISOString();
    const timed = { playbackId, playedAt, listenedMs: 42_000 };
    const recorded = await sendJson(baseUrl, "POST", "/api/plays", auth, timed);
    assertSmoke(
        recorded.playedAt === playedAt && recorded.listenedMs === 42_000,
        `Timed play stored as ${JSON.stringify(recorded)}`,
    );
    const repeated = await sendJson(baseUrl, "POST", "/api/plays", auth, timed);
    assertSmoke(repeated.id === recorded.id, "Repeated play got a new id");
    const [held] = await assertHistoryLength(baseUrl, auth, 1, "repeat");
    assertSmoke(
        held.playedAt === playedAt && held.listenedMs === 42_000,
        `History holds ${JSON.stringify(held)}`,
    );

    const short = await sendJson(baseUrl, "POST", "/api/plays", auth, {
        playbackId,
        listenedMs: 4_999,
    });
    assertSmoke(
        short.recorded === false,
        `Short listen answered ${JSON.stringify(short)}`,
    );
    await assertHistoryLength(baseUrl, auth, 1, "short listen");

    const future = new Date(Date.now() + 10 * 60 * 1_000).toISOString();
    const invalid: Array<[Record<string, unknown>, string]> = [
        [{ playbackId, playedAt: future }, "INVALID_PLAYED_AT"],
        [{ playbackId, listenedMs: -1 }, "INVALID_LISTENED_MS"],
    ];
    for (const [body, code] of invalid) {
        const rejected = await sendJson(
            baseUrl,
            "POST",
            "/api/plays",
            auth,
            body,
            400,
        );
        assertSmoke(rejected.code === code, `Expected ${code}`);
    }
    await assertHistoryLength(baseUrl, auth, 1, "rejected plays");

    await rangeRequest(baseUrl, stream, auth);
    await assertHistoryLength(baseUrl, auth, 2, "stream before explicit play");
    await sendJson(baseUrl, "POST", "/api/plays", auth, { playbackId });
    await assertHistoryLength(baseUrl, auth, 3, "explicit play after stream");

    // An empty history keeps the 30-second stream dedupe from hiding a play
    // that a later download would wrongly record.
    await clearHistory(baseUrl, auth);
}

/**
 * Every downloadable offline item streams with `report=0`, and fetching one
 * does not record a play.
 */
export async function assertDownloadsDoNotReport(
    baseUrl: string,
    creds: Credentials,
    items: Record<string, unknown>[],
): Promise<void> {
    const auth = bearer(creds.jwt);
    const urls = items
        .filter((item) => item.downloadable === true)
        .map((item) => item.downloadUrl);
    assertSmoke(urls.length > 0, "No downloadable offline items");
    for (const url of urls) {
        assertSmoke(
            typeof url === "string" && url.includes("report=0"),
            `downloadUrl without report=0: ${String(url)}`,
        );
    }
    const before = (await playHistory(baseUrl, auth)).length;
    const download = await rangeRequest(baseUrl, urls[0] as string, auth);
    assertSmoke(download.status === 206, `Download: ${download.status}`);
    await assertHistoryLength(baseUrl, auth, before, "offline download");
}

function waitForDisconnect(socket: Socket): Promise<string> {
    return new Promise<string>((resolve, reject) => {
        const timer = setTimeout(
            () => reject(new Error("Socket was not disconnected")),
            SOCKET_DISCONNECT_TIMEOUT_MS,
        );
        socket.once("disconnect", (reason) => {
            clearTimeout(timer);
            resolve(reason);
        });
    });
}

/**
 * P6 end to end: an API key revokes itself, its socket is disconnected, it
 * stops authenticating, and the session's other key is untouched.
 */
export async function assertSelfRevoke(
    baseUrl: string,
    creds: Credentials,
): Promise<void> {
    const auth = bearer(creds.jwt);
    const created = await sendJson(
        baseUrl,
        "POST",
        "/api/api-keys",
        auth,
        { deviceName: "playback-smoke-self-revoke" },
        201,
    );
    assertSmoke(typeof created.apiKey === "string", "No second API key");
    const selfKey = { "X-API-Key": created.apiKey };

    const jwtRevoke = await sendJson(
        baseUrl,
        "DELETE",
        "/api/api-keys/current",
        auth,
        undefined,
        400,
    );
    assertSmoke(
        jwtRevoke.code === "NOT_API_KEY_SESSION",
        `JWT self-revoke code ${String(jwtRevoke.code)}`,
    );

    const socket = await connectSocket(baseUrl, created.apiKey);
    try {
        const disconnected = waitForDisconnect(socket);
        await sendJson(
            baseUrl,
            "DELETE",
            "/api/api-keys/current",
            selfKey,
            undefined,
        );
        await disconnected;
    } finally {
        socket.close();
    }

    const me = await send(baseUrl, "GET", "/api/auth/me", selfKey);
    assertSmoke(me.status === 401, `Revoked key /api/auth/me: ${me.status}`);
    await connectSocket(baseUrl, created.apiKey).then(
        (extra) => {
            extra.close();
            throw new Error("Self-revoked API key still connects");
        },
        () => undefined,
    );

    const firstMe = await send(baseUrl, "GET", "/api/auth/me", {
        "X-API-Key": creds.apiKey,
    });
    assertSmoke(
        firstMe.status === 200,
        `First key /api/auth/me: ${firstMe.status}`,
    );
    const listed = await sendJson(
        baseUrl,
        "GET",
        "/api/api-keys",
        auth,
        undefined,
    );
    const ids = asArray(listed.apiKeys, "apiKeys").map(
        (entry) => asRecord(entry, "apiKey").id,
    );
    assertSmoke(ids.includes(creds.apiKeyId), "First API key no longer listed");
}
