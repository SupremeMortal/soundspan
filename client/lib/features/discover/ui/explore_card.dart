// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';

/// The "Explore" card at the end of Home on compact and medium windows,
/// which opens Explore. It is empty on expanded windows, where the sidebar
/// has the entry. Explore has radio on every server, so the card does not
/// depend on `discovery`.
class ExploreCard extends StatelessWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final windowClass = WindowClass.of(context);
    if (windowClass == WindowClass.expanded) {
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
          leading: Icon(Icons.explore_outlined, color: colors.content),
          title: Text(
            l10n.navExplore,
            style: typography.title.copyWith(color: colors.content),
          ),
          subtitle: Text(
            l10n.homeExploreCard,
            style: typography.bodySmall.copyWith(
              color: colors.contentSecondary,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.contentSecondary,
          ),
          onTap: () => DetailNavigation.openExplore(context),
        ),
      ),
    );
  }
}
