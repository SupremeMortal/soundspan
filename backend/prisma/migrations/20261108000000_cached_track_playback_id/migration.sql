-- Generalize CachedTrack for source-agnostic offline storage: rows are keyed by
-- (userId, deviceId, playbackId, quality) and trackId becomes optional.

-- AlterTable
ALTER TABLE "CachedTrack" ADD COLUMN "deviceId" TEXT,
ADD COLUMN "playbackId" TEXT,
ALTER COLUMN "trackId" DROP NOT NULL;

-- Existing rows are library tracks.
UPDATE "CachedTrack" SET "playbackId" = 't.' || "trackId";

ALTER TABLE "CachedTrack" ALTER COLUMN "playbackId" SET NOT NULL;

-- DropIndex
DROP INDEX "CachedTrack_userId_trackId_quality_key";

-- CreateIndex
CREATE UNIQUE INDEX "CachedTrack_userId_deviceId_playbackId_quality_key" ON "CachedTrack"("userId", "deviceId", "playbackId", "quality");
