// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The column rule of the media-card grids (doc 09, Library), shared by the
/// Library grids and the subscribed podcasts.
library;

import 'package:soundspan/app/theme/dimens.dart';

/// The narrowest a grid tile gets.
const double gridMinTileWidth = 160;

/// The space between grid tiles.
const double gridSpacing = Spacing.x16;

/// The number of columns of a grid [availableWidth] wide: as many tiles of
/// at least [gridMinTileWidth] as fit with [gridSpacing] between them, from
/// 2 to 8 (doc 09, Library).
int gridColumnsFor(double availableWidth) =>
    ((availableWidth + gridSpacing) ~/ (gridMinTileWidth + gridSpacing)).clamp(
      2,
      8,
    );
