// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/app/session/sign_out_sequence.dart';
import 'package:soundspan/features/settings/settings.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/test_root.dart';

/// A [SignOutSequence] whose answers a test sets and whose runs wait for
/// [gate] when it is set.
class _FakeSequence implements SignOutSequence {
  int pending = 0;

  /// The downloads each profile reports; the real sequence reports none
  /// for an inactive profile.
  final Map<String, DownloadsSummary> downloads = {};
  Completer<void>? gate;
  Error? failure;
  final List<String> calls = [];

  @override
  Future<int> pendingChanges(String profileId) async => pending;

  @override
  Future<DownloadsSummary?> downloadsSummary(String profileId) async =>
      downloads[profileId];

  @override
  Future<void> signOut(String profileId, {bool removeDownloads = false}) async {
    calls.add('signOut($profileId, removeDownloads: $removeDownloads)');
    await gate?.future;
    if (failure case final error?) throw error;
  }

  @override
  Future<void> removeServer(String profileId) async {
    calls.add('removeServer($profileId)');
    await gate?.future;
    if (failure case final error?) throw error;
  }
}

void main() {
  late _FakeSequence sequence;

  setUp(() => sequence = _FakeSequence());

  Finder inTile(String profileId, Finder finder) => find.descendant(
    of: find.byKey(ValueKey<String>(profileId)),
    matching: finder,
  );

  Future<TestRoot> open(WidgetTester tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      others: ['other'],
      overrides: [signOutSequenceProvider.overrideWithValue(sequence)],
    );
    root.container.read(routerProvider).go(SettingsSection.servers.path);
    await tester.pumpAndSettle();
    return root;
  }

  testWidgets('sign out asks first, then signs the profile out', (
    tester,
  ) async {
    final root = await open(tester);
    final other = root.otherIds['other']!;

    await tester.tap(inTile(other, find.text('Sign out')));
    await tester.pumpAndSettle();

    expect(find.text('Sign out of other.example.com?'), findsOneWidget);
    expect(find.textContaining('Also remove downloads'), findsNothing);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
    await tester.pumpAndSettle();

    expect(sequence.calls, ['signOut($other, removeDownloads: false)']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cancel changes nothing', (tester) async {
    final root = await open(tester);

    await tester.tap(inTile(root.profileId!, find.text('Sign out')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(sequence.calls, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('with downloads the checkbox shows their count and size, is '
      'unticked, and ticking it reaches the sequence', (tester) async {
    final root = await open(tester);
    sequence.downloads[root.profileId!] = const DownloadsSummary(
      itemCount: 12,
      bytes: 340000000,
    );

    await tester.tap(inTile(root.profileId!, find.text('Sign out')));
    await tester.pumpAndSettle();
    const label = 'Also remove downloads (12 items, 340 MB)';
    expect(find.text(label), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await expectMeetsGuidelines(tester);

    await tester.tap(find.text(label));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
    await tester.pumpAndSettle();

    expect(sequence.calls, [
      'signOut(${root.profileId}, removeDownloads: true)',
    ]);
  });

  testWidgets('one download reads "1 item"', (tester) async {
    final root = await open(tester);
    sequence.downloads[root.profileId!] = const DownloadsSummary(
      itemCount: 1,
      bytes: 1500,
    );

    await tester.tap(inTile(root.profileId!, find.text('Sign out')));
    await tester.pumpAndSettle();

    expect(find.text('Also remove downloads (1 item, 1.5 KB)'), findsOneWidget);
  });

  testWidgets('no checkbox without downloads, nor for an inactive profile', (
    tester,
  ) async {
    final root = await open(tester);
    sequence.downloads[root.profileId!] = const DownloadsSummary(
      itemCount: 0,
      bytes: 0,
    );

    await tester.tap(inTile(root.profileId!, find.text('Sign out')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(inTile(root.otherIds['other']!, find.text('Sign out')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('remove says downloads will be deleted when there are any', (
    tester,
  ) async {
    final root = await open(tester);
    sequence.downloads[root.profileId!] = const DownloadsSummary(
      itemCount: 3,
      bytes: 30000000,
    );
    const sentence =
        'Downloads on this device for this server will be deleted.';

    await tester.tap(inTile(root.profileId!, find.text('Remove this server')));
    await tester.pumpAndSettle();
    expect(find.text(sentence), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(
      inTile(root.otherIds['other']!, find.text('Remove this server')),
    );
    await tester.pumpAndSettle();
    expect(find.text(sentence), findsNothing);
  });

  testWidgets('remove names the server; with nothing pending it reads '
      '"Remove"', (tester) async {
    final root = await open(tester);
    final other = root.otherIds['other']!;

    await tester.tap(inTile(other, find.text('Remove this server')));
    await tester.pumpAndSettle();

    expect(find.text('Remove other.example.com?'), findsOneWidget);
    expect(find.textContaining('will be lost'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Remove'), findsOneWidget);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(sequence.calls, ['removeServer($other)']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('remove with pending changes warns and reads "Remove anyway"', (
    tester,
  ) async {
    sequence.pending = 3;
    final root = await open(tester);

    await tester.tap(inTile(root.profileId!, find.text('Remove this server')));
    await tester.pumpAndSettle();

    expect(
      find.text('3 changes have not been sent to the server and will be lost.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Remove anyway'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('while the sequence runs the dialog shows progress and cannot '
      'be dismissed', (tester) async {
    sequence.gate = Completer<void>();
    final root = await open(tester);

    await tester.tap(inTile(root.profileId!, find.text('Sign out')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
    await tester.pump();

    expect(find.text('Signing out…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    await expectMeetsGuidelines(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    final navigator = tester.state<NavigatorState>(
      find
          .ancestor(
            of: find.byType(AlertDialog),
            matching: find.byType(Navigator),
          )
          .first,
    );
    await navigator.maybePop();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);

    sequence.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a failure shows an error and the dialog stays open', (
    tester,
  ) async {
    sequence.failure = StateError('keychain locked');
    final root = await open(tester);

    await tester.tap(inTile(root.profileId!, find.text('Remove this server')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The sign-in details on this device could not be deleted. '
        'Try again.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('every signed-in profile offers sign out and remove', (
    tester,
  ) async {
    final root = await open(tester);
    for (final id in [root.profileId!, root.otherIds['other']!]) {
      expect(inTile(id, find.text('Sign out')), findsOneWidget);
      expect(inTile(id, find.text('Remove this server')), findsOneWidget);
    }
  });
}
