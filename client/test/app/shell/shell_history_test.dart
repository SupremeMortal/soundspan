// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/shell/shell_history.dart';

void main() {
  test('back then forward returns to the same location', () {
    final history = ShellHistory()
      ..visit(0, '/home')
      ..visit(0, '/home/album/1');
    expect(history.canForward(0), isFalse);

    history
      ..back(0)
      ..visit(0, '/home');
    expect(history.canForward(0), isTrue);

    final target = history.forward(0);
    expect(target, '/home/album/1');
    history.visit(0, target!);
    expect(history.canForward(0), isFalse);

    history
      ..back(0)
      ..visit(0, '/home');
    expect(history.forward(0), '/home/album/1');
  });

  test('forward keeps the rest of the list after a re-open', () {
    final history = ShellHistory()
      ..visit(0, '/home')
      ..visit(0, '/home/album/1')
      ..back(0)
      ..visit(0, '/home');
    history.visit(0, history.forward(0)!);
    history
      ..back(0)
      ..visit(0, '/home');
    expect(history.canForward(0), isTrue);
  });

  test('a new navigation clears forward', () {
    final history = ShellHistory()
      ..visit(0, '/home')
      ..visit(0, '/home/album/1')
      ..back(0)
      ..visit(0, '/home');
    expect(history.canForward(0), isTrue);

    history.visit(0, '/home/artist/2');
    expect(history.canForward(0), isFalse);
    expect(history.forward(0), isNull);
  });

  test('showing the same location again keeps forward', () {
    final history = ShellHistory()
      ..visit(0, '/home')
      ..visit(0, '/home/album/1')
      ..back(0)
      ..visit(0, '/home')
      ..visit(0, '/home');
    expect(history.canForward(0), isTrue);
  });

  test('branches do not share history', () {
    final history = ShellHistory()
      ..visit(0, '/home')
      ..visit(0, '/home/album/1')
      ..back(0)
      ..visit(0, '/home')
      ..visit(2, '/library/playlists')
      ..visit(2, '/library/albums');
    expect(history.canForward(0), isTrue);
    expect(history.canForward(2), isFalse);
    expect(history.forward(2), isNull);

    history
      ..visit(2, '/library/albums/album/7')
      ..back(2)
      ..visit(2, '/library/albums');
    expect(history.forward(2), '/library/albums/album/7');
    expect(history.forward(0), '/home/album/1');
  });
}
