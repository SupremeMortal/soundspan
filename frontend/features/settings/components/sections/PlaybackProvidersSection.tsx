"use client";

import { ReactNode } from "react";
import {
    Download,
    HardDrive,
    Music2,
    Network,
    Share2,
    SquarePlay,
} from "lucide-react";
import {
    PinnedProviderBlock,
    ProviderDefinition,
    ProviderPriorityBoard,
    SettingsInput,
    SettingsRow,
    SettingsSection,
    SettingsToggle,
} from "../ui";
import { SystemSettings } from "../../types";
import {
    PLAYBACK_PROVIDERS,
    PlaybackProvider,
    parseProviderList,
    playbackProvidersUpdate,
} from "../../providerPriority";
import { LidarrProviderSettings } from "./LidarrSection";
import { SoulseekProviderSettings } from "./SoulseekSection";
import { TidalProviderSettings } from "./TidalSection";
import { YouTubeMusicProviderSettings } from "./YouTubeMusicSection";

type TestService = (
    service: string,
) => Promise<{ success: boolean; version?: string; error?: string }>;

interface PlaybackProvidersSectionProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
    onTest: TestService;
    testingServices: Record<string, boolean>;
    /** Federation settings for the Peer libraries block; omit to hide peers. */
    peerSettings?: ReactNode;
}

/**
 * Admin Playback providers: one drag-ordered list that decides where songs
 * stream from and which services download them. The local library is always
 * first; every other provider is enabled by placing it in the list.
 */
export function PlaybackProvidersSection({
    settings,
    onUpdate,
    onTest,
    testingServices,
    peerSettings,
}: PlaybackProvidersSectionProps) {
    const active = parseProviderList(
        settings.playbackProviders,
        PLAYBACK_PROVIDERS,
    );
    const hasSoulseekAccount = Boolean(
        settings.soulseekUsername && settings.soulseekPassword,
    );
    const hasLidarr = Boolean(settings.lidarrUrl && settings.lidarrApiKey);

    const providers: ProviderDefinition<PlaybackProvider>[] = [
        ...(peerSettings
            ? [
                  {
                      id: "peers" as const,
                      label: "Peer libraries",
                      description:
                          "Stream from linked soundspan instances. Streaming only.",
                      icon: <Network className="h-4 w-4 text-violet-300" />,
                      status: {
                          text: "Streams from linked instances",
                          tone: "muted" as const,
                      },
                      renderSettings: () => peerSettings,
                  },
              ]
            : []),
        {
            id: "tidal",
            label: "TIDAL",
            description: "Streams and downloads songs and albums.",
            icon: <Music2 className="h-4 w-4 text-cyan-400" />,
            status: settings.tidalConnected
                ? {
                      text: `Signed in${settings.tidalUserId ? ` (User: ${settings.tidalUserId})` : ""}`,
                      tone: "ok",
                  }
                : { text: "Sign in to finish setup", tone: "warn" },
            renderSettings: () => (
                <TidalProviderSettings
                    settings={settings}
                    onUpdate={onUpdate}
                    onTest={onTest}
                    isTesting={testingServices.tidal || false}
                />
            ),
        },
        {
            id: "ytmusic",
            label: "YouTube Music",
            description: "Streams songs and downloads albums.",
            icon: <SquarePlay className="h-4 w-4 text-red-400" />,
            status: { text: "Search, browse, and streaming on", tone: "ok" },
            renderSettings: () => (
                <YouTubeMusicProviderSettings
                    settings={settings}
                    onUpdate={onUpdate}
                />
            ),
        },
        {
            id: "soulseek",
            label: "Soulseek",
            description: "Downloads songs from the Soulseek network.",
            icon: <Share2 className="h-4 w-4 text-green-400" />,
            status: hasSoulseekAccount
                ? { text: "Account saved", tone: "ok" }
                : { text: "Add a username and password", tone: "warn" },
            renderSettings: () => (
                <SoulseekProviderSettings
                    settings={settings}
                    onUpdate={onUpdate}
                    onTest={onTest}
                    isTesting={testingServices.soulseek || false}
                />
            ),
        },
        {
            id: "lidarr",
            label: "Lidarr",
            description: "Downloads full albums through Lidarr.",
            icon: <Download className="h-4 w-4 text-blue-400" />,
            status: hasLidarr
                ? { text: "Server saved", tone: "ok" }
                : { text: "Add a URL and API key", tone: "warn" },
            renderSettings: () => (
                <LidarrProviderSettings
                    settings={settings}
                    onUpdate={onUpdate}
                    onTest={onTest}
                    isTesting={testingServices.lidarr || false}
                />
            ),
        },
    ];

    return (
        <SettingsSection
            id="playback-providers"
            title="Providers"
            description="Songs play from the first provider in this list that has them, and downloads go to the first download provider that is available, then the next. Drag a provider into the list to turn it on, and out of the list to turn it off."
        >
            <ProviderPriorityBoard
                name="playback"
                providers={providers}
                active={active}
                onChange={(next) => onUpdate(playbackProvidersUpdate(next))}
                pinned={
                    <PinnedProviderBlock
                        icon={<HardDrive className="h-4 w-4 text-gray-200" />}
                        label="Local library"
                        description="Always first. Songs you own play from your library."
                    >
                        <LocalLibrarySettings
                            settings={settings}
                            onUpdate={onUpdate}
                        />
                    </PinnedProviderBlock>
                }
            />
        </SettingsSection>
    );
}

function LocalLibrarySettings({
    settings,
    onUpdate,
}: {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
}) {
    return (
        <div className="space-y-1">
            <SettingsRow
                label="Music library path"
                description="Path to your music library"
            >
                <SettingsInput
                    value={settings.musicPath}
                    onChange={(v) => onUpdate({ musicPath: v })}
                    placeholder="/music"
                    className="w-64"
                />
            </SettingsRow>
            <SettingsRow
                label="Download path"
                description="Path for new downloads"
            >
                <SettingsInput
                    value={settings.downloadPath}
                    onChange={(v) => onUpdate({ downloadPath: v })}
                    placeholder="/downloads"
                    className="w-64"
                />
            </SettingsRow>
            <SettingsRow
                label="Allow library deletion"
                description="When off, deleting tracks, albums, and artists is blocked on the server and delete buttons are hidden in Library."
                htmlFor="library-deletion-enabled"
            >
                <SettingsToggle
                    id="library-deletion-enabled"
                    checked={settings.libraryDeletionEnabled}
                    onChange={(checked) =>
                        onUpdate({ libraryDeletionEnabled: checked })
                    }
                />
            </SettingsRow>
        </div>
    );
}
