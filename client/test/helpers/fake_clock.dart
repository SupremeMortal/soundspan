// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/clock.dart';

/// A [Clock] whose time moves only when a test moves it.
///
/// It does not drive timers; tests that need timers combine it with
/// `fake_async`.
class FakeClock implements Clock {
  /// Creates a clock that reads [start] (default 2025-01-01T00:00:00Z).
  new({DateTime? start}) : _now = (start ?? defaultStart).toUtc();

  /// The start of a clock created without one.
  static final DateTime defaultStart = DateTime.utc(2025);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// Moves the time forward by [duration].
  void advance(Duration duration) => _now = _now.add(duration);

  /// Sets the time to [time], kept in UTC.
  void set(DateTime time) => _now = time.toUtc();
}
