// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';
import 'package:soundspan/shared/clock.dart';

/// Builds the [MediaControls] of the running native platform.
MediaControls createMediaControls({
  required String Function() channelName,
  required Clock clock,
  LikeLabel? likeLabel,
}) => mediaControlsFor(
  operatingSystem: Platform.operatingSystem,
  web: false,
  channelName: channelName,
  clock: clock,
  likeLabel: likeLabel,
);
