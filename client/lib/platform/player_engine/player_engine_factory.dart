// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The player engine seam: `createPlayerEngine()` builds the `PlayerEngine`
/// of the running platform (doc 02, Platform Seams).
///
/// `JustAudioEngine` on Android, iOS, macOS and the web; `MediaKitEngine` on
/// Windows and Linux. Any other platform throws [UnsupportedError].
library;

export 'player_engine_factory_web.dart'
    if (dart.library.io) 'player_engine_factory_io.dart'
    show createPlayerEngine;
