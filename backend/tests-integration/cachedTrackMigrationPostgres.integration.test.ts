import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { Client } from "pg";
import { createScaleDatabase, dropScaleDatabase } from "./scaleTestDatabase";

const integrationDatabaseUrl = process.env.INTEGRATION_DATABASE_URL;
const databaseName = process.env.VIBE_INTEGRATION_DATABASE;
const describeWithPostgres =
    integrationDatabaseUrl && databaseName ? describe : describe.skip;

const migrationSql = readFileSync(
    resolve(
        __dirname,
        "../prisma/migrations/20261108000000_cached_track_playback_id/migration.sql",
    ),
    "utf8",
);

// The migration only touches CachedTrack, so the test runs it against that
// table's pre-migration shape instead of the full migration chain (which
// needs pgvector). Foreign keys to User and Track are kept so the nullable
// trackId behaviour is exercised against the real constraint.
const LEGACY_TABLES = `
    CREATE TABLE "User" ("id" TEXT PRIMARY KEY);
    CREATE TABLE "Track" ("id" TEXT PRIMARY KEY);
    CREATE TABLE "CachedTrack" (
        "id" TEXT NOT NULL,
        "userId" TEXT NOT NULL,
        "trackId" TEXT NOT NULL,
        "localPath" TEXT NOT NULL,
        "quality" TEXT NOT NULL,
        "fileSizeMb" DOUBLE PRECISION NOT NULL,
        "cachedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "lastAccessedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "CachedTrack_pkey" PRIMARY KEY ("id")
    );
    CREATE UNIQUE INDEX "CachedTrack_userId_trackId_quality_key"
        ON "CachedTrack"("userId", "trackId", "quality");
    CREATE INDEX "CachedTrack_userId_idx" ON "CachedTrack"("userId");
    CREATE INDEX "CachedTrack_lastAccessedAt_idx"
        ON "CachedTrack"("lastAccessedAt");
    ALTER TABLE "CachedTrack" ADD CONSTRAINT "CachedTrack_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"("id")
        ON DELETE CASCADE ON UPDATE CASCADE;
    ALTER TABLE "CachedTrack" ADD CONSTRAINT "CachedTrack_trackId_fkey"
        FOREIGN KEY ("trackId") REFERENCES "Track"("id")
        ON DELETE CASCADE ON UPDATE CASCADE`;

async function insertRow(
    client: Client,
    row: {
        id: string;
        deviceId: string | null;
        playbackId: string;
        trackId: string | null;
        quality: string;
    },
): Promise<void> {
    await client.query(
        `INSERT INTO "CachedTrack"
            ("id", "userId", "deviceId", "playbackId", "trackId", "localPath",
             "quality", "fileSizeMb")
         VALUES ($1, 'u1', $2, $3, $4, '/cache/x', $5, 1)`,
        [row.id, row.deviceId, row.playbackId, row.trackId, row.quality],
    );
}

describeWithPostgres("CachedTrack playbackId migration (PostgreSQL)", () => {
    let admin: Client | undefined;
    let client: Client;

    beforeAll(async () => {
        admin = await createScaleDatabase(
            integrationDatabaseUrl!,
            databaseName!,
        );
        client = new Client({ connectionString: process.env.DATABASE_URL });
        await client.connect();
        await client.query(LEGACY_TABLES);
        await client.query(
            `INSERT INTO "User" ("id") VALUES ('u1'), ('u2');
             INSERT INTO "Track" ("id") VALUES ('trk1'), ('trk2');
             INSERT INTO "CachedTrack"
                ("id", "userId", "trackId", "localPath", "quality", "fileSizeMb")
             VALUES
                ('old1', 'u1', 'trk1', '/cache/1', 'high', 10),
                ('old2', 'u1', 'trk1', '/cache/1l', 'low', 4),
                ('old3', 'u2', 'trk2', '/cache/2', 'high', 10)`,
        );
        await client.query(migrationSql);
    });

    afterAll(async () => {
        await client?.end();
        if (admin && databaseName) {
            await dropScaleDatabase(admin, databaseName);
        }
    });

    it("backfills playbackId as t.<trackId> and leaves deviceId null", async () => {
        const result = await client.query(
            `SELECT "id", "deviceId", "playbackId", "trackId"
             FROM "CachedTrack" ORDER BY "id"`,
        );
        expect(result.rows).toEqual([
            { id: "old1", deviceId: null, playbackId: "t.trk1", trackId: "trk1" },
            { id: "old2", deviceId: null, playbackId: "t.trk1", trackId: "trk1" },
            { id: "old3", deviceId: null, playbackId: "t.trk2", trackId: "trk2" },
        ]);
    });

    it("makes playbackId required", async () => {
        await expect(
            client.query(
                `INSERT INTO "CachedTrack"
                    ("id", "userId", "localPath", "quality", "fileSizeMb")
                 VALUES ('nopb', 'u1', '/cache/x', 'high', 1)`,
            ),
        ).rejects.toThrow(/playbackId/);
    });

    it("inserts a remote row with a null trackId", async () => {
        await insertRow(client, {
            id: "remote1",
            deviceId: "device-a",
            playbackId: "y.abc",
            trackId: null,
            quality: "high",
        });
        const result = await client.query(
            `SELECT "trackId" FROM "CachedTrack" WHERE "id" = 'remote1'`,
        );
        expect(result.rows[0].trackId).toBeNull();
    });

    it("enforces uniqueness on userId, deviceId, playbackId and quality", async () => {
        await expect(
            insertRow(client, {
                id: "remote1-dup",
                deviceId: "device-a",
                playbackId: "y.abc",
                trackId: null,
                quality: "high",
            }),
        ).rejects.toThrow(/CachedTrack_userId_deviceId_playbackId_quality_key/);
    });

    it("allows the same item on another device or at another quality", async () => {
        await insertRow(client, {
            id: "remote1-b",
            deviceId: "device-b",
            playbackId: "y.abc",
            trackId: null,
            quality: "high",
        });
        await insertRow(client, {
            id: "remote1-low",
            deviceId: "device-a",
            playbackId: "y.abc",
            trackId: null,
            quality: "low",
        });
    });

    it("drops the old (userId, trackId, quality) unique constraint", async () => {
        await insertRow(client, {
            id: "dev-trk1",
            deviceId: "device-a",
            playbackId: "t.trk1",
            trackId: "trk1",
            quality: "high",
        });
        const indexes = await client.query<{ indexname: string }>(
            `SELECT indexname FROM pg_indexes
             WHERE tablename = 'CachedTrack' ORDER BY indexname`,
        );
        expect(indexes.rows.map((r) => r.indexname)).not.toContain(
            "CachedTrack_userId_trackId_quality_key",
        );
    });

    it("still cascades deletes from Track and User", async () => {
        await client.query(`DELETE FROM "Track" WHERE "id" = 'trk2'`);
        const gone = await client.query(
            `SELECT 1 FROM "CachedTrack" WHERE "id" = 'old3'`,
        );
        expect(gone.rowCount).toBe(0);
        await client.query(`DELETE FROM "User" WHERE "id" = 'u1'`);
        const left = await client.query(`SELECT 1 FROM "CachedTrack"`);
        expect(left.rowCount).toBe(0);
    });
});
