// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/player/ui/queue_view.dart';

/// Opens the queue as a modal sheet over the now-playing screen (doc 09,
/// Now Playing, Queue, Lyrics). The sheet reads the providers of
/// [context]'s scope, so it shows the profile's queue although its route
/// sits above the profile scope.
///
/// [closeActivator] closes the sheet again, as the shortcut that opened it.
Future<void> showQueueSheet(
  BuildContext context, {
  ShortcutActivator? closeActivator,
}) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (sheetContext) {
      Widget sheet = UncontrolledProviderScope(
        container: container,
        child: const QueueSheet(),
      );
      if (closeActivator != null) {
        sheet = CallbackShortcuts(
          bindings: {
            closeActivator: () => Navigator.of(sheetContext).maybePop(),
          },
          child: Focus(autofocus: true, skipTraversal: true, child: sheet),
        );
      }
      return sheet;
    },
  );
}

/// The content of the queue sheet: a "Queue" title above the [QueueView],
/// in a sheet that opens at 70 % of the height and drags to full height.
class QueueSheet extends StatelessWidget {
  /// Creates the sheet content.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.x16),
            child: Semantics(
              header: true,
              child: Text(
                l10n.queueTitle,
                style: context.typography.title.copyWith(
                  color: context.colors.content,
                ),
              ),
            ),
          ),
          Expanded(child: QueueView(scrollController: scrollController)),
        ],
      ),
    );
  }
}
