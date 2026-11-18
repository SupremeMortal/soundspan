import Link from "next/link";
import { SettingsSection } from "../ui";

/**
 * Points to the Link Device page, where a code signs in the soundspan app on
 * another device. The app's device-link steps name this entry
 * (Settings → Link Device).
 */
export function LinkDeviceSection() {
    return (
        <SettingsSection
            id="link-device"
            title="Link Device"
            description="Sign in to the soundspan app on another device with a code instead of your password."
        >
            <Link
                href="/device"
                className="inline-flex items-center px-4 py-2 rounded-full bg-white/10 text-sm font-medium text-white hover:bg-white/15 transition-colors"
            >
                Link Device
            </Link>
        </SettingsSection>
    );
}
