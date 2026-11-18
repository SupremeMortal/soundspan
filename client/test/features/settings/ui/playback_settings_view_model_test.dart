// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/features/settings/ui/playback_settings_view_model.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('StreamQualityOption', () {
    for (final (option, stored, label) in [
      (StreamQualityOption.serverDefault, 'serverDefault', 'Server default'),
      (StreamQualityOption.original, 'original', 'Original'),
      (StreamQualityOption.high, 'high', 'High'),
      (StreamQualityOption.medium, 'medium', 'Medium'),
      (StreamQualityOption.low, 'low', 'Low'),
    ]) {
      test('$option is stored as "$stored" and labelled "$label"', () {
        expect(option.stored, stored);
        expect(option.label(l10n), label);
        expect(StreamQualityOption.fromStored(stored), option);
      });
    }

    for (final stored in <Object?>[null, 'ultra', 3, true, 'High']) {
      test('the stored value $stored falls back to Server default', () {
        expect(
          StreamQualityOption.fromStored(stored),
          StreamQualityOption.serverDefault,
        );
      });
    }
  });

  group('skip interval', () {
    for (final (stored, seconds) in <(Object?, int)>[
      (5, 5),
      (10, 10),
      (15, 15),
      (30, 30),
      (45, 45),
      (60, 60),
      (7, 15),
      (30.0, 30),
      ('30', 15),
      (null, 15),
    ]) {
      test('the stored value $stored reads as $seconds s', () {
        expect(skipSecondsFromStored(stored), seconds);
      });
    }

    test('the options are 5, 10, 15, 30, 45 and 60 seconds', () {
      expect(skipIntervalOptions, [5, 10, 15, 30, 45, 60]);
      expect(l10n.settingsPlaybackSkipSeconds(30), '30 seconds');
    });
  });

  group('podcast speed', () {
    for (final (stored, speed) in <(Object?, double)>[
      (0.5, 0.5),
      (1.25, 1.25),
      (2, 2.0),
      (3.0, 3.0),
      (0.6, 1.0),
      (4, 1.0),
      ('1.5', 1.0),
      (null, 1.0),
    ]) {
      test('the stored value $stored reads as $speed', () {
        expect(podcastSpeedFromStored(stored), speed);
      });
    }

    test('the options run from 0.5× to 3× and are labelled as numbers', () {
      expect(podcastSpeedOptions, [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3]);
      expect(speedLabel(l10n, 1.25), '1.25×');
      expect(speedLabel(l10n, 1), '1×');
      expect(speedLabel(l10n, 0.5), '0.5×');
    });
  });

  group('levelling', () {
    for (final (mode, label) in [
      (LoudnessMode.off, 'Off'),
      (LoudnessMode.track, 'Track'),
      (LoudnessMode.album, 'Album'),
      (LoudnessMode.auto, 'Automatic'),
      (LoudnessMode.unknown, 'Unknown'),
    ]) {
      test('$mode is labelled "$label"', () {
        expect(levellingLabel(l10n, mode), label);
      });
    }

    test('the choices are Off, Track, Album and Automatic', () {
      expect(levellingOptions, [
        LoudnessMode.off,
        LoudnessMode.track,
        LoudnessMode.album,
        LoudnessMode.auto,
      ]);
    });
  });
}
