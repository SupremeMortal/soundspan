// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/clock.dart';

/// The [Clock] backed by the system time; the only production caller of
/// `DateTime.now()`.
class SystemClock implements Clock {
  /// Creates the system clock.
  const new();

  @override
  DateTime now() => DateTime.now().toUtc();
}
