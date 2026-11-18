// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';

/// The largest text scale the app follows (doc 09, Typography).
const double maxTextScale = 2;

/// Follows the operating system's text scale up to [maxTextScale] and
/// clamps it above, for everything below it.
class AppTextScale extends StatelessWidget {
  /// Clamps the text scale of [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: maxTextScale,
    child: child,
  );
}
