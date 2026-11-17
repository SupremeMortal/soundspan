// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../core/playback/controller/controller_harness.dart';
import '../../core/playback/queue/queue_test_items.dart';
import '../../helpers/fake_desktop_shell.dart';

/// A track entry [id], "Song `id`" by [artist], 60 seconds long.
QueueItem desktopTrack(String id, {String artist = 'Band'}) => QueueItem.track(
  queueItemId: id,
  track: Track(
    meta: TrackMeta(
      title: 'Song $id',
      artist: artist,
      album: 'Record',
      durationSec: 60,
    ),
    playbackId: PlaybackId('pb-$id'),
  ),
  context: testContext,
);

/// A [DesktopController] on [platform] over a [FakeDesktopShell], an
/// in-memory `app.db` and a controller over a fake engine.
class DesktopRig {
  /// Creates the rig; [database] reuses an `app.db`, as after a restart.
  new({
    this.platform = TargetPlatform.windows,
    bool hasTrayHost = true,
    AppDatabase? database,
  }) : database = database ?? AppDatabase(NativeDatabase.memory()) {
    shell.hasTrayHost = hasTrayHost;
    for (final id in ['a', 'b', 'c']) {
      h.fake.sources[uriOf(id)] = const FakeSource(
        duration: Duration(seconds: 60),
      );
    }
  }

  /// The operating system the controller runs on.
  final TargetPlatform platform;

  /// The controller harness.
  final ControllerHarness h = ControllerHarness();

  /// The window and tray.
  final FakeDesktopShell shell = FakeDesktopShell();

  /// The app database holding `closeToTray`.
  final AppDatabase database;

  /// How many times the queue was written at once.
  int flushes = 0;

  /// What the keep-playing question answers; null when not asked yet.
  KeepPlayingAnswer? answer;

  /// How many times the keep-playing question was asked.
  int asked = 0;

  /// What the tray hears about the tray host.
  bool? trayHost;

  /// The app settings over [database].
  late final AppSettingsStore settings = AppSettingsStore(database);

  /// The controller under test.
  late final DesktopController desktop =
      DesktopController(
          shell: shell,
          settings: settings,
          platform: platform,
          texts: () =>
              DesktopTexts.of(lookupAppLocalizations(const Locale('en'))),
          onTrayHost: (available) => trayHost = available,
        )
        ..askKeepPlaying = () async {
          asked++;
          return answer;
        };

  /// Starts the controller following the harness's controller.
  Future<void> start() async {
    await desktop.start();
    desktop.bind(h.controller, flush: () async => flushes++);
    await h.settle();
  }

  /// Plays a, b and c.
  Future<void> play() async {
    await h.controller.playItems([
      desktopTrack('a'),
      desktopTrack('b'),
      desktopTrack('c'),
    ]);
    await h.settle();
  }

  /// Stops following and closes the database.
  Future<void> close() async {
    desktop.dispose();
    await h.controller.dispose();
    await database.close();
  }
}
