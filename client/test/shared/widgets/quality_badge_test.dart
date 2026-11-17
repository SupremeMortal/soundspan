// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

import '../../helpers/pump_app.dart';

void main() {
  final cases = <(String, StreamQualityInfo, String)>[
    (
      'FLAC 24/96000',
      const StreamQualityInfo(
        quality: 'original',
        codec: 'flac',
        bitDepth: 24,
        sampleRate: 96000,
        bitrate: 4608,
      ),
      'FLAC · 24/96 kHz',
    ),
    (
      'FLAC 16/44100',
      const StreamQualityInfo(
        quality: 'original',
        codec: 'flac',
        bitDepth: 16,
        sampleRate: 44100,
      ),
      'FLAC · 16/44.1 kHz',
    ),
    (
      'AAC 256',
      const StreamQualityInfo(quality: 'high', codec: 'aac', bitrate: 256),
      'AAC · 256 kbps',
    ),
    (
      'codec only',
      const StreamQualityInfo(quality: 'medium', codec: 'opus'),
      'OPUS',
    ),
  ];

  for (final (name, info, text) in cases) {
    testWidgets('$name shows "$text"', (tester) async {
      await tester.pumpApp(Center(child: QualityBadge(info: info)));

      expect(find.text(text), findsOneWidget);
      final context = tester.element(find.byType(QualityBadge));
      final label = tester.widget<Text>(find.text(text));
      expect(label.style?.color, context.colors.contentSecondary);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(QualityBadge),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (box.decoration as BoxDecoration).color,
        context.colors.surfaceActive,
      );
    });
  }

  for (final (quality, text) in [
    ('high', 'Downloaded · High'),
    ('original', 'Downloaded · Original'),
    (null, 'Downloaded'),
    ('lossless-next', 'Downloaded'),
  ]) {
    testWidgets('a downloaded file stored at $quality shows "$text"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpApp(
        Center(
          child: QualityBadge(
            info: StreamQualityInfo.downloaded(quality: quality),
          ),
        ),
      );

      expect(find.text(text), findsOneWidget);
      expect(tester.getSemantics(find.text(text)).label, text);
      final context = tester.element(find.byType(QualityBadge));
      final label = tester.widget<Text>(find.text(text));
      expect(label.style?.color, context.colors.contentSecondary);
      semantics.dispose();
    });
  }

  testWidgets('null renders nothing', (tester) async {
    await tester.pumpApp(const Center(child: QualityBadge(info: null)));

    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(QualityBadge)), Size.zero);
  });
}
