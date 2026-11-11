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
        "../prisma/migrations/20261111000000_offline_downloads_single_switch/migration.sql",
    ),
    "utf8",
);

// The migration only touches the offline and YT Music quality columns of
// SystemSettings, so it runs against just those columns' pre-migration shape.
const LEGACY_TABLE = `
    CREATE TABLE "SystemSettings" (
        "id" TEXT NOT NULL,
        "ytMusicQuality" TEXT NOT NULL DEFAULT 'HIGH',
        "offlineAllowLocal" BOOLEAN NOT NULL DEFAULT true,
        "offlineAllowFederated" BOOLEAN NOT NULL DEFAULT true,
        "offlineAllowTidal" BOOLEAN NOT NULL DEFAULT true,
        "offlineAllowYtMusic" BOOLEAN NOT NULL DEFAULT true,
        "offlineAllowYouTube" BOOLEAN NOT NULL DEFAULT true,
        CONSTRAINT "SystemSettings_pkey" PRIMARY KEY ("id")
    )`;

describeWithPostgres(
    "SystemSettings offline downloads switch migration (PostgreSQL)",
    () => {
        let admin: Client | undefined;
        let client: Client;

        beforeAll(async () => {
            admin = await createScaleDatabase(
                integrationDatabaseUrl!,
                databaseName!,
            );
            client = new Client({
                connectionString: process.env.DATABASE_URL,
            });
            await client.connect();
            await client.query(LEGACY_TABLE);
            await client.query(
                `INSERT INTO "SystemSettings"
                    ("id", "offlineAllowLocal", "offlineAllowFederated",
                     "offlineAllowTidal")
                 VALUES
                    ('all-on', true, true, true),
                    ('local-off', false, true, true),
                    ('federated-off', true, false, true),
                    ('tidal-off', true, true, false)`,
            );
            await client.query(migrationSql);
        });

        afterAll(async () => {
            await client?.end();
            if (admin && databaseName) {
                await dropScaleDatabase(admin, databaseName);
            }
        });

        it("keeps downloads off where library downloads were turned off", async () => {
            const result = await client.query(
                `SELECT "id", "offlineDownloadsEnabled"
                 FROM "SystemSettings" ORDER BY "id"`,
            );
            expect(result.rows).toEqual([
                { id: "all-on", offlineDownloadsEnabled: true },
                { id: "federated-off", offlineDownloadsEnabled: false },
                { id: "local-off", offlineDownloadsEnabled: false },
                { id: "tidal-off", offlineDownloadsEnabled: true },
            ]);
        });

        it("defaults the switch to on for new rows", async () => {
            await client.query(
                `INSERT INTO "SystemSettings" ("id") VALUES ('fresh')`,
            );
            const result = await client.query(
                `SELECT "offlineDownloadsEnabled" FROM "SystemSettings"
                 WHERE "id" = 'fresh'`,
            );
            expect(result.rows[0].offlineDownloadsEnabled).toBe(true);
        });

        it("drops the per-source switches and the admin YT Music quality", async () => {
            const result = await client.query(
                `SELECT column_name FROM information_schema.columns
                 WHERE table_name = 'SystemSettings' ORDER BY column_name`,
            );
            expect(result.rows.map((r) => r.column_name)).toEqual([
                "id",
                "offlineDownloadsEnabled",
            ]);
        });
    },
);
