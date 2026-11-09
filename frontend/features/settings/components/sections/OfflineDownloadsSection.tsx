import { SettingsRow, SettingsSection, SettingsToggle } from "../ui";
import { SystemSettings } from "../../types";

interface OfflineDownloadsSectionProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
}

/**
 * Admin switch for offline downloads. It applies to every track source alike:
 * anything a user can stream, they can download while it is on.
 */
export function OfflineDownloadsSection({
    settings,
    onUpdate,
}: OfflineDownloadsSectionProps) {
    return (
        <SettingsSection
            id="offline-downloads"
            title="Offline downloads"
            description="Let users download songs to their devices to play offline."
        >
            <SettingsRow
                label="Allow offline downloads"
                description="Turning this off stops new downloads and removes already-downloaded songs from devices the next time they sync."
                htmlFor="offline-downloads-enabled"
            >
                <SettingsToggle
                    id="offline-downloads-enabled"
                    checked={settings.offlineDownloadsEnabled !== false}
                    onChange={(checked) =>
                        onUpdate({ offlineDownloadsEnabled: checked })
                    }
                />
            </SettingsRow>
        </SettingsSection>
    );
}
