// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/features/downloads/downloads.dart';

import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/pump_app.dart';
import 'download_text.dart';

const int _mb = 1024 * 1024;

CollectionDownloadState _state({
  DownloadCollectionStatus status = DownloadCollectionStatus.ready,
  CollectionBlock? block,
  Map<String, Object?>? detail,
  QuotaShortfall? shortfall,
  int unavailable = 0,
}) => CollectionDownloadState(
  status: status,
  itemCount: 3,
  completedCount: 0,
  unavailableCount: unavailable,
  receivedBytes: 0,
  totalBytes: 0,
  blockedReason: block,
  blockedDetail: detail,
  quotaShortfall: shortfall,
);

void main() {
  late FakeDownloadController downloads;

  setUp(() => downloads = FakeDownloadController());

  /// Pumps a button that shows the sheet of [state] for album `al-1`.
  Future<void> show(WidgetTester tester, CollectionDownloadState state) async {
    await tester.pumpApp(
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: TextButton(
              onPressed: () => showCollectionDownloadSheet(
                context,
                ref,
                CollectionKind.album,
                'al-1',
                state,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      overrides: downloads.overrides(),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('server quota: title, the three values, the sentence and '
      'Manage downloads', (tester) async {
    await show(
      tester,
      _state(
        status: DownloadCollectionStatus.blocked,
        block: CollectionBlock.serverQuota,
        detail: {
          'estimatedBytes': 300 * _mb,
          'usedBytes': 900 * _mb,
          'limitBytes': 1024 * _mb,
        },
      ),
    );

    expect(find.text('Not enough space on the server'), findsOneWidget);
    expect(find.text('Needed: 300.0 MB'), findsOneWidget);
    expect(find.text('Used: 900.0 MB'), findsOneWidget);
    expect(find.text('Limit: 1.0 GB'), findsOneWidget);
    expect(
      find.text(
        'Remove downloads to free up space, or raise the download limit in '
        'the server’s settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Manage downloads'), findsOneWidget);
    expectNoSourceWords(tester);

    await tester.tap(find.text('Manage downloads'));
    await tester.pumpAndSettle();
    expect(find.text('Not enough space on the server'), findsNothing);
  });

  testWidgets('downloads turned off on the server', (tester) async {
    await show(
      tester,
      _state(
        status: DownloadCollectionStatus.blocked,
        block: CollectionBlock.disabledByServer,
      ),
    );

    expect(
      find.text('Downloads are turned off on this server'),
      findsOneWidget,
    );
    expectNoSourceWords(tester);
  });

  testWidgets('shortfall: how much more is needed, the two values, and Raise '
      'limit calls raiseDeviceLimit with what everything needs', (
    tester,
  ) async {
    downloads.limitToFitAll = 900 * _mb;
    await show(
      tester,
      _state(
        shortfall: const QuotaShortfall(
          neededBytes: 300 * _mb,
          availableBytes: 100 * _mb,
        ),
      ),
    );

    expect(find.text('200.0 MB more needed on this device'), findsOneWidget);
    expect(find.text('Needed: 300.0 MB'), findsOneWidget);
    expect(find.text('Available: 100.0 MB'), findsOneWidget);
    expect(find.text('Download what fits'), findsOneWidget);
    expectNoSourceWords(tester);

    await tester.tap(find.text('Raise limit'));
    await tester.pumpAndSettle();

    expect(downloads.calls, ['raiseDeviceLimit ${900 * _mb}']);
    expect(find.text('Raise limit'), findsNothing);
  });

  testWidgets('Raise limit is refused with an explanation when free disk '
      'space is the bound', (tester) async {
    downloads.limitToFitAll = null;
    await show(
      tester,
      _state(
        shortfall: const QuotaShortfall(
          neededBytes: 300 * _mb,
          availableBytes: 100 * _mb,
        ),
      ),
    );

    await tester.tap(find.text('Raise limit'));
    await tester.pumpAndSettle();

    expect(downloads.calls, isEmpty);
    expect(
      find.text(
        'There isn’t enough free space on this device. Free up space, then '
        'try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Download what fits dismisses the sheet', (tester) async {
    await show(
      tester,
      _state(
        shortfall: const QuotaShortfall(neededBytes: 300, availableBytes: 0),
      ),
    );

    await tester.tap(find.text('Download what fits'));
    await tester.pumpAndSettle();

    expect(find.text('Download what fits'), findsNothing);
    expect(downloads.calls, isEmpty);
  });

  testWidgets('each unavailable reason shows its exact message', (
    tester,
  ) async {
    downloads.unavailable = const [
      UnavailableDownload(
        title: 'One',
        reason: DownloadUnavailableReason.downloadsDisabled,
      ),
      UnavailableDownload(
        title: 'Two',
        reason: DownloadUnavailableReason.trackUnavailable,
      ),
      UnavailableDownload(
        title: 'Three',
        reason: DownloadUnavailableReason.sourceUnavailable,
      ),
      UnavailableDownload(title: 'Four'),
    ];
    await show(tester, _state(unavailable: 4));

    expect(find.text('Some tracks can’t be downloaded'), findsOneWidget);
    for (final message in [
      'Downloads are turned off on this server',
      'No longer available',
      'Not available for your account',
      'Not available',
    ]) {
      expect(find.text(message), findsOneWidget, reason: message);
    }
    expectNoSourceWords(tester);
  });

  testWidgets('nothing is shown when everything is on its way', (tester) async {
    await show(tester, _state());

    expect(find.byType(BottomSheet), findsNothing);
  });
}
