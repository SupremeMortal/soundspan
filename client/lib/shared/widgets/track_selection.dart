// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';

/// How a pointer click changes a [SelectionController]'s selection.
enum SelectGesture {
  /// A plain click: selects the clicked row alone.
  single,

  /// Ctrl+click (Cmd+click on macOS): adds or removes the clicked row.
  toggle,

  /// Shift+click: selects the rows from the anchor to the clicked row.
  extend,
}

/// The [SelectGesture] of a click made with the modifiers held now: Shift
/// extends, Ctrl (Cmd on macOS) toggles.
SelectGesture currentSelectGesture() {
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isShiftPressed) return SelectGesture.extend;
  final toggle = defaultTargetPlatform == TargetPlatform.macOS
      ? keyboard.isMetaPressed
      : keyboard.isControlPressed;
  return toggle ? SelectGesture.toggle : SelectGesture.single;
}

/// The selection of one track list on pointer devices (doc 09, Desktop
/// Interaction: Selection).
///
/// [items] are the list's loaded rows in list order; a row is identified by
/// its item, compared with `==`. The controller keeps a focus node per item
/// so Up and Down move focus between the rows.
class SelectionController<T> extends ChangeNotifier {
  List<T> _items = const [];
  final Set<T> _selected = {};
  T? _anchor;
  final Map<T, FocusNode> _nodes = {};

  /// The loaded rows, in list order.
  List<T> get items => _items;

  /// Replaces the loaded rows. Selected rows that are gone are dropped
  /// without notifying, so lists call it while they build.
  set items(List<T> items) {
    _items = List.unmodifiable(items);
    final present = items.toSet();
    _selected.removeWhere((item) => !present.contains(item));
    if (!present.contains(_anchor)) _anchor = null;
    for (final item in [..._nodes.keys]) {
      if (!present.contains(item)) _nodes.remove(item)!.dispose();
    }
  }

  /// Whether [item] is selected.
  bool isSelected(T item) => _selected.contains(item);

  /// Whether no row is selected.
  bool get isEmpty => _selected.isEmpty;

  /// The selected rows, in list order.
  List<T> get selection => [
    for (final item in _items)
      if (_selected.contains(item)) item,
  ];

  /// What an action on row [index] acts on: the selection in list order
  /// when that row is part of it, otherwise that row alone.
  List<T> targetsFor(int index) {
    final item = _items[index];
    return _selected.contains(item) ? selection : [item];
  }

  /// The focus node of the row showing [item].
  FocusNode focusNodeFor(T item) =>
      _nodes.putIfAbsent(item, () => FocusNode(debugLabel: 'row $item'));

  /// The index of the row that has focus, or null.
  int? get focusedIndex {
    for (final (index, item) in _items.indexed) {
      if (_nodes[item]?.hasPrimaryFocus ?? false) return index;
    }
    return null;
  }

  /// Applies a click on row [index] with [gesture].
  void select(int index, SelectGesture gesture) {
    final item = _items[index];
    switch (gesture) {
      case SelectGesture.single:
        _selected
          ..clear()
          ..add(item);
        _anchor = item;
      case SelectGesture.toggle:
        if (!_selected.remove(item)) _selected.add(item);
        _anchor = item;
      case SelectGesture.extend:
        _selectRange(index);
    }
    notifyListeners();
  }

  /// Selects every loaded row.
  void selectAll() {
    _selected.addAll(_items);
    notifyListeners();
  }

  /// Clears the selection.
  void clear() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _anchor = null;
    notifyListeners();
  }

  /// Moves focus from the focused row by [delta] rows, clamped to the
  /// list; with [extend], selects from the anchor to the new row. Returns
  /// false when no row of the list has focus.
  bool moveFocus(int delta, {bool extend = false}) {
    final from = focusedIndex;
    if (from == null) return false;
    final to = (from + delta).clamp(0, _items.length - 1);
    if (extend) {
      if (_anchor == null) _anchor = _items[from];
      _selectRange(to);
      notifyListeners();
    }
    final node = focusNodeFor(_items[to])..requestFocus();
    final context = node.context;
    if (context != null) Scrollable.ensureVisible(context);
    return true;
  }

  void _selectRange(int index) {
    final anchor = _anchor;
    final from = anchor == null ? index : _items.indexOf(anchor);
    final (start, end) = from <= index ? (from, index) : (index, from);
    _anchor ??= _items[index];
    _selected
      ..clear()
      ..addAll(_items.sublist(start, end + 1));
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}

/// Selects every loaded row of the list.
class SelectAllRowsIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Clears the list's selection.
class ClearSelectionIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Moves focus to the row [delta] rows away, extending the selection when
/// [extend].
class MoveRowFocusIntent extends Intent {
  /// Creates the intent.
  const new(this.delta, {this.extend = false});

  /// The rows to move by; negative moves up.
  final int delta;

  /// Whether the selection extends to the new row.
  final bool extend;
}

/// The list keys of a selectable track list around [child]: Ctrl+A (Cmd+A
/// on macOS) selects every loaded row, Escape clears the selection, Up and
/// Down move the focused row and Shift+Up and Shift+Down extend the
/// selection (doc 09, Desktop Interaction: Selection).
///
/// Escape and the arrows do nothing, and leave the key to the widgets
/// above, while there is no selection or no row of the list has focus.
/// Off desktop and the web it returns [child].
class SelectionShortcuts<T> extends StatelessWidget {
  /// Creates the keys of [controller] around [child].
  const new({required this.controller, required this.child, super.key});

  /// The list's selection.
  final SelectionController<T> controller;

  /// The list.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!shortcutsActive()) return child;
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.keyA, control: !mac, meta: mac):
            const SelectAllRowsIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const ClearSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const MoveRowFocusIntent(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const MoveRowFocusIntent(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            const MoveRowFocusIntent(-1, extend: true),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            const MoveRowFocusIntent(1, extend: true),
      },
      child: Actions(
        actions: {
          SelectAllRowsIntent: _SelectionAction<SelectAllRowsIntent>(
            enabled: (_) => controller.items.isNotEmpty && !textFieldHasFocus(),
            (_) => controller.selectAll(),
          ),
          ClearSelectionIntent: _SelectionAction<ClearSelectionIntent>(
            enabled: (_) => !controller.isEmpty,
            (_) => controller.clear(),
          ),
          MoveRowFocusIntent: _SelectionAction<MoveRowFocusIntent>(
            enabled: (_) => controller.focusedIndex != null,
            (intent) =>
                controller.moveFocus(intent.delta, extend: intent.extend),
          ),
        },
        child: child,
      ),
    );
  }
}

class _SelectionAction<T extends Intent> extends Action<T> {
  new(this._invoke, {required this._enabled});

  final void Function(T intent) _invoke;
  final bool Function(T intent) _enabled;

  @override
  bool isEnabled(T intent) => _enabled(intent);

  @override
  Object? invoke(T intent) {
    _invoke(intent);
    return null;
  }
}

/// Owns the [SelectionController] of one list for as long as it is shown,
/// and puts the list's [SelectionShortcuts] around what [builder] builds.
class SelectableList<T> extends StatefulWidget {
  /// Creates the selection of the list [builder] builds.
  const new({required this.builder, super.key});

  /// Builds the list with its selection.
  final Widget Function(BuildContext context, SelectionController<T> selection)
  builder;

  @override
  State<SelectableList<T>> createState() => _SelectableListState<T>();
}

class _SelectableListState<T> extends State<SelectableList<T>> {
  final SelectionController<T> _selection = SelectionController<T>();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectionShortcuts<T>(
    controller: _selection,
    child: widget.builder(context, _selection),
  );
}
