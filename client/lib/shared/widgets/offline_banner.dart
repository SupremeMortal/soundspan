// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';

/// The offline notice at the top of Home and Library (doc 07, Reachability
/// and Offline Mode): an [AppBanner] saying why the screen shows what is
/// saved on this device, shown whenever the state is not
/// [Reachability.online].
///
/// While the server is unreachable its Retry action probes at once. It
/// collapses when the state returns to online, at once when the platform
/// asks for reduced motion.
class OfflineBanner extends ConsumerWidget {
  /// Creates the banner.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state =
        ref.watch(reachabilityStateProvider).value ??
        ref.watch(reachabilityProvider).current;
    final banner = switch (state) {
      Reachability.online => null,
      Reachability.noNetwork => AppBanner(
        kind: AppBannerKind.offline,
        message: l10n.offlineBannerNoNetwork,
      ),
      Reachability.serverUnreachable => AppBanner(
        kind: AppBannerKind.offline,
        message: l10n.offlineBannerServerUnreachable,
        actionLabel: l10n.offlineBannerRetry,
        onAction: () => unawaited(ref.read(reachabilityProvider).probeNow()),
      ),
      Reachability.forcedOffline => AppBanner(
        kind: AppBannerKind.offline,
        message: l10n.offlineBannerForced,
      ),
    };
    final child = banner ?? const SizedBox(width: double.infinity);
    // AnimatedSize cannot run with a zero duration, so reduced motion
    // leaves it out.
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: Motion.standard,
      curve: Motion.curve,
      alignment: AlignmentDirectional.topStart,
      child: child,
    );
  }
}
