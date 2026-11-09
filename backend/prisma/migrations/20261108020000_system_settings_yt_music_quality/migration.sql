-- Admin source quality for YouTube Music downloads, same vocabulary as the per-user setting.
ALTER TABLE "SystemSettings" ADD COLUMN "ytMusicQuality" TEXT NOT NULL DEFAULT 'HIGH';
