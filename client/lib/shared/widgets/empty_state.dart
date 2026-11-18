// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// What a screen shows when it has nothing to show (doc 09, Components): an
/// icon, one sentence and at most one action, centred and at most
/// [maxWidth] wide.
class EmptyState extends StatelessWidget {
  /// Creates an empty state saying [message] under [icon], with an action
  /// button when both [actionLabel] and [onAction] are given.
  const new({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// The glyph above the sentence.
  final IconData icon;

  /// The one sentence, already localized.
  final String message;

  /// The action button's text, already localized.
  final String? actionLabel;

  /// Called by the action button.
  final VoidCallback? onAction;

  /// The widest the content gets.
  static const double maxWidth = 360;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Spacing.x48, color: colors.contentMuted),
              const SizedBox(height: Spacing.x16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: typography.body.copyWith(color: colors.contentBody),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Spacing.x16),
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
