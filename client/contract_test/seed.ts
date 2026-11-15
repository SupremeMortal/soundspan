// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Seeds a fresh contract server (compose.yaml) and writes
// .seed/credentials.json for the contract tests. Runs on Node 24 with its
// built-in type stripping and no dependencies:
//
//   node client/contract_test/seed.ts
//
// Every step asserts its response; the first failed assertion exits 1.
// CONTRACT_BASE_URL overrides the server address.

import { createHmac } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const baseUrl = (
    process.env.CONTRACT_BASE_URL ?? "http://127.0.0.1:13006"
).replace(/\/+$/, "");
const here = import.meta.dirname;

interface Account {
    username: string;
    password: string;
}

const admin: Account = { username: "admin", password: "contract-admin-pw" };
const listener: Account = {
    username: "listener",
    password: "contract-listener-pw",
};
const twofa: Account = { username: "twofa", password: "contract-twofa-pw" };

interface Library {
    artists: { name: string; albums: { title: string; tracks: unknown[] }[] }[];
}

const library = JSON.parse(
    readFileSync(join(here, "fixtures", "library.json"), "utf8"),
) as Library;
const expectedArtists = library.artists.length;
const expectedAlbums = library.artists.flatMap((a) => a.albums).length;
const expectedTracks = library.artists
    .flatMap((a) => a.albums)
    .flatMap((album) => album.tracks).length;

function assert(condition: unknown, message: string): asserts condition {
    if (!condition) {
        throw new Error(`assertion failed: ${message}`);
    }
}

function ok(message: string): void {
    console.log(`seed: ok - ${message}`);
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

interface Reply {
    status: number;
    body: any;
}

async function call(
    method: string,
    path: string,
    options: { token?: string; body?: unknown } = {},
): Promise<Reply> {
    const headers: Record<string, string> = {
        "user-agent": "soundspan-contract-seed",
    };
    if (options.token) headers.authorization = `Bearer ${options.token}`;
    if (options.body !== undefined)
        headers["content-type"] = "application/json";
    const response = await fetch(`${baseUrl}${path}`, {
        method,
        headers,
        body:
            options.body === undefined
                ? undefined
                : JSON.stringify(options.body),
    });
    const text = await response.text();
    let body: any = text;
    try {
        body = text.length > 0 ? JSON.parse(text) : null;
    } catch {
        // Plain-text bodies (rate limits) stay strings.
    }
    if (
        body &&
        typeof body === "object" &&
        body.code === "RESPONSE_SCHEMA_MISMATCH"
    ) {
        throw new Error(
            `${method} ${path} answered RESPONSE_SCHEMA_MISMATCH: ${JSON.stringify(body)}`,
        );
    }
    return { status: response.status, body };
}

async function expectOk(
    method: string,
    path: string,
    options: { token?: string; body?: unknown } = {},
): Promise<any> {
    const reply = await call(method, path, options);
    assert(
        reply.status >= 200 && reply.status < 300,
        `${method} ${path} answered ${reply.status}: ${JSON.stringify(reply.body)}`,
    );
    return reply.body;
}

async function signIn(account: Account): Promise<string> {
    const body = await expectOk("POST", "/api/auth/login", { body: account });
    assert(
        typeof body.token === "string",
        `${account.username} received a token`,
    );
    return body.token;
}

/** RFC 4648 base32 without padding. */
function base32Decode(input: string): Buffer {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    const clean = input.toUpperCase().replace(/=+$/, "").replace(/\s+/g, "");
    let bits = 0;
    let value = 0;
    const bytes: number[] = [];
    for (const char of clean) {
        const index = alphabet.indexOf(char);
        assert(index >= 0, `TOTP secret is base32 (found "${char}")`);
        value = (value << 5) | index;
        bits += 5;
        if (bits >= 8) {
            bytes.push((value >>> (bits - 8)) & 0xff);
            bits -= 8;
        }
    }
    return Buffer.from(bytes);
}

/** RFC 6238 TOTP: HMAC-SHA1, 30-second steps, 6 digits. */
function totp(secret: string, now = Date.now()): string {
    const counter = Buffer.alloc(8);
    counter.writeBigUInt64BE(BigInt(Math.floor(now / 1000 / 30)));
    const hmac = createHmac("sha1", base32Decode(secret))
        .update(counter)
        .digest();
    const offset = hmac[hmac.length - 1] & 0x0f;
    const code = (hmac.readUInt32BE(offset) & 0x7fffffff) % 1_000_000;
    return code.toString().padStart(6, "0");
}

async function waitForStartup(): Promise<void> {
    const deadline = Date.now() + 3 * 60_000;
    let last = "no answer";
    while (Date.now() < deadline) {
        try {
            const reply = await call("GET", "/api/health");
            if (reply.status === 200 && reply.body?.startupComplete === true) {
                ok(
                    `GET /api/health reports start-up complete (${reply.body.version})`,
                );
                return;
            }
            last = `${reply.status} ${JSON.stringify(reply.body)}`;
        } catch (error) {
            last = String(error);
        }
        await sleep(2_000);
    }
    throw new Error(`server did not finish start-up within 3 minutes: ${last}`);
}

async function scanLibrary(adminToken: string): Promise<void> {
    const deadline = Date.now() + 5 * 60_000;
    let jobId: string | undefined;
    while (jobId === undefined) {
        const reply = await call("POST", "/api/library/scan", {
            token: adminToken,
        });
        if (reply.status === 200 && typeof reply.body?.jobId === "string") {
            jobId = reply.body.jobId;
        } else {
            // 429 while a start-up maintenance cooldown runs; retry.
            assert(
                reply.status === 429 && Date.now() < deadline,
                `POST /api/library/scan answered ${reply.status}: ${JSON.stringify(reply.body)}`,
            );
            await sleep(5_000);
        }
    }
    ok(`POST /api/library/scan started job ${jobId}`);
    let state = "unknown";
    while (Date.now() < deadline) {
        const reply = await call(
            "GET",
            `/api/library/scan/status/${encodeURIComponent(jobId)}`,
            { token: adminToken },
        );
        assert(
            reply.status === 200,
            `scan status answered ${reply.status}: ${JSON.stringify(reply.body)}`,
        );
        state = reply.body.status;
        assert(
            state !== "failed",
            `scan job failed: ${JSON.stringify(reply.body)}`,
        );
        if (state === "completed") {
            ok(`scan job completed: ${JSON.stringify(reply.body.result)}`);
            return;
        }
        await sleep(2_000);
    }
    throw new Error(
        `scan did not complete within 5 minutes (last state ${state})`,
    );
}

async function total(path: string, token: string): Promise<number> {
    const body = await expectOk("GET", path, { token });
    assert(Number.isInteger(body.total), `${path} has a total`);
    return body.total;
}

async function main(): Promise<void> {
    console.log(`seed: contract server ${baseUrl}`);

    // 1. Start-up.
    await waitForStartup();

    // 2. A fresh server needs onboarding.
    const status = await expectOk("GET", "/api/onboarding/status");
    assert(
        status.needsOnboarding === true,
        "needsOnboarding is true on a fresh server",
    );
    ok("GET /api/onboarding/status reports needsOnboarding: true");

    // 3. The first account becomes the admin.
    const registered = await expectOk("POST", "/api/onboarding/register", {
        body: admin,
    });
    assert(registered.user?.role === "admin", "the first account is an admin");
    await expectOk("POST", "/api/onboarding/complete", {
        token: registered.token,
    });
    const adminToken = await signIn(admin);
    const after = await expectOk("GET", "/api/onboarding/status");
    assert(after.needsOnboarding === false, "onboarding is complete");
    ok("registered and completed onboarding as admin");

    // 4. Two more accounts.
    for (const account of [listener, twofa]) {
        const created = await expectOk("POST", "/api/auth/create-user", {
            token: adminToken,
            body: { ...account, role: "user" },
        });
        assert(
            created.username === account.username && created.role === "user",
            `created ${account.username} with role user`,
        );
        ok(`created user ${account.username}`);
    }

    // 5. Enable 2FA for twofa.
    const twofaToken = await signIn(twofa);
    const setup = await expectOk("POST", "/api/auth/2fa/setup", {
        token: twofaToken,
    });
    assert(typeof setup.secret === "string", "2FA setup returned a secret");
    const totpSecret: string = setup.secret;
    await expectOk("POST", "/api/auth/2fa/enable", {
        token: twofaToken,
        body: { secret: totpSecret, token: totp(totpSecret) },
    });
    const challenge = await expectOk("POST", "/api/auth/login", {
        body: twofa,
    });
    assert(
        challenge.requires2FA === true,
        "twofa's password login asks for a code",
    );
    ok("enabled 2FA for twofa; password login now answers requires2FA");

    // 6. Scan the fixture library.
    await scanLibrary(adminToken);
    const artists = await total("/api/library/artists?limit=1", adminToken);
    const albums = await total("/api/library/albums?limit=1", adminToken);
    const tracks = await total("/api/library/tracks?limit=1", adminToken);
    assert(
        artists === expectedArtists,
        `${expectedArtists} artists (found ${artists})`,
    );
    assert(
        albums === expectedAlbums,
        `${expectedAlbums} albums (found ${albums})`,
    );
    assert(
        tracks === expectedTracks,
        `${expectedTracks} tracks (found ${tracks})`,
    );
    ok(`library has ${artists} artists, ${albums} albums, ${tracks} tracks`);

    // 7. A playlist of five tracks for listener.
    const listenerToken = await signIn(listener);
    const page = await expectOk("GET", "/api/library/tracks?limit=5&offset=0", {
        token: listenerToken,
    });
    const playbackIds: string[] = page.tracks.map(
        (track: any) => track.playbackId,
    );
    assert(
        playbackIds.length === 5 &&
            playbackIds.every((id) => typeof id === "string"),
        "five tracks with a playbackId",
    );
    const playlist = await expectOk("POST", "/api/playlists", {
        token: listenerToken,
        body: { name: "Contract Playlist" },
    });
    assert(typeof playlist.id === "string", "the playlist has an id");
    for (const playbackId of playbackIds) {
        await expectOk(
            "POST",
            `/api/playlists/${encodeURIComponent(playlist.id)}/items`,
            {
                token: listenerToken,
                body: { playbackId },
            },
        );
    }
    const detail = await expectOk(
        "GET",
        `/api/playlists/${encodeURIComponent(playlist.id)}`,
        { token: listenerToken },
    );
    const items: unknown[] = detail.items ?? detail.tracks ?? [];
    assert(
        items.length === 5,
        `the playlist holds 5 items (found ${items.length})`,
    );
    ok(`listener's playlist ${playlist.id} holds 5 tracks`);

    // 8. Three liked tracks and one recorded play for listener, so the liked
    // list pages and Continue Listening is not empty.
    const likedPage = await expectOk(
        "GET",
        "/api/library/tracks?limit=3&offset=5",
        { token: listenerToken },
    );
    const likedIds: string[] = likedPage.tracks.map(
        (track: any) => track.playbackId,
    );
    assert(
        likedIds.length === 3 && likedIds.every((id) => typeof id === "string"),
        "three more tracks with a playbackId",
    );
    for (const playbackId of likedIds) {
        const liked = await expectOk("POST", "/api/library/preferences", {
            token: listenerToken,
            body: { playbackId, signal: "thumbs_up" },
        });
        assert(liked.state === "liked", `${playbackId} is liked`);
    }
    const likedTotal = await total("/api/library/liked?limit=1", listenerToken);
    assert(likedTotal === 3, `3 liked tracks (found ${likedTotal})`);
    ok("listener likes 3 tracks");
    await expectOk("POST", "/api/plays", {
        token: listenerToken,
        body: { playbackId: playbackIds[0], listenedMs: 30_000 },
    });
    const recent = await expectOk(
        "GET",
        "/api/library/recently-listened?limit=5",
        { token: listenerToken },
    );
    assert(
        Array.isArray(recent.items) && recent.items.length > 0,
        `recently listened is not empty (found ${JSON.stringify(recent.items)})`,
    );
    ok("listener has a recorded play; recently listened is not empty");

    // 9. A playbackId of a disabled source. The seed is server-side fixture
    // code and may compose it; client code treats playbackIds as opaque.
    let unavailablePlaybackId: string | null = null;
    const probe = await call("GET", "/api/playback/stream/td.1", {
        token: listenerToken,
    });
    if (probe.status === 409 && probe.body?.code === "SOURCE_UNAVAILABLE") {
        unavailablePlaybackId = "td.1";
        ok("GET /api/playback/stream/td.1 answers 409 SOURCE_UNAVAILABLE");
    } else {
        console.warn(
            `seed: warning - td.1 answered ${probe.status} ${JSON.stringify(probe.body)}; ` +
                "unavailablePlaybackId is null and its cases skip",
        );
    }

    // 10. The fixture podcast for listener: compose.yaml's podcast-feed
    // serves the feed and its two episodes.
    const podcastFeedUrl = "http://podcast-feed/feed.xml";
    const subscribed = await expectOk("POST", "/api/podcasts/subscribe", {
        token: listenerToken,
        body: { feedUrl: podcastFeedUrl },
    });
    assert(
        typeof subscribed.podcast?.id === "string",
        "the subscribed podcast has an id",
    );
    const podcastDetail = await expectOk(
        "GET",
        `/api/podcasts/${encodeURIComponent(subscribed.podcast.id)}`,
        { token: listenerToken },
    );
    const episodes: unknown[] = podcastDetail.episodes ?? [];
    assert(
        episodes.length >= 2,
        `the podcast has at least 2 episodes (found ${episodes.length})`,
    );
    ok(
        `listener subscribes ${podcastFeedUrl} with ${episodes.length} episodes`,
    );

    // 11. Credentials for the tests.
    const credentials = {
        baseUrl,
        admin,
        listener,
        twofa,
        totpSecret,
        playlistId: playlist.id,
        unavailablePlaybackId,
    };
    const dir = join(here, ".seed");
    mkdirSync(dir, { recursive: true });
    writeFileSync(
        join(dir, "credentials.json"),
        `${JSON.stringify(credentials, null, 2)}\n`,
    );
    ok(`wrote ${join(dir, "credentials.json")}`);
}

main().catch((error: unknown) => {
    console.error(
        `seed: FAILED - ${error instanceof Error ? error.message : String(error)}`,
    );
    process.exit(1);
});
