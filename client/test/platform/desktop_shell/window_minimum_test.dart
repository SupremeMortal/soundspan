// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell_io.dart';

void main() {
  const minimum = Size(480, 600);

  test('a bounds request below the minimum is grown to it, keeping its '
      'position', () {
    expect(
      WindowManagerDesktopShell.atLeast(
        const WindowBounds(left: 40, top: 40, width: 300, height: 300),
        minimum,
      ),
      const WindowBounds(left: 40, top: 40, width: 480, height: 600),
    );
  });

  test('only the side below the minimum is grown', () {
    expect(
      WindowManagerDesktopShell.atLeast(
        const WindowBounds(left: 0, top: 0, width: 900, height: 300),
        minimum,
      ),
      const WindowBounds(left: 0, top: 0, width: 900, height: 600),
    );
  });

  test('a request at or above the minimum, or with no minimum set, is '
      'applied as given', () {
    const wanted = WindowBounds(left: 60, top: 50, width: 900, height: 700);
    expect(WindowManagerDesktopShell.atLeast(wanted, minimum), wanted);
    const small = WindowBounds(left: 1, top: 2, width: 300, height: 300);
    expect(WindowManagerDesktopShell.atLeast(small, null), small);
  });
}
