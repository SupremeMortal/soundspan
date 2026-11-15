// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/shared/widgets/artwork.dart';

/// Up to four covers in a 2 × 2 grid inside one rounded square, as for a
/// playlist made of several albums.
///
/// Fewer than four [refs] show the first as a single [Artwork]; none shows
/// the placeholder.
class MosaicArtwork extends StatelessWidget {
  /// Creates the mosaic of [refs], [size] logical pixels square.
  const new({
    required this.refs,
    required this.size,
    this.radius = Radii.small,
    this.semanticLabel,
    super.key,
  });

  /// The covers; the first four are used.
  final List<String> refs;

  /// The edge length, in logical pixels.
  final double size;

  /// The corner radius of the square.
  final double radius;

  /// The accessibility label; without one the mosaic is decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (refs.length < 4) {
      return Artwork(
        ref: refs.firstOrNull,
        size: size,
        radius: radius,
        semanticLabel: semanticLabel,
      );
    }
    final half = size / 2;
    Widget tile(int index) => Artwork(ref: refs[index], size: half, radius: 0);
    final grid = SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          children: [
            Row(children: [tile(0), tile(1)]),
            Row(children: [tile(2), tile(3)]),
          ],
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: grid);
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: grid,
    );
  }
}
