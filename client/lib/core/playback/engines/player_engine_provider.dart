// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/platform/player_engine/player_engine_factory.dart';

/// Builds the [PlayerEngine] of the current platform.
typedef PlayerEngineBuilder = PlayerEngine Function();

/// The root-scope [PlayerEngineBuilder]. The default is the platform
/// factory, `createPlayerEngine` (`JustAudioEngine` on Android, iOS, macOS
/// and the web, `MediaKitEngine` on Windows and Linux), which throws
/// [UnsupportedError] on a platform without an engine; tests override it
/// with `FakeEngine.new`.
final Provider<PlayerEngineBuilder> playerEngineBuilderProvider =
    Provider<PlayerEngineBuilder>((ref) => createPlayerEngine);
