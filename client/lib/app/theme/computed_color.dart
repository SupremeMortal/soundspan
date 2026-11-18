// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';

/// The colour of the 32-bit ARGB value [argb], for colours computed at run
/// time rather than taken from a token, such as an artwork tint (doc 09,
/// Colour Tokens: Dynamic backdrops).
Color computedColor(int argb) => Color(argb);
