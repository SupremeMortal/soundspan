// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:collection';

import 'package:soundspan/core/logging/app_logger.dart';

/// Keeps the most recent entries in memory; the web target's log store.
class RingLogSink implements LogSink {
  /// Creates a ring that keeps the last [capacity] entries.
  new({this.capacity = 500});

  /// How many entries are kept.
  final int capacity;

  final Queue<LogEntry> _entries = Queue();

  /// The kept entries, oldest first.
  List<LogEntry> get entries => List.unmodifiable(_entries);

  @override
  void write(LogEntry entry) {
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
  }

  @override
  Future<void> close() async {}
}
