// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Rows shared by the settings pages.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// One choice of a [SettingsChoiceRow].
final class SettingsOption<T> {
  /// Creates the choice of [value], shown as [label] with an optional
  /// [caption].
  const new(this.value, this.label, {this.caption});

  /// The value chosen.
  final T value;

  /// The choice's label.
  final String label;

  /// A line under the label, or null.
  final String? caption;
}

/// A settings row showing [value]'s label as its subtitle (a skeleton
/// while [value] is null) that opens the single-choice list of [options].
class SettingsChoiceRow<T extends Object> extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
    this.enabled = true,
    this.skeletonKey,
    super.key,
  });

  /// The row's title.
  final String title;

  /// The current value; null shows a skeleton.
  final T? value;

  /// The choices, in list order.
  final List<SettingsOption<T>> options;

  /// Called with the chosen value.
  final Future<void> Function(T value) onSelected;

  /// Whether the row can be tapped.
  final bool enabled;

  /// The key of the skeleton shown while [value] is null.
  final Key? skeletonKey;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final current = options.where((option) => option.value == value);
    return ListTile(
      title: Text(title),
      subtitle: value == null
          ? _Skeleton(key: skeletonKey)
          : Text(current.isEmpty ? '' : current.first.label),
      enabled: enabled,
      minTileHeight: Sizes.touchTarget,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => unawaited(_open(context)),
    );
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => _sheet(context),
      _ => _menu(context),
    };
    if (chosen != null) await onSelected(chosen);
  }

  Future<T?> _sheet(BuildContext context) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.x16,
              0,
              Spacing.x16,
              Spacing.x8,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.typography.subtitle.copyWith(
                  color: context.colors.content,
                ),
              ),
            ),
          ),
          for (final option in options)
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: option.value == value,
              child: ListTile(
                title: Text(option.label),
                subtitle: option.caption == null ? null : Text(option.caption!),
                selected: option.value == value,
                minTileHeight: Sizes.touchTarget,
                trailing: option.value == value
                    ? Icon(Icons.check_rounded, color: context.colors.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
            ),
        ],
      ),
    ),
  );

  Future<T?> _menu(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(0, box.size.height), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    return showMenu<T>(
      context: context,
      position: position,
      items: [
        for (final option in options)
          CheckedPopupMenuItem<T>(
            value: option.value,
            checked: option.value == value,
            child: option.caption == null
                ? Text(option.label)
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    subtitle: Text(option.caption!),
                  ),
          ),
      ],
    );
  }
}

/// The placeholder of a row's value: a `surfaceHighlight` bar.
class _Skeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: 96,
        height: 12,
        margin: const EdgeInsets.symmetric(vertical: Spacing.x4),
        decoration: BoxDecoration(
          color: context.colors.surfaceHighlight,
          borderRadius: BorderRadius.circular(Spacing.x4),
        ),
      ),
    ),
  );
}

/// A caption under a group of rows.
class SettingsCaption extends StatelessWidget {
  /// Creates the caption [text].
  const new(this.text, {super.key});

  /// The caption.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.x16,
      Spacing.x4,
      Spacing.x16,
      Spacing.x8,
    ),
    child: Text(
      text,
      style: context.typography.caption.copyWith(
        color: context.colors.contentSecondary,
      ),
    ),
  );
}

/// A heading above a group of rows, announced as a header.
class SettingsHeading extends StatelessWidget {
  /// Creates the heading [text].
  const new(this.text, {super.key});

  /// The heading.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.x16,
      Spacing.x16,
      Spacing.x16,
      Spacing.x8,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.typography.subtitle.copyWith(
          color: context.colors.content,
        ),
      ),
    ),
  );
}
