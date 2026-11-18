// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';

/// Shows the active profile's outbox notices as snackbars (doc 07, Worker):
/// items gone and conflicts. It sits inside the profile scope, below the
/// app's [ScaffoldMessenger].
class OutboxNoticeListener extends ConsumerStatefulWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The shell.
  final Widget child;

  @override
  ConsumerState<OutboxNoticeListener> createState() =>
      _OutboxNoticeListenerState();
}

class _OutboxNoticeListenerState extends ConsumerState<OutboxNoticeListener> {
  StreamSubscription<OutboxNotice>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(outboxProvider).notices.listen(_show);
  }

  void _show(OutboxNotice notice) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = switch (notice) {
      OutboxItemsGone() => l10n.outboxItemsGoneMessage,
      OutboxConflict() => l10n.outboxConflictMessage,
    };
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
