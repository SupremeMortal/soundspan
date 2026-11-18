// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

/// Collects the indexes a lazy list builds during a frame and reports
/// their range once the frame is done, so a paged source hears the
/// visible range once per frame instead of once per row.
class BuiltRangeReporter {
  /// Reports to [onRange].
  new(this.onRange);

  /// Called after a frame with the first and last index built in it.
  final void Function(int first, int last) onRange;

  int? _first;
  int? _last;
  bool _scheduled = false;
  bool _disposed = false;

  /// Records that row [index] was built.
  void built(int index) {
    _first = math.min(_first ?? index, index);
    _last = math.max(_last ?? index, index);
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final (first, last) = (_first, _last);
      _first = _last = null;
      if (_disposed || first == null || last == null) return;
      onRange(first, last);
    });
  }

  /// Stops reporting.
  void dispose() => _disposed = true;
}
