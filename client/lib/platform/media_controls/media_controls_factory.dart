// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The media controls seam (doc 02, Platform Seams; doc 06, OS Media
/// Controls): `createMediaControls` builds the `MediaControls` of the
/// running platform.
///
/// `AudioServiceControls` on Android, iOS, macOS, Linux (MPRIS) and the web;
/// `SmtcControls` over the in-repo `soundspan_smtc` plugin on Windows.
library;

import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_plugin.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_gateway_windows.dart';
import 'package:soundspan/shared/clock.dart';

export 'media_controls_factory_web.dart'
    if (dart.library.io) 'media_controls_factory_io.dart'
    show createMediaControls;

/// Which [MediaControls] a platform shows.
enum MediaControlsKind {
  /// [AudioServiceControls].
  audioService,

  /// [SmtcControls].
  smtc,

  /// [NoopMediaControls].
  none,
}

/// The [MediaControlsKind] of [operatingSystem], a value of
/// `Platform.operatingSystem`, or of the web when [web] is true.
MediaControlsKind mediaControlsKindFor({
  required String operatingSystem,
  bool web = false,
}) => web
    ? MediaControlsKind.audioService
    : switch (operatingSystem) {
        'android' ||
        'ios' ||
        'macos' ||
        'linux' => MediaControlsKind.audioService,
        'windows' => MediaControlsKind.smtc,
        _ => MediaControlsKind.none,
      };

/// Builds the [MediaControls] that [mediaControlsKindFor] selects;
/// [channelName] is read when the controls are initialised. On Android the
/// notification shows the Like action labelled by [likeLabel] (doc 10,
/// Playback service); elsewhere it is not shown.
MediaControls mediaControlsFor({
  required String operatingSystem,
  required bool web,
  required String Function() channelName,
  required Clock clock,
  LikeLabel? likeLabel,
}) =>
    switch (mediaControlsKindFor(operatingSystem: operatingSystem, web: web)) {
      MediaControlsKind.audioService => AudioServiceControls(
        config: () => audioServiceConfigFor(
          operatingSystem: web ? 'web' : operatingSystem,
          channelName: channelName(),
        ),
        start: startAudioService,
        clock: clock,
        likeLabel: !web && operatingSystem == 'android' ? likeLabel : null,
      ),
      MediaControlsKind.smtc => SmtcControls(
        gateway: WindowsSmtcGateway(),
        clock: clock,
      ),
      MediaControlsKind.none => const NoopMediaControls(),
    };
