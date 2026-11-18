// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/core/playback/engines/just_audio_engine.dart';
import 'package:soundspan/core/playback/engines/just_audio_mapping.dart';
import 'package:soundspan/core/playback/engines/media_kit_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Builds the [PlayerEngine] of the running native platform.
PlayerEngine createPlayerEngine() => playerEngineFor(Platform.operatingSystem);

StreamStatusProbe? _probe;

Future<int?> _statusOf(Uri uri, Map<String, String> headers) =>
    (_probe ??= StreamStatusProbe()).status(uri, headers: headers);

MediaKitEngine _mediaKitEngine(String operatingSystem) {
  MediaKitEngine.ensureInitialized();
  return MediaKitEngine(
    statusOf: _statusOf,
    audioOutputOverride: mediaKitAudioOutputFor(operatingSystem),
  );
}

/// mpv's `ao` on [operatingSystem], a value of `Platform.operatingSystem`;
/// null keeps mpv's default.
///
/// On Linux PulseAudio (served by pipewire-pulse on PipeWire desktops) comes
/// first: tearing down mpv's PipeWire output after it failed to connect, as
/// it does in the flatpak sandbox, which has no PipeWire socket, can stall
/// mpv's core for 20 s or more (doc 06).
String? mediaKitAudioOutputFor(String operatingSystem) =>
    operatingSystem == 'linux' ? 'pulse,pipewire,alsa' : null;

/// Which [PlayerEngine] a native platform plays through.
enum PlayerEngineKind {
  /// [JustAudioEngine] replacing the next source in place (Android, iOS).
  justAudio,

  /// [JustAudioEngine] reloading the playlist in `setNext` (macOS, Spike S1
  /// finding).
  justAudioReloading,

  /// [MediaKitEngine] over libmpv (Windows, Linux).
  mediaKit,
}

/// The [PlayerEngineKind] of [operatingSystem], a value of
/// `Platform.operatingSystem`, or null for a platform without an engine.
PlayerEngineKind? playerEngineKindFor(String operatingSystem) =>
    switch (operatingSystem) {
      'android' || 'ios' => PlayerEngineKind.justAudio,
      'macos' => PlayerEngineKind.justAudioReloading,
      'windows' || 'linux' => PlayerEngineKind.mediaKit,
      _ => null,
    };

/// Builds the [PlayerEngine] of [operatingSystem], a value of
/// `Platform.operatingSystem`, as [playerEngineKindFor] selects it. Throws
/// [UnsupportedError] for a platform without an engine.
///
/// libmpv is initialised here, on Windows and Linux only, so it is never
/// loaded on another platform.
PlayerEngine playerEngineFor(String operatingSystem) =>
    switch (playerEngineKindFor(operatingSystem)) {
      PlayerEngineKind.justAudio => JustAudioEngine(
        family: operatingSystem == 'android'
            ? PlayerFamily.android
            : PlayerFamily.darwin,
        statusOf: _statusOf,
      ),
      PlayerEngineKind.justAudioReloading => JustAudioEngine(
        family: PlayerFamily.darwin,
        statusOf: _statusOf,
        reloadOnSetNext: true,
      ),
      PlayerEngineKind.mediaKit => _mediaKitEngine(operatingSystem),
      null => throw UnsupportedError('No PlayerEngine for $operatingSystem'),
    };
