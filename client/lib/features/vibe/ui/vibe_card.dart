// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/vibe/vibe_providers.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';

/// The "Vibe" card after the Explore card at the end of Home on compact
/// and medium windows, which opens Vibe. It is empty on expanded windows,
/// where the sidebar has the entry, and while the server has no similar
/// tracks ([vibeAvailableProvider]).
class VibeCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowClass = WindowClass.of(context);
    if (windowClass == WindowClass.expanded ||
        !ref.watch(vibeAvailableProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final gutter = pageGutter(windowClass);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Spacing.x24),
      child: Material(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: Sizes.touchTarget,
          leading: Icon(Icons.graphic_eq_rounded, color: colors.content),
          title: Text(
            l10n.navVibe,
            style: typography.title.copyWith(color: colors.content),
          ),
          subtitle: Text(
            l10n.homeVibeCard,
            style: typography.bodySmall.copyWith(
              color: colors.contentSecondary,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.contentSecondary,
          ),
          onTap: () => DetailNavigation.openVibe(context),
        ),
      ),
    );
  }
}
