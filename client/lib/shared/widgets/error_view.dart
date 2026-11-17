// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The one place a failed load becomes what the user sees (doc 02, Error
/// Model): an [EmptyState] chosen by the type of [error].
///
/// `Unauthenticated` shows nothing, because the session controller and the
/// router take over. `FeatureDisabled` and `NotFound` offer no Retry; every
/// other error does when [onRetry] is set. A `FeatureDisabled` asks for a
/// capability refresh once, through [capabilityRefreshProvider]. The
/// server's text and the exception's `toString()` are never shown.
class ErrorView extends ConsumerStatefulWidget {
  /// Creates a view of [error] with a Retry button that calls [onRetry].
  const new({required this.error, this.onRetry, super.key});

  /// What the load failed with.
  final Object error;

  /// Loads again; null hides the Retry button.
  final VoidCallback? onRetry;

  @override
  ConsumerState<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends ConsumerState<ErrorView> {
  @override
  void initState() {
    super.initState();
    _refreshIfDisabled(null);
  }

  @override
  void didUpdateWidget(ErrorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfDisabled(oldWidget.error);
  }

  void _refreshIfDisabled(Object? previous) {
    if (widget.error is FeatureDisabled && previous is! FeatureDisabled) {
      ref.read(capabilityRefreshProvider)();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = errorMessageOf(l10n, widget.error);
    final (IconData icon, bool retry) = switch (widget.error) {
      Unauthenticated() => (Icons.lock_outline_rounded, false),
      Offline() => (Icons.cloud_off_rounded, true),
      FeatureDisabled() => (Icons.block_rounded, false),
      RateLimited() => (Icons.hourglass_empty_rounded, true),
      ServerError() || Upstream() => (Icons.dns_rounded, true),
      NotFound() => (Icons.search_off_rounded, false),
      _ => (Icons.error_outline_rounded, true),
    };
    if (widget.error is Unauthenticated) return const SizedBox.shrink();
    final onRetry = widget.onRetry;
    return EmptyState(
      icon: icon,
      message: message,
      actionLabel: retry && onRetry != null ? l10n.errorViewRetry : null,
      onAction: retry ? onRetry : null,
    );
  }
}

/// The sentence the user sees for [error], as [ErrorView] and the error
/// snackbars show it (doc 02, Error Model); empty for `Unauthenticated`,
/// which shows nothing. The server's text and the exception's `toString()`
/// are never used.
String errorMessageOf(AppLocalizations l10n, Object error) => switch (error) {
  Unauthenticated() => '',
  Offline() => l10n.errorViewOffline,
  FeatureDisabled() => l10n.errorViewFeatureDisabled,
  RateLimited() => l10n.errorViewRateLimited,
  ServerError() || Upstream() => l10n.errorViewServerProblem,
  NotFound() => l10n.errorViewNotFound,
  _ => l10n.errorViewGeneric,
};
