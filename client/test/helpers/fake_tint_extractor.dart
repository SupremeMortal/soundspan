// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/providers/tint.dart';

/// A [TintExtractor] answering [tints] by cover ref, and null for any other
/// cover. Every request is recorded in [requests].
class FakeTintExtractor implements TintExtractor {
  /// Answers [tints], or none.
  new([Map<String, Color>? tints]) : tints = tints ?? {};

  /// The tints by cover ref.
  final Map<String, Color> tints;

  /// The refs asked for, in order.
  final List<String> requests = [];

  @override
  Future<Color?> tintOf(String artworkRef) async {
    requests.add(artworkRef);
    return tints[artworkRef];
  }
}
