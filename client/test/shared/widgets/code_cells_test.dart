// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/shared/widgets/code_cells.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

const _hint = 'Codes have no I, O, 0 or 1';

/// What a pumped [CodeCells] reported.
class _Cells {
  final List<String> changes = [];
  final List<DeviceLinkCode> completed = [];

  String get value => changes.isEmpty ? '' : changes.last;
}

Future<_Cells> _pump(
  WidgetTester tester, {
  String? initialValue,
  String? errorText,
  bool enabled = true,
}) async {
  final cells = _Cells();
  await tester.pumpApp(
    Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CodeCells(
            initialValue: initialValue,
            errorText: errorText,
            enabled: enabled,
            onChanged: cells.changes.add,
            onCompleted: cells.completed.add,
          ),
        ),
      ),
    ),
  );
  return cells;
}

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

String _text(WidgetTester tester) => _editable(tester).controller.text;

int _cursor(WidgetTester tester) =>
    _editable(tester).controller.selection.baseOffset;

/// Types [chars] one at a time, as a keyboard does.
Future<void> _type(WidgetTester tester, String chars) async {
  for (final char in chars.split('')) {
    final value = _editable(tester).controller.value;
    final at = value.selection.baseOffset;
    final text = value.text.replaceRange(at, at, char);
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: at + 1),
      ),
    );
    await tester.pump();
  }
}

/// Presses backspace once, as a keyboard does on a collapsed selection.
Future<void> _backspace(WidgetTester tester) async {
  final value = _editable(tester).controller.value;
  final at = value.selection.baseOffset;
  if (at == 0) {
    tester.testTextInput.updateEditingValue(value);
  } else {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: value.text.replaceRange(at - 1, at, ''),
        selection: TextSelection.collapsed(offset: at - 1),
      ),
    );
  }
  await tester.pump();
}

Future<void> _focus(WidgetTester tester) async {
  await tester.tap(find.byType(CodeCells));
  await tester.pump();
}

/// The characters the six cells show, `_` for an empty one.
String _shown(WidgetTester tester) => [
  for (var i = 0; i < DeviceLinkCode.length; i++)
    tester
            .widget<Text>(find.byKey(ValueKey('code-cell-$i')))
            .data
            ?.trim()
            .padLeft(1, '_') ??
        '_',
].join();

void main() {
  testWidgets('typing abc234 yields ABC234 and calls onCompleted once', (
    tester,
  ) async {
    final cells = await _pump(tester);
    await _focus(tester);

    await _type(tester, 'abc234');

    expect(_text(tester), 'ABC234');
    expect(_shown(tester), 'ABC234');
    expect(cells.value, 'ABC234');
    expect(cells.completed, [DeviceLinkCode.tryParse('ABC234')]);
    expect(find.text(_hint), findsNothing);

    await _type(tester, 'x');
    expect(_text(tester), 'ABC234', reason: 'a seventh character is dropped');
    expect(cells.completed, hasLength(1));
  });

  testWidgets('typing O enters nothing and shows the hint as a live region', (
    tester,
  ) async {
    final cells = await _pump(tester);
    await _focus(tester);

    await _type(tester, 'O');

    expect(_text(tester), isEmpty);
    expect(cells.value, isEmpty);
    expect(find.text(_hint), findsOne);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text(_hint)),
      isSemantics(isLiveRegion: true, label: _hint),
    );
    handle.dispose();

    await _type(tester, 'a');
    expect(_text(tester), 'A');
    expect(find.text(_hint), findsNothing);
  });

  for (final rejected in ['I', 'i', '0', '1', '#']) {
    testWidgets('$rejected is not entered', (tester) async {
      await _pump(tester);
      await _focus(tester);
      await _type(tester, 'a$rejected');
      expect(_text(tester), 'A');
      expect(find.text(_hint), findsOne);
    });
  }

  testWidgets('pasting " abc-234 " fills six cells', (tester) async {
    final cells = await _pump(tester);
    await _focus(tester);

    await tester.enterText(find.byType(EditableText), ' abc-234 ');
    await tester.pump();

    expect(_shown(tester), 'ABC234');
    expect(cells.completed.single.value, 'ABC234');
    expect(_cursor(tester), 6);
  });

  testWidgets('a paste takes the first valid six-character run', (
    tester,
  ) async {
    final cells = await _pump(tester);
    await _focus(tester);

    await tester.enterText(find.byType(EditableText), 'Code: XYZ-789 thanks');
    await tester.pump();

    expect(_text(tester), 'XYZ789');
    expect(cells.completed.single.value, 'XYZ789');
  });

  testWidgets('a paste over a partly filled code replaces it', (tester) async {
    await _pump(tester);
    await _focus(tester);
    await _type(tester, 'qq');

    final value = _editable(tester).controller.value;
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '${value.text}abc234',
        selection: const TextSelection.collapsed(offset: 8),
      ),
    );
    await tester.pump();

    expect(_text(tester), 'ABC234');
  });

  testWidgets('backspace in an empty cell moves back and clears the previous '
      'cell', (tester) async {
    final cells = await _pump(tester);
    await _focus(tester);
    await _type(tester, 'abc');
    expect(_cursor(tester), 3);

    await _backspace(tester);
    expect(_shown(tester), 'AB____');
    expect(_cursor(tester), 2);

    await _backspace(tester);
    await _backspace(tester);
    expect(_shown(tester), '______');
    expect(_cursor(tester), 0);
    expect(cells.value, isEmpty);

    await _backspace(tester);
    expect(_shown(tester), '______');
  });

  testWidgets('left and right arrows move between cells and typing over a '
      'filled cell replaces it', (tester) async {
    final cells = await _pump(tester);
    await _focus(tester);
    await _type(tester, 'abc234');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_cursor(tester), 4);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_cursor(tester), 5);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await _type(tester, 'z');

    expect(_text(tester), 'ABCZ34');
    expect(_cursor(tester), 4);
    expect(cells.completed.map((c) => c.value), ['ABC234', 'ABCZ34']);
  });

  testWidgets('initialValue fills the cells without calling onCompleted', (
    tester,
  ) async {
    final cells = await _pump(tester, initialValue: 'abc234');
    expect(_shown(tester), 'ABC234');
    expect(cells.completed, isEmpty);
  });

  testWidgets('errorText is shown under the cells as a live region', (
    tester,
  ) async {
    await _pump(tester, errorText: 'That code has expired.');
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('That code has expired.')),
      isSemantics(isLiveRegion: true, label: 'That code has expired.'),
    );
    handle.dispose();
  });

  testWidgets('disabled cells take no input', (tester) async {
    await _pump(tester, enabled: false);
    expect(_editable(tester).readOnly || !_isEnabled(tester), isTrue);
  });

  testWidgets('one text field node is labelled "Link code, 6 characters" '
      'with the entered characters as its value', (tester) async {
    await _pump(tester, initialValue: 'ABC');
    final handle = tester.ensureSemantics();
    final fields = find.semantics.byPredicate(
      (node) => node.flagsCollection.isTextField,
    );
    expect(fields, findsOne);
    expect(
      fields.evaluate().single,
      isSemantics(
        isTextField: true,
        label: 'Link code, 6 characters',
        value: 'ABC',
      ),
    );
    expect(find.semantics.byLabel('A'), findsNothing);
    handle.dispose();
  });

  testWidgets('meets the guidelines', (tester) async {
    await _pump(tester, initialValue: 'ABC');
    await expectMeetsGuidelines(tester);
  });
}

bool _isEnabled(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).enabled ?? true;
