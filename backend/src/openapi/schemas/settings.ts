import { z } from "zod";
import { PlaybackQuality } from "./playback";

/** Loudness levelling modes a user can choose. */
export const LoudnessMode = z
    .enum(["off", "track", "album", "auto"])
    .meta({ id: "LoudnessMode" });

/**
 * The current user's settings. `hasProfilePicture` is sent by
 * `GET /api/settings` only.
 */
export const UserSettings = z
    .object({
        userId: z.string(),
        playbackQuality: PlaybackQuality,
        loudnessMode: LoudnessMode,
        maxCacheSizeMb: z.number().int(),
        shareOnlinePresence: z.boolean(),
        shareListeningStatus: z.boolean(),
        wifiOnly: z.boolean(),
        offlineEnabled: z.boolean(),
        showYtMusicExplore: z.boolean(),
        showTidalExplore: z.boolean(),
        ytMusicQuality: z.string(),
        tidalStreamingQuality: z.string(),
        displayName: z.string().nullable(),
        hasProfilePicture: z.boolean().optional(),
    })
    .meta({ id: "UserSettings" });

/**
 * Body of `POST /api/settings`. Omitted fields keep their stored value.
 */
export const UpdateSettingsRequest = z
    .object({
        playbackQuality: PlaybackQuality.optional(),
        loudnessMode: LoudnessMode.optional(),
        maxCacheSizeMb: z.number().int().min(0).optional(),
    })
    .meta({ id: "UpdateSettingsRequest" });
