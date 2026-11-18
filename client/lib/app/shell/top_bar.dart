// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_title_bar.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/widgets/wordmark.dart';

/// The top bar of expanded windows (doc 09, Shell by Window Class): the
/// [Wordmark], Back and Forward, a pill search field, the Activity toggle
/// and the [avatar].
///
/// In [titleBarMode] the bar is also the window's title bar: it is
/// [titleBarHeight] tall, its empty space and the wordmark drag the window
/// ([WindowDragRegion]), and [leadingControls] and [trailingControls] (the
/// window buttons) sit at its ends.
class TopBar extends StatefulWidget {
  /// Creates the top bar.
  const new({
    required this.onBack,
    required this.onForward,
    required this.onSearch,
    required this.avatar,
    this.onSearchChanged,
    this.searchFocusNode,
    this.onToggleActivity,
    this.activityOpen = false,
    this.titleBarMode = false,
    this.leadingControls,
    this.trailingControls,
    this.leadingInset = 0,
    super.key,
  });

  /// The smallest height of the bar below the system's title bar.
  static const double minHeight = 64;

  /// The smallest height of the bar when it is the window's title bar.
  static const double titleBarHeight = 48;

  /// Whether the bar is the window's title bar.
  final bool titleBarMode;

  /// The window buttons before the wordmark; null for none.
  final Widget? leadingControls;

  /// The window buttons after the avatar; null for none.
  final Widget? trailingControls;

  /// Extra space before the wordmark, which the macOS traffic lights take.
  final double leadingInset;

  /// The key of the search field.
  static const Key searchFieldKey = Key('shell.search');

  /// Goes back in the current branch; null disables Back.
  final VoidCallback? onBack;

  /// Re-opens the location last left with Back; null disables Forward.
  final VoidCallback? onForward;

  /// Called with the trimmed text when the search field is submitted and
  /// not empty.
  final ValueChanged<String> onSearch;

  /// Called with the trimmed text, empty included, once typing in the
  /// search field pauses for [searchDebounce]; null while the field only
  /// searches on submit.
  final ValueChanged<String>? onSearchChanged;

  /// How long typing pauses before [onSearchChanged] is called.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// The avatar button.
  final Widget avatar;

  /// Shows or hides the Activity panel; null leaves the toggle out.
  final VoidCallback? onToggleActivity;

  /// Whether the Activity panel is shown.
  final bool activityOpen;

  /// The focus node of the search field, which the search shortcut
  /// focuses; null lets the field make its own.
  final FocusNode? searchFocusNode;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;

  @override
  void didUpdateWidget(TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onSearchChanged == null) _debounce?.cancel();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    if (widget.onSearchChanged == null) return;
    _debounce = Timer(TopBar.searchDebounce, () {
      widget.onSearchChanged?.call(text.trim());
    });
  }

  void _submit(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isNotEmpty) widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );
    final titleBar = widget.titleBarMode;
    final leadingControls = widget.leadingControls;
    final trailingControls = widget.trailingControls;
    final bar = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: titleBar ? TopBar.titleBarHeight : TopBar.minHeight,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: leadingControls != null
              ? 0
              : Spacing.x16 + widget.leadingInset,
          end: trailingControls != null ? 0 : Spacing.x16,
          top: titleBar ? 0 : Spacing.x8,
          bottom: titleBar ? 0 : Spacing.x8,
        ),
        child: Row(
          children: [
            if (leadingControls != null) ...[
              leadingControls,
              const SizedBox(width: Spacing.x12),
            ],
            // The wordmark is part of the drag area in the title bar.
            IgnorePointer(ignoring: titleBar, child: const Wordmark()),
            const SizedBox(width: Spacing.x24),
            IconButton(
              onPressed: widget.onBack,
              tooltip: l10n.shellBack,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              onPressed: widget.onForward,
              tooltip: l10n.shellForward,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            const SizedBox(width: Spacing.x12),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: TextField(
                    key: TopBar.searchFieldKey,
                    controller: _query,
                    focusNode: widget.searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: _changed,
                    onSubmitted: _submit,
                    style: context.typography.body.copyWith(
                      color: colors.content,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.shellSearchHint,
                      hintStyle: context.typography.body.copyWith(
                        color: colors.contentSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colors.contentSecondary,
                      ),
                      filled: true,
                      fillColor: colors.surfaceHover,
                      isDense: true,
                      border: pill,
                      enabledBorder: pill,
                      focusedBorder: pill.copyWith(
                        borderSide: BorderSide(color: colors.brand, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.x12),
            if (widget.onToggleActivity case final onToggle?) ...[
              IconButton(
                onPressed: onToggle,
                isSelected: widget.activityOpen,
                tooltip: l10n.shellActivity,
                color: colors.contentSecondary,
                selectedIcon: Icon(Icons.group_rounded, color: colors.brand),
                icon: const Icon(Icons.group_outlined),
              ),
              const SizedBox(width: Spacing.x4),
            ],
            widget.avatar,
            if (trailingControls != null) ...[
              const SizedBox(width: Spacing.x8),
              trailingControls,
            ],
          ],
        ),
      ),
    );
    return titleBar ? WindowDragRegion(child: bar) : bar;
  }
}
