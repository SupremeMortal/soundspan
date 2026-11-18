CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS "Playlist_name_trgm_idx"
    ON "Playlist" USING GIN (name gin_trgm_ops);
