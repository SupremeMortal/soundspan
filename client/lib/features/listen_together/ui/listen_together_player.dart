// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_view_model.dart';

/// The queue header while in a Listen Together group (doc 09, Queue): the
/// group's name and how many members it has; a tap opens Listen Together.
/// Nothing outside a group.
class ListenTogetherQueueHeader extends ConsumerWidget {
  /// Creates the header.
  const new({super.key});

  /// The key of the header.
  static const Key headerKey = ValueKey('ListenTogether.queueHeader');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(attachedListenTogetherProvider)?.group;
    if (group == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return ListTile(
      key: headerKey,
      minTileHeight: Sizes.touchTarget,
      leading: Icon(Icons.groups_rounded, color: colors.brand),
      title: Text(
        l10n.listenTogetherQueueHeader(group.name, group.members.length),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.typography.body.copyWith(color: colors.content),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.contentSecondary,
      ),
      onTap: () {
        final router = GoRouter.of(context);
        final navigator = Navigator.of(context);
        // A queue sheet closes first, so the screen is not under it.
        if (ModalRoute.of(context) is PopupRoute) navigator.pop();
        DetailNavigation.openLocation(router, RoutePaths.listenTogether);
      },
    );
  }
}

/// The message of a failed group command (doc 08, Commands From This
/// Device).
String groupCommandErrorMessage(
  AppLocalizations l10n,
  GroupCommandError error,
) => switch (error) {
  GroupCommandTimedOut() => l10n.listenTogetherNoResponse,
  GroupCommandRejected(:final message?) when message.isNotEmpty => message,
  GroupCommandRejected() => l10n.listenTogetherCommandRejected,
  GroupCommandOffline() => l10n.errorViewOffline,
  HostControlsPlayback() => l10n.listenTogetherHostControls,
  RemoteCommandUnsupported() => l10n.listenTogetherNotInGroup,
  ItemsNotShareable(:final count) => l10n.listenTogetherNotShareable(count),
};

/// Shows a snackbar for each new failed group command around [child].
class ListenTogetherNoticeListener extends ConsumerWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(attachedListenTogetherProvider, (previous, next) {
      final error = next?.lastCommandError;
      if (error == null || identical(error, previous?.lastCommandError)) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(groupCommandErrorMessage(l10n, error))),
      );
    });
    return child;
  }
}
