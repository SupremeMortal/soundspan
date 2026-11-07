"use client";

import {
    ProviderDefinition,
    ProviderPriorityBoard,
    SettingsSection,
} from "../ui";
import { SystemSettings } from "../../types";
import {
    SEARCH_PROVIDERS,
    SearchProvider,
    parseProviderList,
    searchProvidersUpdate,
} from "../../providerPriority";
import { LastfmKeySettings } from "./ProviderKeySettings";

type TestService = (
    service: string,
) => Promise<{ success: boolean; version?: string; error?: string }>;

const DEFAULT_ENABLED = "lastfm,deezer";

const PROVIDERS: ProviderDefinition<SearchProvider>[] = [
    {
        id: "lastfm",
        label: "Last.fm",
        description:
            "Artists and songs. Also corrects misspelled artist names.",
    },
    {
        id: "deezer",
        label: "Deezer",
        description:
            "Artists and songs from Deezer's public catalog, including new releases. No account needed.",
    },
    {
        id: "tidal",
        label: "TIDAL",
        description:
            "Artists and songs that play straight from TIDAL. Used only for users with a TIDAL session.",
    },
    {
        id: "youtube",
        label: "YouTube Music",
        description:
            "Songs that play straight from YouTube Music, while it is in the Playback provider list.",
    },
];

interface SearchProvidersSectionProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
    onTest?: TestService;
    testingServices?: Record<string, boolean>;
}

/**
 * Admin list that orders and enables the catalog providers behind Search's
 * Discover results.
 */
export function SearchProvidersSection({
    settings,
    onUpdate,
    onTest,
    testingServices = {},
}: SearchProvidersSectionProps) {
    const providers = PROVIDERS.map((def) =>
        def.id === "lastfm"
            ? {
                  ...def,
                  renderSettings: () => (
                      <LastfmKeySettings
                          settings={settings}
                          onUpdate={onUpdate}
                          onTest={onTest}
                          isTesting={testingServices.lastfm ?? false}
                          idPrefix="search"
                      />
                  ),
              }
            : def,
    );
    const enabled = new Set(
        parseProviderList(
            settings.searchProvidersEnabled ?? DEFAULT_ENABLED,
            SEARCH_PROVIDERS,
        ),
    );
    const order = parseProviderList(
        settings.searchProviderOrder,
        SEARCH_PROVIDERS,
    );
    const active = [...order, ...SEARCH_PROVIDERS].filter(
        (provider, index, all) =>
            enabled.has(provider) && all.indexOf(provider) === index,
    );

    return (
        <SettingsSection
            id="search-providers"
            title="Search Providers"
            description="Where Search finds artists and songs that are not in the library. Providers in the list are searched together, and when two return the same artist or song, the one higher in the list is shown. Library results always come first."
        >
            <ProviderPriorityBoard
                name="search"
                providers={providers}
                active={active}
                onChange={(next) =>
                    onUpdate(
                        searchProvidersUpdate(
                            next,
                            settings.searchProviderOrder,
                        ),
                    )
                }
                emptyText="No search providers. Search shows library results only."
            />
        </SettingsSection>
    );
}
