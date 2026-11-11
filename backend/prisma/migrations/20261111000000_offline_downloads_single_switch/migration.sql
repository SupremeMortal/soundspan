-- Replace the per-source offline-download switches with one switch that
-- applies to every track source, and drop the unused admin YT Music quality.

-- AlterTable
ALTER TABLE "SystemSettings" ADD COLUMN "offlineDownloadsEnabled" BOOLEAN NOT NULL DEFAULT true;

-- Keep downloads off where an admin had turned library downloads off.
UPDATE "SystemSettings"
SET "offlineDownloadsEnabled" = "offlineAllowLocal" AND "offlineAllowFederated";

-- AlterTable
ALTER TABLE "SystemSettings" DROP COLUMN "offlineAllowLocal",
DROP COLUMN "offlineAllowFederated",
DROP COLUMN "offlineAllowTidal",
DROP COLUMN "offlineAllowYtMusic",
DROP COLUMN "offlineAllowYouTube",
DROP COLUMN "ytMusicQuality";
