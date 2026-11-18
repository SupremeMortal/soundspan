// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/like_button.dart';

import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'like_button',
    sizes: const [Size(240, 80)],
    builder: (_) => Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LikeButton(liked: false, onToggle: () {}),
          LikeButton(liked: true, onToggle: () {}),
          const LikeButton(liked: false, onToggle: null),
        ],
      ),
    ),
  );
}
