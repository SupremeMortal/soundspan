import { z } from "zod";
import { prisma } from "../utils/db";
import {
    fanartEnabledFor,
    metadataProviderFields,
} from "./metadataProviderSettings";
import {
    isPlaybackProviderActive,
    isPlaybackProviderList,
    playbackProviderEnableFlags,
} from "./playbackSourcePriority";

/** System-settings API fields for every admin-ordered provider list. */
export const providerListFields = {
    playbackProviders: z
        .string()
        .refine(isPlaybackProviderList, "Invalid playback providers")
        .optional(),
    ...metadataProviderFields,
};

/** Settings-update fields that the provider lists read and write. */
export interface ProviderListUpdate {
    playbackProviders?: string;
    artistImageProviders?: string;
    albumCoverProviders?: string;
    lidarrEnabled?: boolean;
    tidalEnabled?: boolean;
    ytMusicEnabled?: boolean;
    fanartEnabled?: boolean;
}

/** Stored metadata lists, read when an update changes only one of them. */
export type StoredMetadataProviderLists = {
    artistImageProviders?: string | null;
    albumCoverProviders?: string | null;
} | null;

function loadStoredMetadataProviderLists(): Promise<StoredMetadataProviderLists> {
    return prisma.systemSettings.findUnique({
        where: { id: "default" },
        select: { artistImageProviders: true, albumCoverProviders: true },
    });
}

/** Returns whether an update takes Soulseek out of the provider list. */
export function removesSoulseek(data: ProviderListUpdate): boolean {
    return (
        data.playbackProviders !== undefined &&
        !isPlaybackProviderActive(data.playbackProviders, "soulseek")
    );
}

/**
 * Makes provider-list membership the enable switch. When an update carries
 * `playbackProviders`, the Lidarr, TIDAL and YouTube Music flags follow
 * membership. When it carries either metadata list, `fanartEnabled` follows
 * whether Fanart.tv is in either resulting list. Membership overrides a
 * conflicting flag in the same update.
 */
export async function applyProviderListEnablement<T extends ProviderListUpdate>(
    data: T,
    loadStoredMetadataLists: () => Promise<StoredMetadataProviderLists> = loadStoredMetadataProviderLists,
): Promise<T> {
    const result: T = { ...data };
    if (data.playbackProviders !== undefined) {
        Object.assign(
            result,
            playbackProviderEnableFlags(data.playbackProviders),
        );
    }
    const artist = data.artistImageProviders;
    const album = data.albumCoverProviders;
    if (artist === undefined && album === undefined) return result;
    const stored =
        artist === undefined || album === undefined
            ? await loadStoredMetadataLists()
            : null;
    result.fanartEnabled = fanartEnabledFor(
        artist ?? stored?.artistImageProviders,
        album ?? stored?.albumCoverProviders,
    );
    return result;
}
