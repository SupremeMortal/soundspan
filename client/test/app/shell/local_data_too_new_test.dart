// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/local_data_too_new_screen.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/test_root.dart';

/// Opens every `state.db` as written by app schema version 99 until one is
/// deleted.
class _TooNewOpener extends InMemoryDatabaseOpener {
  bool tooNew = true;

  @override
  QueryExecutor open(DatabaseTarget target) {
    if (tooNew && target is StateDatabaseTarget) {
      opened.add(target);
      return NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA user_version = 99'),
      );
    }
    return super.open(target);
  }

  @override
  Future<void> delete(DatabaseTarget target) async {
    await super.delete(target);
    if (target is StateDatabaseTarget) tooNew = false;
  }
}

void main() {
  late _TooNewOpener opener;
  late RecordingProfileRuntime runtime;

  Future<TestRoot> pump(WidgetTester tester) {
    opener = _TooNewOpener();
    return tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      opener: opener,
      overrides: [recordingRuntimeOverride((r) => runtime = r)],
    );
  }

  testWidgets('the screen replaces the shell', (tester) async {
    final root = await pump(tester);
    expect(runtime.state.value, ProfileRuntimeLocalDataTooNew(root.profileId!));
    expect(find.byType(LocalDataTooNewScreen), findsOneWidget);
    expect(find.byType(AdaptiveShell), findsNothing);
    expect(
      find.text('This data was written by a newer version of the app'),
      findsOneWidget,
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('reset requires confirmation', (tester) async {
    final root = await pump(tester);
    await tester.tap(find.text('Reset this server’s local data'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(runtime.reset, isEmpty);
    expect(opener.deleted, isEmpty);

    runtime.delegate = false;
    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(runtime.reset, [root.profileId]);
  });

  testWidgets('cancel changes nothing', (tester) async {
    final root = await pump(tester);
    await tester.tap(find.text('Reset this server’s local data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(runtime.reset, isEmpty);
    expect(opener.deleted, isEmpty);
    expect(runtime.state.value, ProfileRuntimeLocalDataTooNew(root.profileId!));
    expect(find.byType(LocalDataTooNewScreen), findsOneWidget);
  });

  testWidgets('"Switch server" opens the server list', (tester) async {
    final root = await pump(tester);
    await tester.tap(find.text('Switch server'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/settings/servers');
  });
}
