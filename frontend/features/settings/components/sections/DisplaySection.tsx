import { SettingsSection, SettingsRow, SettingsToggle } from "../ui";
import { SystemSettings } from "../../types";

interface DisplaySectionProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
}

/**
 * Instance-wide display options.
 */
export function DisplaySection({ settings, onUpdate }: DisplaySectionProps) {
    return (
        <SettingsSection id="display" title="Display">
            <SettingsRow
                label="Show version"
                description="Display the app version in the bottom-right corner of the player bar."
                htmlFor="show-version"
            >
                <SettingsToggle
                    id="show-version"
                    checked={settings.showVersion}
                    onChange={(checked) => onUpdate({ showVersion: checked })}
                />
            </SettingsRow>
        </SettingsSection>
    );
}
