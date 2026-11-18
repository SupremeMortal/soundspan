-- Total time a play was audibly heard, in milliseconds. NULL means not measured.
ALTER TABLE "Play" ADD COLUMN "listenedMs" INTEGER;
