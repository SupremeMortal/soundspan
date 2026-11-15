// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/core/playback/engines/just_audio_engine.dart';
import 'package:soundspan/core/playback/engines/just_audio_mapping.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Builds the [PlayerEngine] of the running native platform.
PlayerEngine createPlayerEngine() => playerEngineFor(Platform.operatingSystem);

StreamStatusProbe? _probe;

Future<int?> _statusOf(Uri uri, Map<String, String> headers) =>
    (_probe ??= StreamStatusProbe()).status(uri, headers: headers);

/// Builds the [PlayerEngine] of [operatingSystem], a value of
/// `Platform.operatingSystem`: [JustAudioEngine] on Android, iOS and macOS
/// (macOS reloads the playlist in `setNext`, Spike S1 finding). Throws
/// [UnsupportedError] anywhere else.
PlayerEngine playerEngineFor(String operatingSystem) =>
    switch (operatingSystem) {
      'android' => JustAudioEngine(
        family: PlayerFamily.android,
        statusOf: _statusOf,
      ),
      'ios' => JustAudioEngine(
        family: PlayerFamily.darwin,
        statusOf: _statusOf,
      ),
      'macos' => JustAudioEngine(
        family: PlayerFamily.darwin,
        statusOf: _statusOf,
        reloadOnSetNext: true,
      ),
      _ => throw UnsupportedError('No PlayerEngine for $operatingSystem'),
    };
