import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { Client } from "pg";
import { prisma } from "../src/utils/db";
import {
    applyScaleMigrations,
    createScaleDatabase,
    dropScaleDatabase,
} from "./scaleTestDatabase";

const integrationDatabaseUrl = process.env.INTEGRATION_DATABASE_URL;
const databaseName = process.env.VIBE_INTEGRATION_DATABASE;
const describeWithPostgres =
    integrationDatabaseUrl && databaseName ? describe : describe.skip;

const migrationSql = readFileSync(
    resolve(
        __dirname,
        "../prisma/migrations/20261114000000_play_listened_ms/migration.sql",
    ),
    "utf8",
);

const MAX_LISTENED_MS = 86_400_000;

// The pre-migration shape of "Play", in its own schema so the full Prisma
// migration chain can own "public" for the idempotency lookup below.
const LEGACY_TABLE = `
    CREATE TABLE "Play" (
        "id" TEXT NOT NULL,
        "userId" TEXT NOT NULL,
        "trackId" TEXT,
        "trackTidalId" TEXT,
        "trackYtMusicId" TEXT,
        "playedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "source" TEXT NOT NULL DEFAULT 'LIBRARY',
        CONSTRAINT "Play_pkey" PRIMARY KEY ("id")
    )`;

describeWithPostgres("Play.listenedMs migration (PostgreSQL)", () => {
    let admin: Client | undefined;
    let legacy: Client;

    beforeAll(async () => {
        admin = await createScaleDatabase(
            integrationDatabaseUrl!,
            databaseName!,
        );
        legacy = new Client({ connectionString: process.env.DATABASE_URL });
        await legacy.connect();
        await legacy.query(`CREATE SCHEMA "legacy_play"`);
        await legacy.query(`SET search_path TO "legacy_play"`);
        await legacy.query(LEGACY_TABLE);
        await legacy.query(
            `INSERT INTO "Play" ("id", "userId", "trackId")
             VALUES ('old-1', 'user-1', 'track-1'),
                    ('old-2', 'user-1', 'track-2')`,
        );
        await legacy.query(migrationSql);
        await applyScaleMigrations(process.env.DATABASE_URL!);
    });

    afterAll(async () => {
        await legacy?.end();
        await prisma.$disconnect();
        if (admin && databaseName) {
            await dropScaleDatabase(admin, databaseName);
        }
    });

    it("reads existing rows back with listenedMs NULL", async () => {
        const result = await legacy.query(
            `SELECT "id", "listenedMs" FROM "Play" ORDER BY "id"`,
        );
        expect(result.rows).toEqual([
            { id: "old-1", listenedMs: null },
            { id: "old-2", listenedMs: null },
        ]);
    });

    it("stores an integer up to the largest allowed value", async () => {
        await legacy.query(
            `INSERT INTO "Play" ("id", "userId", "listenedMs")
             VALUES ('new-1', 'user-1', 42000), ('new-max', 'user-1', $1)`,
            [MAX_LISTENED_MS],
        );
        const result = await legacy.query(
            `SELECT "id", "listenedMs" FROM "Play"
             WHERE "id" IN ('new-1', 'new-max') ORDER BY "id"`,
        );
        expect(result.rows).toEqual([
            { id: "new-1", listenedMs: 42_000 },
            { id: "new-max", listenedMs: MAX_LISTENED_MS },
        ]);
    });

    it("finds a play by (userId, trackId, playedAt) at millisecond precision", async () => {
        await prisma.user.create({
            data: { id: "listened-user", username: "listened-user" },
        });
        await prisma.artist.create({
            data: {
                id: "listened-artist",
                mbid: "listened-artist-mbid",
                name: "Artist",
            },
        });
        await prisma.album.create({
            data: {
                id: "listened-album",
                rgMbid: "listened-album-mbid",
                artistId: "listened-artist",
                title: "Album",
                primaryType: "Album",
            },
        });
        await prisma.track.create({
            data: {
                id: "listened-track",
                albumId: "listened-album",
                title: "Song",
                trackNo: 1,
                duration: 215,
                fileModified: new Date("2026-08-25T00:00:00.000Z"),
                fileSize: 1_000,
            },
        });
        const playedAt = new Date("2026-03-15T11:59:58.123Z");
        const created = await prisma.play.create({
            data: {
                userId: "listened-user",
                trackId: "listened-track",
                source: "LIBRARY",
                playedAt,
                listenedMs: MAX_LISTENED_MS,
            },
        });

        const found = await prisma.play.findMany({
            where: {
                userId: "listened-user",
                trackId: "listened-track",
                playedAt: new Date(playedAt.toISOString()),
            },
        });

        expect(found).toHaveLength(1);
        expect(found[0].id).toBe(created.id);
        expect(found[0].playedAt.toISOString()).toBe(
            "2026-03-15T11:59:58.123Z",
        );
        expect(found[0].listenedMs).toBe(MAX_LISTENED_MS);
    });
});
