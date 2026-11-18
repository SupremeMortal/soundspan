// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/shell/player_slots.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/playback/controller/controller_harness.dart'
    show RecordingEngine;
import '../../core/playback/queue/queue_test_items.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

/// Opens every `state.db` over one in-memory database that holds a stored
/// queue of `a`, `b` and `c`, with `b` current at 1:05.
class _StoredQueueOpener extends InMemoryDatabaseOpener {
  final Database _raw = sqlite3.openInMemory();

  /// Writes the stored queue; call it outside fake async.
  Future<void> seed() async {
    final database = StateDatabase(
      NativeDatabase.opened(_raw, closeUnderlyingOnClose: false),
    );
    final items = trackItems(['a', 'b', 'c']);
    await QueueDao(database).replace(
      [
        for (final (index, item) in items.indexed)
          QueueSnapshotData(
            position: index,
            queueItemId: item.queueItemId,
            kind: 'track',
            itemJson: jsonEncode(item.toJson()),
          ),
      ],
      QueueMetaData(
        id: 1,
        currentQueueItemId: 'b',
        positionMs: const Duration(minutes: 1, seconds: 5).inMilliseconds,
        repeatMode: 'off',
        revision: 3,
        updatedAt: DateTime.utc(2025),
      ),
    );
    await database.close();
  }

  @override
  QueryExecutor open(DatabaseTarget target) {
    if (target is! StateDatabaseTarget) return super.open(target);
    opened.add(target);
    return NativeDatabase.opened(_raw);
  }
}

void main() {
  late RecordingEngine engine;

  Future<TestRoot> pump(WidgetTester tester, Size size) async {
    final opener = _StoredQueueOpener();
    await tester.runAsync(opener.seed);
    return await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: size,
      opener: opener,
      engine: () => engine = RecordingEngine(FakeEngine()),
    );
  }

  void expectRestoredPaused(TestRoot root) {
    final profile = root.container.read(profileRuntimeProvider).container!;
    final snapshot = profile.read(playbackControllerProvider).snapshot;
    expect(snapshot.current?.queueItemId, 'b');
    expect(snapshot.playing, isFalse);
    expect(snapshot.position, const Duration(minutes: 1, seconds: 5));
    expect(
      engine.calls.where((call) => !call.startsWith('setVolume')),
      isEmpty,
    );
  }

  testWidgets('the stored queue shows in the mini player at 390 after '
      'start-up', (tester) async {
    final root = await pump(tester, TestSizes.compact);

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.text('Song b'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(MiniPlayerSlot.slotKey)).height,
      greaterThan(0),
    );
    expectRestoredPaused(root);
  });

  testWidgets('the stored queue shows in the player bar at 1440 after '
      'start-up', (tester) async {
    final root = await pump(tester, TestSizes.expanded);

    expect(
      tester.getSize(find.byKey(PlayerBarSlot.panelKey)).height,
      PlayerBarSlot.height,
    );
    expect(
      find.descendant(
        of: find.byKey(PlayerBarSlot.panelKey),
        matching: find.text('Song b'),
      ),
      findsOneWidget,
    );
    expectRestoredPaused(root);
  });
}
