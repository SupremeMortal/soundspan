// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/clock/system_clock.dart';

/// The source of the current time.
///
/// Code under `lib/` reads time only through this seam (the `clock` rule of
/// `tool/check_imports.dart`), so tests replace it with a fake.
abstract interface class Clock {
  /// The current time, in UTC.
  DateTime now();
}

/// The process-wide [Clock]: a [SystemClock] unless overridden.
final Provider<Clock> clockProvider = Provider<Clock>(
  (ref) => const SystemClock(),
);
