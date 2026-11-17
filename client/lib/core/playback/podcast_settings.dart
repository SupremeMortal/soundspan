// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/podcast.dart';

/// The `device_settings` key of the skip interval of episodes, in seconds
/// (doc 06, Podcasts).
const skipSecondsKey = 'playback.skipSeconds';

/// The `device_settings` key of the default playback speed of episodes.
const podcastSpeedKey = 'playback.speed.podcast';

/// The skip interval while `playback.skipSeconds` is unset.
const Duration defaultEpisodeSkipInterval = Duration(seconds: 15);

/// The episode speed while `playback.speed.podcast` is unset.
const double defaultEpisodeSpeed = 1;

/// The speeds the episode speed menu offers (doc 06, Podcasts).
const List<double> episodeSpeedOptions = [
  0.5,
  0.75,
  1,
  1.25,
  1.5,
  1.75,
  2,
  2.5,
  3,
];

/// The skip interval a stored `playback.skipSeconds` value stands for: a
/// positive whole number of seconds, else [defaultEpisodeSkipInterval].
Duration episodeSkipIntervalOf(Object? stored) => switch (stored) {
  final num seconds when seconds > 0 => Duration(seconds: seconds.round()),
  _ => defaultEpisodeSkipInterval,
};

/// The speed a stored `playback.speed.podcast` value stands for, clamped to
/// 0.5–3.0; [defaultEpisodeSpeed] when it is unset or not a number.
double episodeSpeedOf(Object? stored) => switch (stored) {
  final num speed when speed.isFinite => speed.toDouble().clamp(0.5, 3.0),
  _ => defaultEpisodeSpeed,
};

/// Where [episode] resumes: its saved position, or zero when it was never
/// played or is finished (doc 06, Podcasts).
Duration episodeResumePosition(Episode episode) {
  final progress = episode.progress;
  if (progress == null || progress.isFinished) return Duration.zero;
  final seconds = progress.currentTimeSec;
  if (!seconds.isFinite || seconds <= 0) return Duration.zero;
  return Duration(milliseconds: (seconds * 1000).round());
}
