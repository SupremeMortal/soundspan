// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/logging/ring_log_sink.dart';

/// The web log sink: the last 500 entries in memory. [directory] is ignored.
LogSink createPersistentLogSink({String? directory}) => RingLogSink();
