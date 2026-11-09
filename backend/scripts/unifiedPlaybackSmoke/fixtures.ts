import fs from "node:fs/promises";
import path from "node:path";
import { Client } from "pg";
import { assertSmoke, runCommand } from "../backupRestoreSmoke/support";
import { databaseUrl } from "../backupRestoreSmoke/database";

export const SMOKE_DATABASE = "smoke_unified_playback";
export const TRACK_FILE = "smoke/unified-playback.wav";
const SAMPLE_RATE = 8_000;
const DURATION_SECONDS = 2;

/** Builds a mono 16-bit PCM WAV of silence, so no encoder is needed. */
export function silentWav(): Buffer {
    const dataBytes = SAMPLE_RATE * DURATION_SECONDS * 2;
    const header = Buffer.alloc(44);
    header.write("RIFF", 0);
    header.writeUInt32LE(36 + dataBytes, 4);
    header.write("WAVEfmt ", 8);
    header.writeUInt32LE(16, 16);
    header.writeUInt16LE(1, 20);
    header.writeUInt16LE(1, 22);
    header.writeUInt32LE(SAMPLE_RATE, 24);
    header.writeUInt32LE(SAMPLE_RATE * 2, 28);
    header.writeUInt16LE(2, 32);
    header.writeUInt16LE(16, 34);
    header.write("data", 36);
    header.writeUInt32LE(dataBytes, 40);
    return Buffer.concat([header, Buffer.alloc(dataBytes)]);
}

export async function recreateDatabase(adminUrl: string): Promise<string> {
    const client = new Client({ connectionString: adminUrl });
    await client.connect();
    try {
        await client.query(
            `DROP DATABASE IF EXISTS "${SMOKE_DATABASE}" WITH (FORCE)`,
        );
        await client.query(`CREATE DATABASE "${SMOKE_DATABASE}"`);
    } finally {
        await client.end();
    }
    return databaseUrl(adminUrl, SMOKE_DATABASE);
}

export async function migrate(backendRoot: string, url: string): Promise<void> {
    await runCommand(
        `${backendRoot}/node_modules/.bin/prisma`,
        ["migrate", "deploy"],
        {
            cwd: backendRoot,
            env: { ...process.env, DATABASE_URL: url },
            timeoutMs: 5 * 60 * 1_000,
        },
    );
}

export interface SeededLibrary {
    albumId: string;
    trackId: string;
    wavBytes: number;
}

/** Writes the audio fixture under the music path and inserts its rows. */
export async function seedLibrary(
    url: string,
    musicRoot: string,
): Promise<SeededLibrary> {
    const wav = silentWav();
    const target = path.join(musicRoot, TRACK_FILE);
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, wav);
    const client = new Client({ connectionString: url });
    await client.connect();
    try {
        await client.query(`
            INSERT INTO "Artist" (id, mbid, name)
            VALUES ('up-artist', 'up-artist-mbid', 'Playback Artist')
        `);
        await client.query(`
            INSERT INTO "Album" (id, "rgMbid", "artistId", title, "primaryType")
            VALUES ('up-album', 'up-album-mbid', 'up-artist', 'Playback Album', 'Album')
        `);
        const inserted = await client.query<{ id: string }>(
            `INSERT INTO "Track"
                (id, "albumId", title, "trackNo", duration, "filePath", mime,
                 "fileModified", "fileSize", "updatedAt")
             VALUES ('up-track', 'up-album', 'Playback Track', 1, $1, $2, 'audio/wav',
                     now(), $3, now())
             RETURNING id`,
            [DURATION_SECONDS, TRACK_FILE, wav.length],
        );
        assertSmoke(inserted.rows.length === 1, "Track seed failed");
    } finally {
        await client.end();
    }
    return { albumId: "up-album", trackId: "up-track", wavBytes: wav.length };
}
