// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell_io.dart';

/// A session bus that answers `NameHasOwner` with [answer] (or never, when
/// it is null) and records whether it was closed.
final class _FakeBus implements DBusClient {
  new({this.answer, this.error});

  final bool? answer;
  final Object? error;
  bool closed = false;

  @override
  Future<bool> nameHasOwner(String name) {
    if (error != null) return Future.error(error!);
    final answer = this.answer;
    return answer == null ? Completer<bool>().future : Future.value(answer);
  }

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('statusNotifierHostRegistered', () {
    test('a session bus that never answers counts as no host once the '
        'timeout passes, so bootstrap step 5 is not held up', () async {
      final bus = _FakeBus();
      final watch = Stopwatch()..start();
      final registered =
          await WindowManagerDesktopShell.statusNotifierHostRegistered(
            bus,
            timeout: const Duration(milliseconds: 50),
          ).timeout(const Duration(seconds: 5));
      expect(registered, isFalse);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(bus.closed, isTrue);
    });

    test('no watcher on the bus is no host', () async {
      final bus = _FakeBus(answer: false);
      expect(
        await WindowManagerDesktopShell.statusNotifierHostRegistered(bus),
        isFalse,
      );
      expect(bus.closed, isTrue);
    });

    test('a failing bus is no host', () async {
      final bus = _FakeBus(error: StateError('no session bus'));
      expect(
        await WindowManagerDesktopShell.statusNotifierHostRegistered(bus),
        isFalse,
      );
      expect(bus.closed, isTrue);
    });

    test('the lookup is bounded by two seconds by default', () {
      expect(
        WindowManagerDesktopShell.statusNotifierTimeout,
        const Duration(seconds: 2),
      );
    });
  });
}
