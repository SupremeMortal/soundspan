// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/profile/profile_scope.dart';
import 'package:soundspan/features/settings/ui/about/about_section.dart';
import 'package:soundspan/features/settings/ui/appearance_section.dart';
import 'package:soundspan/features/settings/ui/desktop_section.dart';
import 'package:soundspan/features/settings/ui/playback_settings_screen.dart';
import 'package:soundspan/features/settings/ui/servers_section.dart';
import 'package:soundspan/features/settings/ui/storage_settings_screen.dart';

/// The settings sections that exist, in list order.
enum SettingsSection {
  /// The user's servers.
  servers(Icons.dns_rounded),

  /// Stream quality, volume levelling and podcast playback.
  playback(Icons.play_circle_outline_rounded),

  /// Downloads, the device limit, usage and the caches.
  storage(Icons.storage_rounded),

  /// Theme and language.
  appearance(Icons.palette_rounded),

  /// The keyboard shortcuts; listed on desktop platforms and the web.
  desktop(Icons.keyboard_rounded),

  /// Licences.
  about(Icons.info_outline_rounded);

  new(this.icon);

  /// The section's icon in the list.
  final IconData icon;

  /// The sections listed on this platform: [desktop] only on a desktop
  /// platform or the web.
  static List<SettingsSection> get listed => [
    for (final section in values)
      if (section != desktop || shortcutsActive()) section,
  ];

  /// The section's location: `/settings/<name>`.
  String get path => '${RoutePaths.settings}/$name';

  /// The localized section name.
  String title(AppLocalizations l10n) => switch (this) {
    servers => l10n.screenSettingsServers,
    playback => l10n.screenSettingsPlayback,
    storage => l10n.screenSettingsStorage,
    appearance => l10n.screenSettingsAppearance,
    desktop => l10n.screenSettingsDesktop,
    about => l10n.screenSettingsAbout,
  };
}

/// Settings, on the root navigator (doc 09, Settings).
///
/// On expanded windows it is one two-column page: the section list on the
/// left and [section] (Servers when null) on the right. Otherwise
/// `/settings` is the list and each section is pushed as its own page.
class SettingsScreen extends StatelessWidget {
  /// Creates the screen showing [section], or the list when null.
  const new({this.section, super.key});

  /// The width of the section list on expanded windows.
  static const double listWidth = 320;

  /// The section shown, or null for the list.
  final SettingsSection? section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = windowClassOf(constraints.biggest);
        final section = this.section;
        if (windowClass == WindowClass.expanded) {
          final selected = section ?? SettingsSection.servers;
          return RouteTitle(
            screen: selected.title(l10n),
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.screenSettings)),
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: listWidth,
                    child: _SectionList(
                      selected: selected,
                      onSelected: (next) {
                        if (next != selected) {
                          unawaited(
                            GoRouter.of(context).replace<void>(next.path),
                          );
                        }
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _body(selected)),
                ],
              ),
            ),
          );
        }
        if (section == null) {
          return RouteTitle(
            screen: l10n.screenSettings,
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.screenSettings)),
              body: _SectionList(
                onSelected: (next) =>
                    unawaited(GoRouter.of(context).push<void>(next.path)),
              ),
            ),
          );
        }
        return RouteTitle(
          screen: section.title(l10n),
          child: Scaffold(
            appBar: AppBar(title: Text(section.title(l10n))),
            body: _body(section),
          ),
        );
      },
    );
  }

  static Widget _body(SettingsSection section) => switch (section) {
    SettingsSection.servers => const ServersSection(),
    SettingsSection.playback => const ProfileScope(
      child: PlaybackSettingsScreen(),
    ),
    SettingsSection.storage => const ProfileScope(
      child: StorageSettingsScreen(),
    ),
    SettingsSection.appearance => const AppearanceSection(),
    SettingsSection.desktop => const DesktopSection(),
    SettingsSection.about => const AboutSection(),
  };
}

class _SectionList extends StatelessWidget {
  const new({required this.onSelected, this.selected});

  final SettingsSection? selected;
  final ValueChanged<SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
      children: [
        for (final section in SettingsSection.listed)
          ListTile(
            leading: Icon(section.icon),
            title: Text(section.title(l10n)),
            selected: section == selected,
            minTileHeight: Sizes.touchTarget,
            trailing: selected == null
                ? const Icon(Icons.chevron_right_rounded)
                : null,
            onTap: () => onSelected(section),
          ),
      ],
    );
  }
}
