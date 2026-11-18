// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:audio_session/audio_session.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';

/// The [AudioSessionEvent] of the plugin's [event].
///
/// A duck begins and ends as [DuckBegan] and [DuckEnded]; any other
/// interruption begins as [InterruptionBegan]; one of type pause ends with
/// `shouldResume`, one of unknown type without it.
AudioSessionEvent audioSessionEventOf(AudioInterruptionEvent event) {
  if (event.type == AudioInterruptionType.duck) {
    return event.begin ? const DuckBegan() : const DuckEnded();
  }
  if (event.begin) return const InterruptionBegan();
  return InterruptionEnded(
    shouldResume: event.type == AudioInterruptionType.pause,
  );
}

/// The plugin configuration of [profile]: `music()` or `speech()`, with
/// Android pausing on its own never (the app decides, doc 06).
AudioSessionConfiguration audioSessionConfigurationOf(
  AudioFocusProfile profile,
) {
  final base = switch (profile) {
    AudioFocusProfile.music => const AudioSessionConfiguration.music(),
    AudioFocusProfile.speech => const AudioSessionConfiguration.speech(),
  };
  return base.copyWith(androidWillPauseWhenDucked: false);
}
