// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/device_link_code.dart';

/// The six cells a device-link code is typed into (doc 09, Components; doc
/// 04, Device Link).
///
/// One text field sits under six drawn cells, so a screen reader meets a
/// single node labelled "Link code, 6 characters" whose value is the
/// entered characters. Typing upper-cases and advances; a character outside
/// [DeviceLinkCode.alphabet] is not entered and the hint that codes have no
/// `I`, `O`, `0` or `1` is shown and announced. Backspace clears the
/// previous cell and moves back; the arrow keys move between cells; typing
/// over a filled cell replaces it. Pasting six or more characters fills the
/// cells from the first valid six-character run once spaces and hyphens are
/// removed.
class CodeCells extends StatefulWidget {
  /// Creates the cells.
  const new({
    required this.onChanged,
    required this.onCompleted,
    this.initialValue,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  /// Called with the entered characters after every change.
  final ValueChanged<String> onChanged;

  /// Called when an edit fills the sixth cell.
  final ValueChanged<DeviceLinkCode> onCompleted;

  /// The characters the cells start with; those outside the alphabet and
  /// past the sixth are dropped.
  final String? initialValue;

  /// Whether the cells take input.
  final bool enabled;

  /// An error shown under the cells.
  final String? errorText;

  @override
  State<CodeCells> createState() => _CodeCellsState();
}

class _CodeCellsState extends State<CodeCells> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  bool _rejected = false;

  @override
  void initState() {
    super.initState();
    final initial = _allowed(widget.initialValue?.toUpperCase() ?? '');
    final text = initial.substring(
      0,
      math.min(initial.length, DeviceLinkCode.length),
    );
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  void _onRejected(bool rejected) {
    if (rejected == _rejected) return;
    setState(() => _rejected = rejected);
  }

  void _onChanged(String text) {
    setState(() {});
    widget.onChanged(text);
    if (text.length == DeviceLinkCode.length) {
      final code = DeviceLinkCode.tryParse(text);
      if (code != null) widget.onCompleted(code);
    }
  }

  void _focusCell(int index) {
    if (!widget.enabled) return;
    _focus.requestFocus();
    final at = math.min(index, _controller.text.length);
    _controller.selection = TextSelection.collapsed(offset: at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = _controller.text;
    final selection = _controller.selection;
    final active = _focus.hasFocus && selection.isValid
        ? math.min(selection.baseOffset, DeviceLinkCode.length - 1)
        : null;
    final hasError = widget.errorText != null;
    final message = _rejected ? l10n.codeCellsHint : widget.errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _cellHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableInteractiveSelection: false,
                    showCursor: false,
                    keyboardType: TextInputType.visiblePassword,
                    textCapitalization: TextCapitalization.characters,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [_CodeFormatter(_onRejected)],
                    onChanged: _onChanged,
                    decoration: InputDecoration(
                      labelText: l10n.codeCellsLabel,
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < DeviceLinkCode.length; i++) ...[
                      if (i > 0) const SizedBox(width: Spacing.x8),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _focusCell(i),
                          child: _Cell(
                            index: i,
                            char: i < text.length ? text[i] : '',
                            active: active == i,
                            error: hasError,
                            enabled: widget.enabled,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: Spacing.x8),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.typography.body.copyWith(
                color: hasError && !_rejected
                    ? colors.danger
                    : colors.contentSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

const double _cellHeight = 56;

/// One drawn cell.
class _Cell extends StatelessWidget {
  const new({
    required this.index,
    required this.char,
    required this.active,
    required this.error,
    required this.enabled,
  });

  final int index;
  final String char;
  final bool active;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = switch ((error, active)) {
      (_, true) => colors.brand,
      (true, false) => colors.danger,
      (false, false) => colors.lineStrong,
    };
    return AnimatedContainer(
      duration: Motion.standard,
      curve: Motion.curve,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.small),
        border: Border.all(color: border, width: active ? 2 : 1),
      ),
      child: Text(
        char,
        key: ValueKey('code-cell-$index'),
        style: context.typography.mono.copyWith(
          color: enabled ? colors.content : colors.contentDisabled,
        ),
      ),
    );
  }
}

/// [text] without the characters outside [DeviceLinkCode.alphabet].
String _allowed(String text) =>
    text.split('').where(DeviceLinkCode.isAllowedChar).join();

/// Keeps the field to at most six characters of the alphabet, upper-cased,
/// with typing over a filled cell replacing it and a paste of a whole code
/// filling every cell.
class _CodeFormatter extends TextInputFormatter {
  new(this._onRejected);

  final void Function(bool rejected) _onRejected;

  static final RegExp _separators = RegExp(r'[\s-]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final old = oldValue.text;
    final next = newValue.text.toUpperCase();
    final (prefix, suffix) = _typedAt(old, next, newValue.selection);
    final inserted = next.substring(prefix, next.length - suffix);
    if (inserted.isEmpty) {
      // A deletion or a cursor move.
      _onRejected(false);
      final text = _allowed(next);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: math.min(
            newValue.selection.isValid
                ? newValue.selection.baseOffset
                : text.length,
            text.length,
          ),
        ),
      );
    }
    final cleaned = inserted.replaceAll(_separators, '');
    if (cleaned.length >= DeviceLinkCode.length) {
      final code = _firstRun(cleaned);
      if (code == null) {
        _onRejected(true);
        return oldValue;
      }
      _onRejected(false);
      return TextEditingValue(
        text: code,
        selection: const TextSelection.collapsed(offset: DeviceLinkCode.length),
      );
    }
    final allowed = _allowed(cleaned);
    _onRejected(allowed.length < cleaned.length);
    if (allowed.isEmpty) return oldValue;
    final tail = old.substring(old.length - suffix);
    final kept = tail.substring(math.min(allowed.length, tail.length));
    var text = '${old.substring(0, prefix)}$allowed$kept';
    if (text.length > DeviceLinkCode.length) {
      text = text.substring(0, DeviceLinkCode.length);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: math.min(prefix + allowed.length, text.length),
      ),
    );
  }

  /// Where [next] differs from [old], as the length of their common prefix
  /// and suffix. A plain insertion before a collapsed [selection] is placed
  /// at that selection, so typing a repeated character lands in the cell
  /// the cursor was in.
  static (int, int) _typedAt(String old, String next, TextSelection selection) {
    final added = next.length - old.length;
    final start = selection.baseOffset - added;
    if (added > 0 &&
        selection.isValid &&
        selection.isCollapsed &&
        start >= 0 &&
        next.startsWith(old.substring(0, start)) &&
        next.endsWith(old.substring(start))) {
      return (start, old.length - start);
    }
    var prefix = 0;
    final shortest = math.min(old.length, next.length);
    while (prefix < shortest && old[prefix] == next[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest - prefix &&
        old[old.length - 1 - suffix] == next[next.length - 1 - suffix]) {
      suffix++;
    }
    return (prefix, suffix);
  }

  /// The first run of six alphabet characters in [text].
  static String? _firstRun(String text) {
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      if (!DeviceLinkCode.isAllowedChar(text[i])) {
        start = i + 1;
      } else if (i - start + 1 == DeviceLinkCode.length) {
        return text.substring(start, i + 1);
      }
    }
    return null;
  }
}
