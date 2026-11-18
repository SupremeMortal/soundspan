// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Vibe: tracks that sound like a library track, found from a track menu's
/// Start radio and on the Vibe screen, and tracks found by a description
/// (doc 03, "Home, discovery, social"; doc 09, Track Actions).
library;

export 'domain/vibe_repository.dart' show VibeRepository;
export 'ui/start_radio.dart'
    show reportVibeDisabled, startRadio, startRadioOffered, vibeRadioContext;
export 'ui/vibe_card.dart' show VibeCard;
export 'vibe_providers.dart'
    show
        vibeAvailableProvider,
        vibeRepositoryProvider,
        vibeSearchAvailableProvider;
