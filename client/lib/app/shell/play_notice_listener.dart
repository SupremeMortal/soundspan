// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/error_view.dart';

/// Shows the active profile's [PlayNotice]s as snackbars: a queue cut at
/// its maximum size, and a collection that failed to load, in the words of
/// the shared error mapping ([errorMessageOf]). It sits inside the profile
/// scope, below the app's [ScaffoldMessenger].
class PlayNoticeListener extends ConsumerStatefulWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The shell.
  final Widget child;

  @override
  ConsumerState<PlayNoticeListener> createState() => _PlayNoticeListenerState();
}

class _PlayNoticeListenerState extends ConsumerState<PlayNoticeListener> {
  StreamSubscription<PlayNotice>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(playNoticesProvider).stream.listen(_show);
  }

  void _show(PlayNotice notice) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = switch (notice) {
      QueueTruncated(:final queued) => l10n.playQueueTruncated(queued),
      PlayLoadFailed(:final error) => errorMessageOf(l10n, error),
    };
    if (message.isEmpty) return;
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
