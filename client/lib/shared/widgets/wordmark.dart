// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/brand.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The logo mark followed by "soundspan" in Turret Road ExtraBold. The only
/// widget that uses that family.
class Wordmark extends StatelessWidget {
  /// Creates a wordmark whose mark is [height] tall.
  const new({this.height = 28, this.showMark = true, super.key});

  /// The height of the mark and the cap height of the text.
  final double height;

  /// Whether the logo mark precedes the text.
  final bool showMark;

  /// The family of the product name.
  static const String fontFamily = 'Turret Road';

  /// Turret Road's cap height as a fraction of the em (700 of 1000 units).
  static const double _capHeightPerEm = 0.7;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Brand.productName,
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMark) ...[
            SvgPicture.asset(Brand.markAsset, height: height, width: height),
            const SizedBox(width: Spacing.x8),
          ],
          Text(
            Brand.productName,
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: height / _capHeightPerEm,
              height: 1,
              color: context.colors.content,
            ),
          ),
        ],
      ),
    );
  }
}
