// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/capability_refresher.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/features/connect/ui/connect_layout.dart';

/// `/connect/probe?profile=<id>`: the signed-in profile [profileId] talks to
/// a server older than the oldest version this app supports (doc 04,
/// Capability Discovery and Version Gate).
///
/// The router's guard sends every shell location here while that is so.
/// "Check again" refreshes the capabilities and returns to the shell once
/// the version is in range; "Switch server" opens the Servers settings. The
/// profile stays signed in and its local data is untouched.
class ServerTooOldScreen extends ConsumerStatefulWidget {
  /// Creates the screen for profile [profileId].
  const new({required this.profileId, super.key});

  /// The active profile whose server is too old.
  final String profileId;

  @override
  ConsumerState<ServerTooOldScreen> createState() => _ServerTooOldScreenState();
}

class _ServerTooOldScreenState extends ConsumerState<ServerTooOldScreen> {
  bool _checking = false;

  /// The active profile's container when it is [ServerTooOldScreen.profileId].
  ProviderContainer? _container() {
    final runtime = ref.read(profileRuntimeProvider);
    final container = runtime.container;
    if (runtime.state.value is! ProfileRuntimeActive || container == null) {
      return null;
    }
    return container.read(profileContextProvider).profile.id == widget.profileId
        ? container
        : null;
  }

  Future<void> _checkAgain() async {
    final container = _container();
    if (container == null) {
      GoRouter.of(context).go(RoutePaths.home);
      return;
    }
    setState(() => _checking = true);
    await container.read(capabilityRefresherProvider).refresh();
    if (!mounted) return;
    setState(() => _checking = false);
    final version = container.read(serverCapabilitiesProvider).serverVersion;
    if (!ref.read(versionGateProvider).evaluate(version).blocks) {
      GoRouter.of(context).go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gate = ref.watch(versionGateProvider);
    final runtime = ref.watch(profileRuntimeProvider);
    return ValueListenableBuilder<ProfileRuntimeState>(
      valueListenable: runtime.state,
      builder: (context, _, _) {
        final version = _container()
            ?.read(serverCapabilitiesProvider)
            .serverVersion;
        return ConnectLayout(
          screen: l10n.screenConnectProbe,
          children: [
            Semantics(
              container: true,
              liveRegion: true,
              child: Text(
                l10n.connectServerTooOld(
                  gate.min.toString(),
                  version?.toString() ?? '?',
                ),
                textAlign: TextAlign.center,
                style: context.typography.subtitle.copyWith(
                  color: context.colors.content,
                ),
              ),
            ),
            const SizedBox(height: Spacing.x24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(Sizes.touchTarget),
              ),
              onPressed: _checking ? null : () => unawaited(_checkAgain()),
              child: Text(l10n.connectServerTooOldCheckAgain),
            ),
            const SizedBox(height: Spacing.x8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(Sizes.touchTarget),
              ),
              onPressed: () =>
                  GoRouter.of(context).go(RoutePaths.settingsServers),
              child: Text(l10n.connectServerTooOldSwitchServer),
            ),
          ],
        );
      },
    );
  }
}
