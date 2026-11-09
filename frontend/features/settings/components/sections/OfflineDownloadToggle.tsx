import { SettingsRow, SettingsToggle } from "../ui";
import { SystemSettings } from "../../types";

/** System-settings switches that gate offline downloads, one per source. */
export type OfflineAllowField =
    | "offlineAllowLocal"
    | "offlineAllowFederated"
    | "offlineAllowTidal"
    | "offlineAllowYtMusic"
    | "offlineAllowYouTube";

interface OfflineDownloadToggleProps {
    field: OfflineAllowField;
    /** DOM id for the checkbox, also used to label the row. */
    id: string;
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
    /** Row label; defaults to "Allow offline downloads". */
    label?: string;
}

/** One "Allow offline downloads" switch for a single source. */
export function OfflineDownloadToggle({
    field,
    id,
    settings,
    onUpdate,
    label = "Allow offline downloads",
}: OfflineDownloadToggleProps) {
    return (
        <SettingsRow
            label={label}
            description="Turning this off stops new downloads and removes already-downloaded songs from devices the next time they sync."
            htmlFor={id}
        >
            <SettingsToggle
                id={id}
                checked={settings[field] !== false}
                onChange={(checked) => onUpdate({ [field]: checked })}
            />
        </SettingsRow>
    );
}
