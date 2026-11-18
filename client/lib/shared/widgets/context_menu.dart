// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// One entry of a [showContextMenu] menu.
class MenuEntry {
  /// Creates the entry [id] labelled [label] with [icon].
  const new({
    required this.id,
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  /// A stable id, for tests and analytics-free identification.
  final String id;

  /// The label shown.
  final String label;

  /// The leading icon.
  final IconData icon;

  /// Draws the entry in `danger`.
  final bool destructive;

  /// Called once, after the menu closed, when the entry is chosen.
  final VoidCallback onSelected;
}

/// Whether input is by pointer (doc 02, Adaptive Layout): a desktop
/// platform, or a mouse is connected. The window width plays no part.
bool usesPointerInput() =>
    switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    } ||
    RendererBinding.instance.mouseTracker.mouseIsConnected;

/// Shows [entries] as one menu (doc 09, Components: `ContextMenu`): a modal
/// bottom sheet on touch input (radius 12, `surfaceOverlay`, under the
/// optional [header]) and a popup menu at [position] (global) with a
/// pointer, at the centre of [context]'s box when [position] is null.
///
/// An empty [entries] shows nothing. Choosing an entry closes the menu and
/// then calls its [MenuEntry.onSelected] once.
Future<void> showContextMenu(
  BuildContext context,
  List<MenuEntry> entries, {
  Offset? position,
  Widget? header,
}) async {
  if (entries.isEmpty) return;
  final chosen = usesPointerInput()
      ? await _showPopup(context, entries, position)
      : await _showSheet(context, entries, header);
  for (final entry in entries) {
    if (entry.id == chosen) {
      entry.onSelected();
      return;
    }
  }
}

Future<String?> _showSheet(
  BuildContext context,
  List<MenuEntry> entries,
  Widget? header,
) {
  final colors = context.colors;
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: colors.surfaceOverlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.large)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            for (final entry in entries)
              ListTile(
                key: ValueKey('menu.${entry.id}'),
                leading: Icon(entry.icon, color: _colour(context, entry)),
                title: Text(
                  entry.label,
                  style: context.typography.body.copyWith(
                    color: _colour(context, entry),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(entry.id),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _showPopup(
  BuildContext context,
  List<MenuEntry> entries,
  Offset? position,
) {
  final overlay =
      Overlay.of(context, rootOverlay: true).context.findRenderObject()!
          as RenderBox;
  final box = context.findRenderObject();
  final at =
      position ??
      (box is RenderBox && box.hasSize
          ? box.localToGlobal(box.size.center(Offset.zero))
          : Offset.zero);
  final local = overlay.globalToLocal(at);
  final colors = context.colors;
  return showMenu<String>(
    context: context,
    useRootNavigator: true,
    color: colors.surfaceOverlay,
    // Raised by surface colour and a hairline, not a Material shadow.
    elevation: 0,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: colors.line),
      borderRadius: BorderRadius.circular(Radii.small),
    ),
    position: RelativeRect.fromRect(
      local & Size.zero,
      Offset.zero & overlay.size,
    ),
    items: [
      for (final entry in entries)
        PopupMenuItem<String>(
          key: ValueKey('menu.${entry.id}'),
          value: entry.id,
          child: Row(
            children: [
              Icon(entry.icon, size: 20, color: _colour(context, entry)),
              const SizedBox(width: Spacing.x12),
              Flexible(
                child: Text(
                  entry.label,
                  style: context.typography.body.copyWith(
                    color: _colour(context, entry),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Color _colour(BuildContext context, MenuEntry entry) =>
    entry.destructive ? context.colors.danger : context.colors.content;
