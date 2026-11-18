// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/key_expiry_monitor.dart';
import 'package:soundspan/core/profile/key_expiry_binding.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';

/// The link-expiry warning on Home (doc 04, API-Key Expiry; doc 09, Home):
/// a `warning` [AppBanner] from 14 days before the device link expires,
/// and after it has, with "Link again" opening the re-link flow. It cannot
/// be dismissed.
class ExpiryBanner extends ConsumerWidget {
  /// Creates the banner.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final message = switch (ref.watch(keyExpiryStateProvider).value) {
      KeyExpiring(:final days) => l10n.homeLinkExpiring(days),
      KeyExpired() => l10n.homeLinkExpired,
      KeyExpiryNone() || null => null,
    };
    if (message == null) return const SizedBox.shrink();
    final profileId = ref.watch(profileContextProvider).profile.id;
    return AppBanner(
      kind: AppBannerKind.linkExpiring,
      message: message,
      actionLabel: l10n.homeLinkAgain,
      onAction: () => GoRouter.of(context).go(relinkLocation(profileId)),
    );
  }
}
