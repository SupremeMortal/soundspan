// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/providers/images.dart';

/// The outline of an [Artwork].
enum ArtworkShape {
  /// A rounded square: albums, playlists, podcasts.
  square,

  /// A circle: artists and avatars.
  circle,
}

/// A cover image (doc 09, Components).
///
/// It asks [artworkImageProvider] for the server size snapped for
/// `size × devicePixelRatio`, decodes it at that width, and cross-fades it
/// in over a `surfaceHighlight` placeholder with a music-note glyph. The
/// placeholder also stands for a null [ref] and a failed load. The only
/// widget that reads [artworkImageProvider].
class Artwork extends ConsumerWidget {
  /// Creates the artwork of [ref], [size] logical pixels square.
  const new({
    required this.ref,
    required this.size,
    this.shape = ArtworkShape.square,
    this.radius = Radii.small,
    this.semanticLabel,
    super.key,
  });

  /// The server's cover value; null shows the placeholder.
  final String? ref;

  /// The edge length, in logical pixels.
  final double size;

  /// Square or circle.
  final ArtworkShape shape;

  /// The corner radius of a square: 6, or 12 for now playing.
  final double radius;

  /// The accessibility label; without one the artwork is decorative and
  /// excluded from semantics.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final placeholder = ArtworkPlaceholder(size: size);
    final cover = ref;
    Widget child;
    if (cover == null) {
      child = placeholder;
    } else {
      final request = ArtworkRequest(
        cover,
        logicalPx: size,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      final provider = widgetRef.watch(artworkImageProvider)(request);
      final fade = Motion.of(context, Motion.standard);
      child = Image(
        image: ResizeImage(provider, width: request.pixelSize),
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        gaplessPlayback: true,
        frameBuilder: (context, image, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return image;
          return Stack(
            fit: StackFit.expand,
            children: [
              placeholder,
              AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: fade,
                curve: Motion.curve,
                child: image,
              ),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }
    final clipped = switch (shape) {
      ArtworkShape.circle => ClipOval(child: child),
      ArtworkShape.square => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    };
    final sized = SizedBox.square(dimension: size, child: clipped);
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: sized);
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: sized,
    );
  }
}

/// The `surfaceHighlight` square with a music-note glyph that stands in for
/// missing artwork; it also fills skeletons.
class ArtworkPlaceholder extends StatelessWidget {
  /// Creates a placeholder [size] logical pixels square.
  const new({required this.size, super.key});

  /// The edge length, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: size,
      child: ColoredBox(
        color: colors.surfaceHighlight,
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            size: size * 0.4,
            color: colors.contentMuted,
          ),
        ),
      ),
    );
  }
}
