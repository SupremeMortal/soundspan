// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/update/update_checker.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';

/// The desktop update notice at the top of the shell content (doc 10,
/// Update Notice): "soundspan `<version>` is available" with "View release",
/// which opens the release page, and a dismiss button that hides it until
/// a higher version appears.
///
/// It starts the [UpdateChecker] after its first frame; the checker makes
/// no request where the check is disabled.
class UpdateBanner extends ConsumerStatefulWidget {
  /// Creates the banner.
  const new({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(updateCheckerProvider.notifier).check());
    });
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updateNoticeProvider);
    if (update == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return AppBanner(
      kind: AppBannerKind.update,
      message: l10n.updateBannerMessage(update.version),
      actionLabel: l10n.updateViewRelease,
      onAction: () =>
          unawaited(ref.read(urlOpenerProvider).open(update.htmlUrl)),
      onDismiss: () => unawaited(
        ref.read(updateCheckerProvider.notifier).dismiss(update.version),
      ),
    );
  }
}
