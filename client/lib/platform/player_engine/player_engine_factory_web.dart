// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/just_audio_engine.dart';
import 'package:soundspan/core/playback/engines/just_audio_mapping.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan_api/soundspan_api.dart';

StreamStatusProbe? _probe;

Future<int?> _statusOf(Uri uri, Map<String, String> headers) =>
    (_probe ??= StreamStatusProbe()).status(uri, headers: headers);

/// Builds the web [PlayerEngine]: [JustAudioEngine] over the browser's
/// media element.
PlayerEngine createPlayerEngine() =>
    JustAudioEngine(family: PlayerFamily.web, statusOf: _statusOf);
