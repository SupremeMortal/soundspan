import { SettingsSection } from "../ui";
import { SystemSettings } from "../../types";
import { OfflineDownloadToggle } from "./OfflineDownloadToggle";

interface OfflineDownloadsSectionProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
}

/**
 * Admin offline-download switches for sources that have no provider block of
 * their own: the local library, peer libraries, and YouTube. TIDAL and
 * YouTube Music carry their switch inside their provider blocks.
 */
export function OfflineDownloadsSection({
    settings,
    onUpdate,
}: OfflineDownloadsSectionProps) {
    return (
        <SettingsSection
            id="offline-downloads"
            title="Offline downloads"
            description="Choose which sources users can download to their devices."
        >
            <OfflineDownloadToggle
                field="offlineAllowLocal"
                id="offline-allow-local"
                label="Allow offline downloads: Local library"
                settings={settings}
                onUpdate={onUpdate}
            />
            <OfflineDownloadToggle
                field="offlineAllowFederated"
                id="offline-allow-federated"
                label="Allow offline downloads: Peer libraries"
                settings={settings}
                onUpdate={onUpdate}
            />
            <OfflineDownloadToggle
                field="offlineAllowYouTube"
                id="offline-allow-youtube"
                label="Allow offline downloads: YouTube"
                settings={settings}
                onUpdate={onUpdate}
            />
        </SettingsSection>
    );
}
