// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

/// Builds the [PlayerEngine] of the current platform.
typedef PlayerEngineBuilder = PlayerEngine Function();

PlayerEngine _unsupported() =>
    throw UnsupportedError('No PlayerEngine for this platform');

/// The root-scope [PlayerEngineBuilder]. The default throws
/// [UnsupportedError] when called; the app overrides it with the engine of
/// its platform and tests with `FakeEngine.new`.
final Provider<PlayerEngineBuilder> playerEngineBuilderProvider =
    Provider<PlayerEngineBuilder>((ref) => _unsupported);
