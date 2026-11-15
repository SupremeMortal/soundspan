// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  const duration = Duration(minutes: 3, seconds: 41);

  Widget row({
    String title = 'Come Together',
    String artist = 'The Beatles',
    String? album = 'Abbey Road',
    TrackRowLeading leading = const TrackRowLeading.index(1),
    bool showAlbumColumn = false,
    bool enabled = true,
    String? disabledReason,
    VoidCallback? onTap,
    bool selected = false,
  }) => Align(
    alignment: Alignment.topCenter,
    child: TrackRow(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      leading: leading,
      showAlbumColumn: showAlbumColumn,
      enabled: enabled,
      disabledReason: disabledReason,
      onTap: onTap,
      selected: selected,
    ),
  );

  testWidgets('index leading and thumbnail leading', (tester) async {
    await tester.pumpApp(row(leading: const TrackRowLeading.index(7)));
    expect(find.text('7'), findsOneWidget);
    expect(find.byType(Artwork), findsNothing);

    await tester.pumpApp(
      row(leading: const TrackRowLeading.thumbnail('cover-1')),
    );
    expect(find.text('7'), findsNothing);
    final artwork = tester.widget<Artwork>(find.byType(Artwork));
    expect(artwork.ref, 'cover-1');
    expect(artwork.size, 44);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('album column only when asked', (tester) async {
    await tester.pumpApp(row(), size: TestSizes.expanded);
    expect(find.text('Abbey Road'), findsNothing);

    await tester.pumpApp(row(showAlbumColumn: true), size: TestSizes.expanded);
    expect(find.text('Abbey Road'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Abbey Road')).dx,
      greaterThan(tester.getTopLeft(find.text('Come Together')).dx),
    );
    expect(
      tester.getTopLeft(find.text('3:41')).dx,
      greaterThan(tester.getTopLeft(find.text('Abbey Road')).dx),
    );
  });

  testWidgets('heights are 48 and 56 at scale 1.0 and grow at 2.0 without '
      'overflow', (tester) async {
    await tester.pumpApp(row());
    expect(tester.getSize(find.byType(TrackRow)).height, 48);

    await tester.pumpApp(
      row(leading: const TrackRowLeading.thumbnail('cover-1')),
    );
    expect(tester.getSize(find.byType(TrackRow)).height, 56);

    for (final leading in const [
      TrackRowLeading.index(1),
      TrackRowLeading.thumbnail('cover-1'),
    ]) {
      await tester.pumpApp(
        row(leading: leading, showAlbumColumn: true),
        textScale: 2,
        size: TestSizes.expanded,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TrackRow)).height, greaterThan(56));
    }
  });

  testWidgets('disabled row is 40 % opaque, ignores taps, and exposes the '
      'reason in tooltip and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpApp(
      row(
        enabled: false,
        disabledReason: 'Not available offline',
        onTap: () => taps++,
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(TrackRow),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.4);
    await tester.tap(find.text('Come Together'), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byTooltip('Not available offline'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TrackRow)),
      isSemantics(
        label:
            'Come Together, The Beatles, 3 minutes 41 seconds, '
            'Not available offline',
        isButton: false,
        hasTapAction: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('merged semantics label reads title, artist and spoken '
      'duration', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpApp(row(onTap: () => taps++));

    final label = find.bySemanticsLabel(
      'Come Together, The Beatles, 3 minutes 41 seconds',
    );
    expect(
      tester.getSemantics(label),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Come Together'), findsNothing);
    expect(find.bySemanticsLabel('3:41'), findsNothing);
    await tester.tap(find.byType(TrackRow));
    expect(taps, 1);
    await expectMeetsGuidelines(tester);
    handle.dispose();
  });

  testWidgets('spoken duration covers one unit, hours and zero', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Future<void> expectSpoken(Duration value, String spoken) async {
      await tester.pumpApp(
        TrackRow(
          title: 'T',
          artist: 'A',
          duration: value,
          leading: const TrackRowLeading.index(1),
        ),
      );
      expect(find.bySemanticsLabel('T, A, $spoken'), findsOneWidget);
    }

    await expectSpoken(
      const Duration(minutes: 1, seconds: 1),
      '1 minute 1 second',
    );
    await expectSpoken(const Duration(minutes: 4), '4 minutes');
    await expectSpoken(
      const Duration(hours: 1, minutes: 2, seconds: 3),
      '1 hour 2 minutes 3 seconds',
    );
    await expectSpoken(Duration.zero, '0 seconds');
    handle.dispose();
  });

  testWidgets('not a button without onTap', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(row());

    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          'Come Together, The Beatles, 3 minutes 41 seconds',
        ),
      ),
      isSemantics(isButton: false, hasTapAction: false),
    );
    await expectMeetsGuidelines(tester);
    handle.dispose();
  });

  testWidgets('selected uses surfaceActive and hover surfaceHover', (
    tester,
  ) async {
    Color? fill() {
      final box = tester.widget<DecoratedBox>(
        find.byKey(TrackRow.backgroundKey),
      );
      return (box.decoration as BoxDecoration).color;
    }

    await tester.pumpApp(row(selected: true, onTap: () {}));
    final colors = tester.element(find.byType(TrackRow)).colors;
    expect(fill(), colors.surfaceActive);

    await tester.pumpApp(row(onTap: () {}));
    expect(fill(), isNull);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(TrackRow)));
    await tester.pump();
    expect(fill(), colors.surfaceHover);
  });

  testWidgets('keyboard focus shows a brand ring', (tester) async {
    var taps = 0;
    await tester.pumpApp(row(onTap: () => taps++));
    expect(find.byKey(TrackRow.focusRingKey), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(TrackRow.focusRingKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    final colors = tester.element(find.byType(TrackRow)).colors;
    final border = (ring.decoration as BoxDecoration).border! as Border;
    expect(border.top.color, colors.brand);
    expect(border.top.width, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('skeleton has the same height as a loaded row', (tester) async {
    await tester.pumpApp(
      const Column(
        children: [
          TrackRowSkeleton(withThumbnail: true),
          TrackRowSkeleton(withThumbnail: false),
        ],
      ),
    );
    final sizes = tester
        .widgetList(find.byType(TrackRowSkeleton))
        .map((w) => tester.getSize(find.byWidget(w)).height)
        .toList();
    expect(sizes, [56, 48]);

    await tester.pumpApp(
      const Column(children: [TrackRowSkeleton(withThumbnail: true)]),
      textScale: 2,
    );
    final skeleton = tester.getSize(find.byType(TrackRowSkeleton)).height;
    await tester.pumpApp(
      row(leading: const TrackRowLeading.thumbnail('cover-1')),
      textScale: 2,
    );
    expect(skeleton, tester.getSize(find.byType(TrackRow)).height);
  });

  testWidgets('long title and artist truncate', (tester) async {
    final long = 'A very long name ' * 20;
    await tester.pumpApp(row(title: long, artist: long, showAlbumColumn: true));

    expect(tester.takeException(), isNull);
    for (final text in tester.widgetList<Text>(find.text(long))) {
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }
    expect(tester.getSize(find.byType(TrackRow)).height, 48);
    expect(find.text('3:41'), findsOneWidget);
  });
}
