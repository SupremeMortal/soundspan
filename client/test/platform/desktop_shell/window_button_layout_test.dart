// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/desktop_shell/window_chrome.dart';

const WindowButton _min = WindowButton.minimize;
const WindowButton _max = WindowButton.maximize;
const WindowButton _close = WindowButton.close;

void main() {
  group('WindowButtonLayout.parse', () {
    final cases = <String, WindowButtonLayout>{
      // KDE's default.
      'icon:minimize,maximize,close': WindowButtonLayout.standard,
      'close,minimize,maximize:': const WindowButtonLayout(
        leading: [_close, _min, _max],
      ),
      ':close': const WindowButtonLayout(trailing: [_close]),
      // GNOME's default.
      'appmenu:close': const WindowButtonLayout(trailing: [_close]),
      'close:minimize': const WindowButtonLayout(
        leading: [_close],
        trailing: [_min],
      ),
      ' minimize , maximize : close ': const WindowButtonLayout(
        leading: [_min, _max],
        trailing: [_close],
      ),
      'menu,spacer:icon,appmenu,close': const WindowButtonLayout(
        trailing: [_close],
      ),
      'close:close,minimize,close': const WindowButtonLayout(
        leading: [_close],
        trailing: [_min],
      ),
      'minimize,maximize,close': const WindowButtonLayout(
        leading: [_min, _max, _close],
      ),
      'icon:': WindowButtonLayout.none,
      ':': WindowButtonLayout.none,
      '': WindowButtonLayout.standard,
      '   ': WindowButtonLayout.standard,
    };
    for (final MapEntry(key: value, value: expected) in cases.entries) {
      test('"$value"', () {
        expect(WindowButtonLayout.parse(value), expected);
      });
    }
  });

  test('standard is minimise, maximise and close at the trailing end', () {
    expect(WindowButtonLayout.standard.leading, isEmpty);
    expect(WindowButtonLayout.standard.trailing, [_min, _max, _close]);
  });

  test('none is empty', () {
    expect(WindowButtonLayout.none.isEmpty, isTrue);
    expect(WindowButtonLayout.standard.isEmpty, isFalse);
  });
}
