-- Admin offline-download policy: one switch per track source, all allowed.
ALTER TABLE "SystemSettings" ADD COLUMN "offlineAllowLocal" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "SystemSettings" ADD COLUMN "offlineAllowFederated" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "SystemSettings" ADD COLUMN "offlineAllowTidal" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "SystemSettings" ADD COLUMN "offlineAllowYtMusic" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "SystemSettings" ADD COLUMN "offlineAllowYouTube" BOOLEAN NOT NULL DEFAULT true;
