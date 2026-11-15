// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The player engine seam: `createPlayerEngine()` builds the `PlayerEngine`
/// of the running platform (doc 02, Platform Seams).
///
/// `JustAudioEngine` on Android, iOS, macOS and the web. Windows and Linux
/// have no engine yet and throw [UnsupportedError].
library;

export 'player_engine_factory_web.dart'
    if (dart.library.io) 'player_engine_factory_io.dart'
    show createPlayerEngine;
