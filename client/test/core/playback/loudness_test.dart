// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/loudness.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';

/// Track -20 LUFS / -1 dBTP; album -10 LUFS / -0.5 dBTP.
const _differing = Loudness(
  loudnessLufs: -20,
  truePeakDb: -1,
  albumLoudnessLufs: -10,
  albumTruePeakDb: -0.5,
);

void main() {
  final cases =
      <
        ({
          String name,
          LoudnessMode mode,
          Loudness? loudness,
          QueueContextKind? context,
          double target,
          double expected,
        })
      >[
        (
          name: 'mode off, loud track',
          mode: LoudnessMode.off,
          loudness: const Loudness(loudnessLufs: -6, truePeakDb: 0),
          context: QueueContextKind.album,
          target: -18,
          expected: 0,
        ),
        (
          name: 'mode track, -10 LUFS, target -18',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -10, truePeakDb: -1),
          context: null,
          target: -18,
          expected: -8,
        ),
        (
          name: 'mode track, -24 LUFS, peak -6 dBTP: capped at +3',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -24, truePeakDb: -6),
          context: null,
          target: -18,
          expected: 3,
        ),
        (
          name: 'mode track, -20 LUFS, peak -1 dBTP: limited by headroom',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -20, truePeakDb: -1),
          context: null,
          target: -18,
          expected: 1,
        ),
        (
          name: 'mode track, -20 LUFS, peak +0.5 dBTP',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -20, truePeakDb: 0.5),
          context: null,
          target: -18,
          expected: 0,
        ),
        (
          name: 'mode track, -20 LUFS, peak missing',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -20),
          context: null,
          target: -18,
          expected: 0,
        ),
        (
          name: 'mode track, -19 LUFS, peak -6 dBTP: below both limits',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -19, truePeakDb: -6),
          context: null,
          target: -18,
          expected: 1,
        ),
        (
          name: 'mode track, loudness missing',
          mode: LoudnessMode.track,
          loudness: const Loudness(truePeakDb: -6),
          context: null,
          target: -18,
          expected: 0,
        ),
        (
          name: 'mode track, no loudness at all (episode)',
          mode: LoudnessMode.track,
          loudness: null,
          context: null,
          target: -18,
          expected: 0,
        ),
        (
          name: 'mode track, album and track values differ: track used',
          mode: LoudnessMode.track,
          loudness: _differing,
          context: QueueContextKind.album,
          target: -18,
          expected: 1,
        ),
        (
          name: 'mode album, album and track values differ: album used',
          mode: LoudnessMode.album,
          loudness: _differing,
          context: QueueContextKind.playlist,
          target: -18,
          expected: -8,
        ),
        (
          name: 'mode album, album loudness missing: track used',
          mode: LoudnessMode.album,
          loudness: const Loudness(
            loudnessLufs: -20,
            truePeakDb: -1,
            albumTruePeakDb: -9,
          ),
          context: QueueContextKind.album,
          target: -18,
          expected: 1,
        ),
        (
          name: 'mode auto, context album: album value',
          mode: LoudnessMode.auto,
          loudness: _differing,
          context: QueueContextKind.album,
          target: -18,
          expected: -8,
        ),
        (
          name: 'mode auto, context album, album loudness missing: track',
          mode: LoudnessMode.auto,
          loudness: const Loudness(loudnessLufs: -20, truePeakDb: -1),
          context: QueueContextKind.album,
          target: -18,
          expected: 1,
        ),
        for (final context in [
          QueueContextKind.playlist,
          QueueContextKind.search,
          QueueContextKind.single,
          null,
        ])
          (
            name: 'mode auto, context ${context?.name}: track value',
            mode: LoudnessMode.auto,
            loudness: _differing,
            context: context,
            target: -18,
            expected: 1,
          ),
        (
          name: 'mode unknown',
          mode: LoudnessMode.unknown,
          loudness: _differing,
          context: QueueContextKind.album,
          target: -18,
          expected: 0,
        ),
        (
          name: 'custom target -14: gain relative to -14',
          mode: LoudnessMode.track,
          loudness: const Loudness(loudnessLufs: -10, truePeakDb: -1),
          context: null,
          target: -14,
          expected: -4,
        ),
        (
          name: 'album peak limits an album gain, not the track peak',
          mode: LoudnessMode.album,
          loudness: const Loudness(
            loudnessLufs: -24,
            truePeakDb: -9,
            albumLoudnessLufs: -24,
            albumTruePeakDb: -2,
          ),
          context: QueueContextKind.album,
          target: -18,
          expected: 2,
        ),
      ];

  for (final c in cases) {
    test(c.name, () {
      expect(
        loudnessGainDb(
          mode: c.mode,
          loudness: c.loudness,
          contextKind: c.context,
          targetLufs: c.target,
        ),
        closeTo(c.expected, 1e-9),
      );
    });
  }

  test('gainToLinear at 0, -6 and +3 dB', () {
    expect(gainToLinear(0), 1.0);
    expect(gainToLinear(-6), closeTo(0.501, 0.001));
    expect(gainToLinear(3), closeTo(1.413, 0.001));
  });
}
