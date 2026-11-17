// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart' show shellActiveDotKey;
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/social/social.dart';

/// The upper-case first letter of the name [profile]'s user goes by, or an
/// empty string without a profile.
String avatarInitial(Profile? profile) {
  final name = profile == null
      ? ''
      : (profile.userDisplayName?.trim().isNotEmpty ?? false)
      ? profile.userDisplayName!.trim()
      : profile.username.trim();
  return name.isEmpty ? '' : name.characters.first.toUpperCase();
}

/// The avatar button of the shell (doc 09, Shell by Window Class).
///
/// It shows the active user's initial and opens the account menu: the
/// server switcher, "Add server", "Listen Together" ("In a group" with a
/// `brand` dot while in one), "Activity" and "Settings". Listen Together and
/// Activity are on compact and medium windows only; expanded ones have the
/// sidebar item and the top-bar toggle. On compact windows the menu is a bottom sheet; otherwise it
/// is a popup under the button.
class AvatarButton extends ConsumerWidget {
  /// Creates the button.
  const new({super.key});

  /// The key of the button.
  static const Key buttonKey = Key('shell.avatar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final activeId = ref.watch(activeProfileIdProvider);
    final active = profiles.firstWhereOrNull((p) => p.id == activeId);
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colors.accent,
      foregroundColor: colors.onAccent,
      child: ExcludeSemantics(
        child: Text(
          avatarInitial(active),
          style: context.typography.body.copyWith(
            color: colors.onAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final entries = _entries(context, ref, profiles, activeId);
    if (WindowClass.of(context) == WindowClass.compact) {
      return IconButton(
        key: buttonKey,
        tooltip: l10n.shellAccountMenu,
        icon: avatar,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => AvatarMenuSheet(entries: entries),
        ),
      );
    }
    return MenuAnchor(
      menuChildren: [
        for (final entry in entries)
          if (entry.isHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.x16,
                Spacing.x12,
                Spacing.x16,
                Spacing.x4,
              ),
              child: Text(
                entry.label,
                style: context.typography.overline.copyWith(
                  color: colors.contentSecondary,
                ),
              ),
            )
          else
            MenuItemButton(
              leadingIcon: _marked(context, entry, Icon(entry.icon)),
              trailingIcon: entry.current
                  ? Icon(
                      Icons.check_rounded,
                      color: colors.brand,
                      semanticLabel: l10n.shellMenuCurrentServer,
                    )
                  : null,
              onPressed: entry.onSelected,
              child: Text(entry.label),
            ),
      ],
      builder: (context, controller, _) => IconButton(
        key: buttonKey,
        tooltip: l10n.shellAccountMenu,
        icon: avatar,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  List<AvatarMenuEntry> _entries(
    BuildContext context,
    WidgetRef ref,
    List<Profile> profiles,
    String? activeId,
  ) {
    final l10n = AppLocalizations.of(context);
    final runtime = ref.read(profileRuntimeProvider);
    // Captured now: the button's element may be rebuilt while the menu is
    // open, so the callbacks must not look the router up from it.
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.maybeOf(context);
    final container = ProviderScope.containerOf(context);
    final expanded = WindowClass.of(context) == WindowClass.expanded;
    final inGroup = ref.watch(inListenTogetherGroupProvider);
    return [
      AvatarMenuEntry.header(l10n.shellMenuServers),
      for (final profile in profiles)
        AvatarMenuEntry(
          label: profile.displayName,
          icon: Icons.dns_rounded,
          current: profile.id == activeId,
          onSelected: () => unawaited(runtime.switchTo(profile.id)),
        ),
      AvatarMenuEntry(
        label: l10n.shellMenuAddServer,
        icon: Icons.add_rounded,
        onSelected: () => unawaited(router?.push<void>(RoutePaths.connect)),
      ),
      if (!expanded)
        AvatarMenuEntry(
          label: inGroup
              ? l10n.listenTogetherInGroup
              : l10n.listenTogetherTitle,
          icon: Icons.groups_rounded,
          dot: inGroup,
          onSelected: () {
            if (router != null) {
              DetailNavigation.openLocation(router, RoutePaths.listenTogether);
            }
          },
        ),
      if (!expanded && navigator != null)
        AvatarMenuEntry(
          label: l10n.shellMenuActivity,
          icon: Icons.group_rounded,
          onSelected: () => unawaited(
            showActivitySheet(navigator.context, container: container),
          ),
        ),
      AvatarMenuEntry(
        label: l10n.shellMenuSettings,
        icon: Icons.settings_rounded,
        onSelected: () => unawaited(router?.push<void>(RoutePaths.settings)),
      ),
    ];
  }
}

/// One line of the account menu.
@immutable
class AvatarMenuEntry {
  /// An entry that runs [onSelected]; [current] marks the server the app
  /// shows.
  const new({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.current = false,
    this.dot = false,
  }) : isHeader = false;

  /// A heading above a group of entries.
  const new header(this.label)
    : icon = Icons.label_rounded,
      onSelected = null,
      current = false,
      dot = false,
      isHeader = true;

  /// The localized label, or the server's display name.
  final String label;

  /// The leading icon.
  final IconData icon;

  /// What choosing the entry does; null for a heading.
  final VoidCallback? onSelected;

  /// Whether the entry is the server the app shows.
  final bool current;

  /// Whether the entry is a heading.
  final bool isHeader;

  /// Whether a `brand` dot marks the icon (Listen Together while in a
  /// group).
  final bool dot;
}

/// [icon], marked with a `brand` dot when [entry] asks for one.
Widget _marked(BuildContext context, AvatarMenuEntry entry, Widget icon) =>
    entry.dot
    ? Badge(
        key: shellActiveDotKey,
        smallSize: 8,
        backgroundColor: context.colors.brand,
        child: icon,
      )
    : icon;

/// The account menu as a bottom sheet, for compact windows.
class AvatarMenuSheet extends StatelessWidget {
  /// Creates the sheet listing [entries].
  const new({required this.entries, super.key});

  /// The menu's entries.
  final List<AvatarMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries)
              if (entry.isHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.x16,
                    Spacing.x8,
                    Spacing.x16,
                    Spacing.x4,
                  ),
                  child: Text(
                    entry.label,
                    style: context.typography.overline.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                )
              else
                ListTile(
                  leading: _marked(context, entry, Icon(entry.icon)),
                  title: Text(entry.label),
                  minTileHeight: Sizes.touchTarget,
                  trailing: entry.current
                      ? Icon(
                          Icons.check_rounded,
                          color: colors.brand,
                          semanticLabel: l10n.shellMenuCurrentServer,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    entry.onSelected?.call();
                  },
                ),
          ],
        ),
      ),
    );
  }
}
