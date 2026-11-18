// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan/shared/widgets/artwork.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/placeholder_image_provider.dart';
import '../../helpers/pump_app.dart';

void main() {
  Finder inArtwork(Finder matching) =>
      find.descendant(of: find.byType(Artwork), matching: matching);

  Widget withMediaQuery(
    Widget child, {
    double? devicePixelRatio,
    bool? disableAnimations,
  }) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        devicePixelRatio: devicePixelRatio,
        disableAnimations: disableAnimations,
      ),
      child: Center(child: child),
    ),
  );

  for (final (size, ratio, expected) in [
    (160.0, 2.0, 320),
    (232.0, 3.0, 768),
  ]) {
    testWidgets('requests the snapped size for size × DPR '
        '($size at DPR $ratio → $expected)', (tester) async {
      final requests = <ArtworkRequest>[];
      await tester.pumpApp(
        withMediaQuery(
          Artwork(ref: 'cover-1', size: size),
          devicePixelRatio: ratio,
        ),
        overrides: [
          artworkImageProvider.overrideWithValue((request) {
            requests.add(request);
            return PlaceholderImageProvider(request.ref);
          }),
        ],
      );

      expect(requests.last.pixelSize, expected);
      expect(requests.last.ref, 'cover-1');
      final image = tester.widget<Image>(inArtwork(find.byType(Image)));
      final resized = image.image as ResizeImage;
      expect(resized.width, expected);
      expect(resized.imageProvider, const PlaceholderImageProvider('cover-1'));
      expect(tester.getSize(find.byType(Artwork)), Size.square(size));
    });
  }

  testWidgets('placeholder for a null ref and on load error', (tester) async {
    await tester.pumpApp(const Center(child: Artwork(ref: null, size: 120)));
    expect(inArtwork(find.byIcon(Icons.music_note_rounded)), findsOneWidget);
    expect(inArtwork(find.byType(Image)), findsNothing);

    await tester.pumpApp(
      const Center(child: Artwork(ref: 'broken', size: 120)),
      overrides: [
        artworkImageProvider.overrideWithValue((_) => _FailingImageProvider()),
      ],
    );
    await tester.pump();
    expect(inArtwork(find.byIcon(Icons.music_note_rounded)), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('placeholder while the image loads', (tester) async {
    final deferred = _DeferredImageProvider();
    await tester.pumpApp(
      const Center(child: Artwork(ref: 'slow', size: 120)),
      overrides: [artworkImageProvider.overrideWithValue((_) => deferred)],
    );

    expect(inArtwork(find.byIcon(Icons.music_note_rounded)), findsOneWidget);
    deferred.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(inArtwork(find.byType(AnimatedOpacity))),
      isA<AnimatedOpacity>()
          .having((o) => o.opacity, 'opacity', 1)
          .having(
            (o) => o.duration,
            'duration',
            const Duration(milliseconds: 150),
          ),
    );
  });

  testWidgets('circle shape clips round', (tester) async {
    await tester.pumpApp(
      const Center(
        child: Artwork(ref: 'artist', size: 120, shape: ArtworkShape.circle),
      ),
    );
    expect(inArtwork(find.byType(ClipOval)), findsOneWidget);
    expect(inArtwork(find.byType(ClipRRect)), findsNothing);

    await tester.pumpApp(
      const Center(child: Artwork(ref: 'album', size: 120, radius: 12)),
    );
    expect(inArtwork(find.byType(ClipOval)), findsNothing);
    expect(
      tester.widget<ClipRRect>(inArtwork(find.byType(ClipRRect))).borderRadius,
      BorderRadius.circular(12),
    );
  });

  testWidgets('decorative without a label, labelled with one', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpApp(const Center(child: Artwork(ref: 'a', size: 120)));
    expect(find.semantics.byFlag(ui.SemanticsFlag.isImage), findsNothing);

    await tester.pumpApp(
      const Center(
        child: Artwork(
          ref: 'a',
          size: 120,
          semanticLabel: 'Cover of Abbey Road',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Cover of Abbey Road')),
      isSemantics(label: 'Cover of Abbey Road', isImage: true),
    );
    handle.dispose();
  });

  testWidgets('no fade under reduced motion', (tester) async {
    final deferred = _DeferredImageProvider();
    await tester.pumpApp(
      withMediaQuery(
        const Artwork(ref: 'slow', size: 120),
        disableAnimations: true,
      ),
      overrides: [artworkImageProvider.overrideWithValue((_) => deferred)],
    );

    deferred.complete();
    await tester.pump();
    final fade = tester.widget<AnimatedOpacity>(
      inArtwork(find.byType(AnimatedOpacity)),
    );
    expect(fade.duration, Duration.zero);
    expect(fade.opacity, 1);
  });
}

/// An image that loads when [complete] is called.
class _DeferredImageProvider extends ImageProvider<_DeferredImageProvider> {
  final Completer<ImageInfo> _completer = Completer();

  void complete() {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = PlaceholderImageProvider.palette.first,
    );
    final picture = recorder.endRecording();
    _completer.complete(ImageInfo(image: picture.toImageSync(1, 1)));
    picture.dispose();
  }

  @override
  Future<_DeferredImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DeferredImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_completer.future);
}

/// An image that fails to load.
class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('cover unavailable')),
  );
}
