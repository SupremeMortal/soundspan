// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/contrast.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/tint_extractor.dart';
import 'package:soundspan/shared/widgets/backdrop.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_tint_extractor.dart';
import '../../helpers/pump_app.dart';

/// 24 opaque tints: eight hues at three lightnesses.
final List<Color> _tints = [
  for (var hue = 0.0; hue < 360; hue += 45)
    for (final lightness in const [0.15, 0.5, 0.9])
      HSLColor.fromAHSL(1, hue, 0.8, lightness).toColor(),
];

LinearGradient _gradientOf(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  return (container.decoration! as BoxDecoration).gradient! as LinearGradient;
}

void main() {
  test('title contrast is at least 4.5:1 for a set of 24 tints spread over '
      'hue and lightness, in both themes', () {
    expect(_tints, hasLength(24));
    for (final (colors, brightness) in [
      (SoundspanColors.dark, Brightness.dark),
      (SoundspanColors.light, Brightness.light),
    ]) {
      for (final tint in _tints) {
        final gradient = backdropGradient(tint, brightness, colors);
        for (final colour in gradient.colors) {
          expect(
            contrastRatio(colors.content, colour),
            greaterThanOrEqualTo(4.5),
            reason: '$brightness tint $tint gives $colour',
          );
        }
      }
    }
  });

  test('the tint is mixed into ground in dark and surface in light', () {
    const tint = Color(0xFF3366CC);
    final dark = backdropGradient(tint, Brightness.dark, SoundspanColors.dark);
    expect(
      dark.colors.first,
      Color.lerp(SoundspanColors.dark.ground, tint, darkTintMix),
    );
    expect(dark.colors.last, SoundspanColors.dark.surface);
    final light = backdropGradient(
      tint,
      Brightness.light,
      SoundspanColors.light,
    );
    expect(
      light.colors.first,
      Color.lerp(SoundspanColors.light.surface, tint, lightTintMix),
    );
  });

  testWidgets('no tint gives plain surface', (tester) async {
    for (final ref in [null, 'no-tint']) {
      await tester.pumpApp(Backdrop(artworkRef: ref, child: const SizedBox()));
      await tester.pumpAndSettle();
      expect(
        _gradientOf(tester).colors,
        everyElement(SoundspanColors.dark.surface),
      );
    }
  });

  testWidgets('a tint fades in once it is known', (tester) async {
    const tint = Color(0xFFCC3355);
    final extractor = FakeTintExtractor({'cover': tint});
    await tester.pumpApp(
      const Backdrop(artworkRef: 'cover', child: SizedBox()),
      overrides: [
        tintExtractorProvider.overrideWithValue(AsyncData(extractor)),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      _gradientOf(tester).colors,
      backdropGradient(tint, Brightness.dark, SoundspanColors.dark).colors,
    );
    expect(extractor.requests, ['cover']);
  });

  group('CachedTintExtractor', () {
    late CacheDatabase db;
    late CacheStore store;

    setUp(() {
      db = CacheDatabase(NativeDatabase.memory());
      store = CacheStore(db, FakeClock());
    });

    tearDown(() => db.close());

    test('a tint is read from the cache on the second request and not '
        'recomputed', () async {
      var computed = 0;
      Future<Color?> compute(String ref) async {
        computed++;
        return const Color(0xFF336699);
      }

      final first = CachedTintExtractor(store, compute);
      expect(await first.tintOf('cover'), const Color(0xFF336699));
      expect(await first.tintOf('cover'), const Color(0xFF336699));
      final second = CachedTintExtractor(store, compute);
      expect(await second.tintOf('cover'), const Color(0xFF336699));
      expect(computed, 1);
      final blob = await store.readBlob<int>(
        tintBlobKey('cover'),
        (json) => json! as int,
      );
      expect(blob?.value, 0xFF336699);
    });

    test('a cover without a tint is not stored', () async {
      var computed = 0;
      final extractor = CachedTintExtractor(store, (_) async {
        computed++;
        return null;
      });
      expect(await extractor.tintOf('cover'), isNull);
      expect(await extractor.tintOf('cover'), isNull);
      expect(computed, 2);
    });
  });

  group('dominantColor', () {
    Uint8List pixels(List<(int, int, int, int)> colours, List<int> counts) {
      final bytes = BytesBuilder();
      for (var i = 0; i < colours.length; i++) {
        final (r, g, b, a) = colours[i];
        for (var n = 0; n < counts[i]; n++) {
          bytes.add([r, g, b, a]);
        }
      }
      return bytes.toBytes();
    }

    test('a colourful area wins over a larger grey one', () {
      final rgba = pixels([(128, 128, 128, 255), (200, 30, 40, 255)], [60, 40]);
      expect(dominantColor(rgba), 0xFFC81E28);
    });

    test('transparent pixels are ignored; none opaque gives null', () {
      expect(dominantColor(pixels([(10, 200, 10, 0)], [10])), isNull);
      expect(
        dominantColor(pixels([(10, 200, 10, 0), (0, 0, 255, 255)], [50, 1])),
        0xFF0000FF,
      );
    });
  });
}
