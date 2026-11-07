"use client";

import {
    ProviderDefinition,
    ProviderPriorityBoard,
    SettingsSection,
} from "../ui";
import { SystemSettings } from "../../types";
import {
    ALBUM_COVER_PROVIDERS,
    ARTIST_IMAGE_PROVIDERS,
    AlbumCoverProvider,
    ArtistImageProvider,
    albumCoverProvidersUpdate,
    artistImageProvidersUpdate,
    parseProviderList,
} from "../../providerPriority";
import { FanartKeySettings, LastfmKeySettings } from "./ProviderKeySettings";

type TestService = (
    service: string,
) => Promise<{ success: boolean; version?: string; error?: string }>;

const FANART_DESCRIPTION = "High-quality artwork. Needs a Fanart.tv API key.";

const ARTIST_IMAGE_DEFS: ProviderDefinition<ArtistImageProvider>[] = [
    {
        id: "wikidata",
        label: "Wikidata",
        description: "Artist photos linked from Wikidata. No account needed.",
    },
    { id: "fanart", label: "Fanart.tv", description: FANART_DESCRIPTION },
    {
        id: "deezer",
        label: "Deezer",
        description: "Artist photos from Deezer's catalog. No account needed.",
    },
    {
        id: "lastfm",
        label: "Last.fm",
        description: "Artist images from Last.fm.",
    },
];

const ALBUM_COVER_DEFS: ProviderDefinition<AlbumCoverProvider>[] = [
    {
        id: "coverartarchive",
        label: "Cover Art Archive",
        description:
            "Covers for albums with a MusicBrainz release. No account needed.",
    },
    {
        id: "deezer",
        label: "Deezer",
        description: "Covers matched by artist and album name.",
    },
    { id: "fanart", label: "Fanart.tv", description: FANART_DESCRIPTION },
];

interface MetadataProvidersSectionProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
    onTest?: TestService;
    testingServices?: Record<string, boolean>;
}

/**
 * Admin lists that order and enable the providers tried for artist images
 * and album covers.
 */
export function MetadataProvidersSection({
    settings,
    onUpdate,
    onTest,
    testingServices = {},
}: MetadataProvidersSectionProps) {
    // Key fields render inside the Fanart.tv and Last.fm blocks of each list.
    const withKeys = <T extends string>(
        list: string,
        defs: ProviderDefinition<T>[],
    ): ProviderDefinition<T>[] =>
        defs.map((def) => {
            const keyProps = {
                settings,
                onUpdate,
                onTest,
                isTesting: testingServices[def.id] ?? false,
                idPrefix: list,
            };
            if (def.id === "fanart") {
                return {
                    ...def,
                    renderSettings: () => <FanartKeySettings {...keyProps} />,
                };
            }
            if (def.id === "lastfm") {
                return {
                    ...def,
                    renderSettings: () => <LastfmKeySettings {...keyProps} />,
                };
            }
            return def;
        });

    return (
        <>
            <SettingsSection
                id="artist-image-providers"
                title="Artist Images"
                description="Providers are tried in order until one has an image. Drag a provider into the list to use it."
            >
                <ProviderPriorityBoard
                    name="artist-images"
                    providers={withKeys("artist-images", ARTIST_IMAGE_DEFS)}
                    active={parseProviderList(
                        settings.artistImageProviders,
                        ARTIST_IMAGE_PROVIDERS,
                    )}
                    onChange={(next) =>
                        onUpdate(
                            artistImageProvidersUpdate(
                                next,
                                settings.albumCoverProviders,
                            ),
                        )
                    }
                    emptyText="No providers. Artists keep the images they already have."
                />
            </SettingsSection>

            <SettingsSection
                id="album-cover-providers"
                title="Album Covers"
                description="Providers are tried in order until one has a cover. Drag a provider into the list to use it."
            >
                <ProviderPriorityBoard
                    name="album-covers"
                    providers={withKeys("album-covers", ALBUM_COVER_DEFS)}
                    active={parseProviderList(
                        settings.albumCoverProviders,
                        ALBUM_COVER_PROVIDERS,
                    )}
                    onChange={(next) =>
                        onUpdate(
                            albumCoverProvidersUpdate(
                                next,
                                settings.artistImageProviders,
                            ),
                        )
                    }
                    emptyText="No providers. Albums keep the covers they already have."
                />
            </SettingsSection>
        </>
    );
}
