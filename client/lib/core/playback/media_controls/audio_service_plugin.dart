// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:audio_service/audio_service.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';

/// The [AudioServiceStarter] of the running app: `AudioService.init`, which
/// registers the handler with the platform (the Android media browser
/// service, Now Playing, the Media Session API or MPRIS).
Future<SoundspanAudioHandler> startAudioService(
  SoundspanAudioHandler Function() builder,
  AudioServiceConfig config,
) => AudioService.init(builder: builder, config: config);
