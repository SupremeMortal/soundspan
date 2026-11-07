"use client";

import { SettingsInput, SettingsRow } from "../ui";
import { SystemSettings } from "../../types";
import { InlineStatus } from "@/components/ui/InlineStatus";
import { useConnectionTest } from "@/features/settings/hooks/useConnectionTest";

type TestService = (
    service: string,
) => Promise<{ success: boolean; version?: string; error?: string }>;

interface ProviderKeySettingsProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
    onTest?: TestService;
    isTesting?: boolean;
    /** Keeps input ids unique when the block appears in several lists. */
    idPrefix: string;
}

interface ApiKeyFieldProps {
    id: string;
    label: string;
    description: string;
    placeholder: string;
    value: string;
    onChange: (value: string) => void;
    onTest?: () => ReturnType<TestService>;
    isTesting: boolean;
}

function ApiKeyField({
    id,
    label,
    description,
    placeholder,
    value,
    onChange,
    onTest,
    isTesting,
}: ApiKeyFieldProps) {
    const { status, message, runTest, reset } = useConnectionTest({
        loadingMessage: "Testing...",
        successMessage: "Connected",
        failureMessage: "Failed",
    });

    return (
        <>
            <SettingsRow label={label} description={description} htmlFor={id}>
                <SettingsInput
                    id={id}
                    type="password"
                    value={value}
                    onChange={onChange}
                    placeholder={placeholder}
                    className="w-64"
                />
            </SettingsRow>
            {onTest && (
                <div className="inline-flex items-center gap-3 pt-1">
                    <button
                        type="button"
                        onClick={() => runTest(onTest)}
                        disabled={isTesting || !value}
                        className="rounded-full bg-white px-4 py-1.5 text-sm font-medium text-black transition-transform hover:scale-105 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {status === "loading"
                            ? "Testing..."
                            : "Test Connection"}
                    </button>
                    <InlineStatus
                        status={status}
                        message={message}
                        onClear={reset}
                    />
                </div>
            )}
        </>
    );
}

/** Fanart.tv API key, shown inside the Fanart.tv provider block. */
export function FanartKeySettings({
    settings,
    onUpdate,
    onTest,
    isTesting = false,
    idPrefix,
}: ProviderKeySettingsProps) {
    return (
        <ApiKeyField
            id={`${idPrefix}-fanart-api-key`}
            label="API key"
            description="Fanart.tv needs a key to return images."
            placeholder="Enter Fanart.tv API key"
            value={settings.fanartApiKey ?? ""}
            onChange={(value) => onUpdate({ fanartApiKey: value })}
            onTest={onTest && (() => onTest("fanart"))}
            isTesting={isTesting}
        />
    );
}

/** Last.fm API key, shown inside each Last.fm provider block. */
export function LastfmKeySettings({
    settings,
    onUpdate,
    onTest,
    isTesting = false,
    idPrefix,
}: ProviderKeySettingsProps) {
    return (
        <ApiKeyField
            id={`${idPrefix}-lastfm-api-key`}
            label="API key"
            description="Used for every Last.fm lookup, including recommendations."
            placeholder="Enter Last.fm API key"
            value={settings.lastfmApiKey ?? ""}
            onChange={(value) => onUpdate({ lastfmApiKey: value })}
            onTest={onTest && (() => onTest("lastfm"))}
            isTesting={isTesting}
        />
    );
}
