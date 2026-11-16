// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';
import 'package:soundspan/shared/clock.dart';

/// Builds the [MediaControls] of the web: the Media Session API through
/// `audio_service`.
MediaControls createMediaControls({
  required String Function() channelName,
  required Clock clock,
}) => mediaControlsFor(
  operatingSystem: 'web',
  web: true,
  channelName: channelName,
  clock: clock,
);
