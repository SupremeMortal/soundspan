// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/fakes/fake_download_controller.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeDownloadController downloads;

  setUp(() => downloads = FakeDownloadController());

  Widget rows() => Column(
    children: [
      for (final id in ['p1', 'p2', 'p3'])
        TrackRow(
          key: ValueKey(id),
          title: 'Song $id',
          artist: 'Artist',
          duration: const Duration(minutes: 3, seconds: 41),
          leading: const TrackRowLeading.index(1),
          playbackId: PlaybackId(id),
          onTap: () {},
        ),
    ],
  );

  Finder glyphOf(String id) => find.descendant(
    of: find.byKey(ValueKey(id)),
    matching: find.byType(DownloadGlyph),
  );

  testWidgets('a completed and a running item show their glyph; an item '
      'not downloaded shows none', (tester) async {
    downloads
      ..setItem(const TrackItemKey('p1'), itemState(DownloadStatus.completed))
      ..setItem(
        const TrackItemKey('p2'),
        itemState(DownloadStatus.running, received: 500),
      );
    await tester.pumpApp(rows(), overrides: downloads.overrides());
    await tester.pump();

    expect(
      tester.widget<DownloadGlyph>(glyphOf('p1')).state,
      DownloadGlyphState.completed,
    );
    expect(
      tester.widget<DownloadGlyph>(glyphOf('p2')).state,
      const DownloadGlyphState.running(0.5),
    );
    expect(glyphOf('p3'), findsNothing);
  });

  testWidgets('the merged label of a downloaded row ends with '
      '", downloaded"', (tester) async {
    downloads.setItem(
      const TrackItemKey('p1'),
      itemState(DownloadStatus.completed),
    );
    await tester.pumpApp(rows(), overrides: downloads.overrides());
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Song p1, Artist, 3 minutes 41 seconds, downloaded',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Song p2, Artist, 3 minutes 41 seconds'),
      findsOneWidget,
    );
  });

  testWidgets('only the affected row rebuilds on progress', (tester) async {
    downloads
      ..setItem(
        const TrackItemKey('p1'),
        itemState(DownloadStatus.running, received: 100),
      )
      ..setItem(
        const TrackItemKey('p2'),
        itemState(DownloadStatus.running, received: 200),
      );
    await tester.pumpApp(rows(), overrides: downloads.overrides());
    await tester.pump();
    final before1 = tester.widget<DownloadGlyph>(glyphOf('p1'));
    final before2 = tester.widget<DownloadGlyph>(glyphOf('p2'));

    downloads.setItem(
      const TrackItemKey('p1'),
      itemState(DownloadStatus.running, received: 600),
    );
    await tester.pump();
    await tester.pump();

    final after1 = tester.widget<DownloadGlyph>(glyphOf('p1'));
    expect(after1.state, const DownloadGlyphState.running(0.6));
    expect(identical(after1, before1), isFalse);
    expect(
      identical(tester.widget<DownloadGlyph>(glyphOf('p2')), before2),
      isTrue,
    );
  });

  testWidgets('tapping a failed glyph retries the item', (tester) async {
    downloads.setItem(
      const TrackItemKey('p1'),
      itemState(DownloadStatus.failedRetryable),
    );
    await tester.pumpApp(rows(), overrides: downloads.overrides());
    await tester.pump();

    await tester.tap(glyphOf('p1'));

    expect(downloads.calls, ['retry t:p1']);
  });

  testWidgets('no glyph where the platform does not download', (tester) async {
    downloads.setItem(
      const TrackItemKey('p1'),
      itemState(DownloadStatus.completed),
    );
    await tester.pumpApp(
      rows(),
      overrides: downloads.overrides(canDownload: false),
    );
    await tester.pump();

    expect(find.byType(DownloadGlyph), findsNothing);
  });
}
