-- Admin-ordered provider lists. In each list, membership enables a provider
-- and the order is its priority.
--
-- playbackProviders replaces playbackSourceOrder, downloadSource and
-- primaryFailureFallback. It is an ordered, duplicate-free subset of
-- peers, tidal, ytmusic, soulseek and lidarr; the library is implicit and
-- always first.
--
-- Backfill for each existing row:
--
--   1. stream = the peers/tidal/ytmusic entries of playbackSourceOrder in
--      their stored order, followed by any of peers, tidal, ytmusic it does
--      not list (in that order).
--   2. preferred = downloadSource, then primaryFailureFallback, with youtube
--      mapped to ytmusic and none or unknown values dropped.
--   3. Walk the sequence preferred + stream + [soulseek, lidarr]. Append each
--      entry that is not already in the result. Before appending an entry of
--      stream, first append every stream entry ahead of it. This keeps the
--      peers/tidal/ytmusic order of step 1 intact (the streaming order wins
--      when it disagrees with the download settings on tidal vs ytmusic),
--      puts downloadSource ahead of primaryFailureFallback, and puts both
--      ahead of the remaining download providers.
--   4. Keep only the active providers: peers always; tidal when tidalEnabled;
--      ytmusic when ytMusicEnabled; soulseek when both soulseekUsername and
--      soulseekPassword are non-empty; lidarr when lidarrEnabled.
--
-- New rows default to peers only, matching step 4 for a fresh install where
-- every enable flag is off. The admin list shows exactly what is on, so saving
-- it through the settings API never turns on a provider the admin did not add.
--
-- artistImageProviders and albumCoverProviders replace the fixed metadata
-- image chains. Every existing row keeps the full previous chain, so image
-- lookups behave as before.
ALTER TABLE "SystemSettings" ADD COLUMN "playbackProviders" TEXT NOT NULL DEFAULT 'peers';
ALTER TABLE "SystemSettings" ADD COLUMN "artistImageProviders" TEXT NOT NULL DEFAULT 'wikidata,fanart,deezer,lastfm';
ALTER TABLE "SystemSettings" ADD COLUMN "albumCoverProviders" TEXT NOT NULL DEFAULT 'coverartarchive,deezer,fanart';

DO $$
DECLARE
    settings RECORD;
    stream TEXT[];
    preferred TEXT[];
    ordered TEXT[];
    active TEXT[];
    entry TEXT;
    ahead TEXT;
BEGIN
    FOR settings IN
        SELECT "id", "playbackSourceOrder", "downloadSource",
               "primaryFailureFallback", "tidalEnabled", "ytMusicEnabled",
               "lidarrEnabled", "soulseekUsername", "soulseekPassword"
        FROM "SystemSettings"
    LOOP
        -- Step 1: streaming order.
        stream := ARRAY[]::TEXT[];
        FOREACH entry IN ARRAY string_to_array(
            COALESCE(settings."playbackSourceOrder", ''), ','
        ) || ARRAY['peers', 'tidal', 'ytmusic']
        LOOP
            entry := btrim(entry);
            IF entry IN ('peers', 'tidal', 'ytmusic')
               AND NOT entry = ANY(stream) THEN
                stream := stream || entry;
            END IF;
        END LOOP;

        -- Step 2: configured download source, then its fallback.
        preferred := ARRAY[]::TEXT[];
        FOREACH entry IN ARRAY ARRAY[
            COALESCE(settings."downloadSource", ''),
            COALESCE(settings."primaryFailureFallback", '')
        ]
        LOOP
            entry := CASE btrim(entry)
                WHEN 'youtube' THEN 'ytmusic'
                ELSE btrim(entry)
            END;
            IF entry IN ('tidal', 'ytmusic', 'soulseek', 'lidarr')
               AND NOT entry = ANY(preferred) THEN
                preferred := preferred || entry;
            END IF;
        END LOOP;

        -- Step 3: merge, pulling earlier stream entries forward.
        ordered := ARRAY[]::TEXT[];
        FOREACH entry IN ARRAY preferred || stream || ARRAY['soulseek', 'lidarr']
        LOOP
            IF entry = ANY(stream) THEN
                FOREACH ahead IN ARRAY stream
                LOOP
                    IF NOT ahead = ANY(ordered) THEN
                        ordered := ordered || ahead;
                    END IF;
                    EXIT WHEN ahead = entry;
                END LOOP;
            ELSIF NOT entry = ANY(ordered) THEN
                ordered := ordered || entry;
            END IF;
        END LOOP;

        -- Step 4: keep the active providers.
        active := ARRAY[]::TEXT[];
        FOREACH entry IN ARRAY ordered
        LOOP
            IF entry = 'peers'
               OR (entry = 'tidal' AND settings."tidalEnabled")
               OR (entry = 'ytmusic' AND settings."ytMusicEnabled")
               OR (entry = 'lidarr' AND settings."lidarrEnabled")
               OR (entry = 'soulseek'
                   AND COALESCE(settings."soulseekUsername", '') <> ''
                   AND COALESCE(settings."soulseekPassword", '') <> '') THEN
                active := active || entry;
            END IF;
        END LOOP;

        UPDATE "SystemSettings"
        SET "playbackProviders" = array_to_string(active, ',')
        WHERE "id" = settings."id";
    END LOOP;
END $$;

ALTER TABLE "SystemSettings" DROP COLUMN "playbackSourceOrder";
ALTER TABLE "SystemSettings" DROP COLUMN "downloadSource";
ALTER TABLE "SystemSettings" DROP COLUMN "primaryFailureFallback";
