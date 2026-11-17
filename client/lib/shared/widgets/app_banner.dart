// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// The kinds of [AppBanner].
enum AppBannerKind {
  /// The app is offline or the server cannot be reached; `warning`.
  offline,

  /// The device link expires soon; `warning`.
  linkExpiring,

  /// A notice about the server, such as "newer than tested" or "version
  /// unknown"; neutral.
  serverNotice,

  /// A newer client release exists (desktop update notice); neutral.
  update,
}

/// An inline, full-width notice at the top of a screen (doc 09, Components;
/// named `AppBanner` because Flutter already has a `Banner`).
///
/// It is a live region, so a screen reader announces it when it appears.
/// The action button shows when both [actionLabel] and [onAction] are
/// given, the dismiss button only when [onDismiss] is.
class AppBanner extends StatelessWidget {
  /// Creates a banner of [kind] saying [message].
  const new({
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    super.key,
  });

  /// The kind, which picks the icon and colour.
  final AppBannerKind kind;

  /// The text, already localized.
  final String message;

  /// The action button's text, already localized.
  final String? actionLabel;

  /// Called by the action button.
  final VoidCallback? onAction;

  /// Called by the dismiss button; null hides it.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final (IconData icon, Color iconColor) = switch (kind) {
      AppBannerKind.offline => (Icons.cloud_off_rounded, colors.warning),
      AppBannerKind.linkExpiring => (Icons.schedule_rounded, colors.warning),
      AppBannerKind.serverNotice => (
        Icons.info_outline_rounded,
        colors.contentSecondary,
      ),
      AppBannerKind.update => (
        Icons.new_releases_outlined,
        colors.contentSecondary,
      ),
    };
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;
    final onDismiss = this.onDismiss;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceActive,
          border: kind == AppBannerKind.linkExpiring
              ? Border(left: BorderSide(color: colors.warning, width: 4))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: Spacing.x16,
            end: Spacing.x8,
            top: Spacing.x4,
            bottom: Spacing.x4,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(icon, size: 20, color: iconColor)),
                const SizedBox(width: Spacing.x12),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    container: true,
                    child: Text(
                      message,
                      style: typography.bodySmall.copyWith(
                        color: colors.contentBody,
                      ),
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: Spacing.x8),
                  // `content`, not the button's `brand`: only `content`
                  // keeps 4.5:1 on `surfaceActive` in every theme.
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.content,
                    ),
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ],
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    tooltip: AppLocalizations.of(context).appBannerDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.contentSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
