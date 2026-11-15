// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The sort menu of a library list: a button that offers [values], each
/// labelled by [label], with [selected] checked (doc 09, Library). Null
/// means the server's default order, so nothing is checked.
class LibrarySortMenu<S> extends StatelessWidget {
  /// Creates the menu.
  const new({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    super.key,
  });

  /// The key of the menu button.
  static const Key buttonKey = Key('library.sort');

  /// The orders offered, in menu order.
  final List<S> values;

  /// The current order; null for the server's default.
  final S? selected;

  /// The localized name of an order.
  final String Function(AppLocalizations l10n, S value) label;

  /// Called with the chosen order.
  final ValueChanged<S> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<S>(
      key: buttonKey,
      tooltip: l10n.librarySort,
      icon: const Icon(Icons.sort_rounded),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final value in values)
          CheckedPopupMenuItem<S>(
            value: value,
            checked: value == selected,
            child: Text(label(l10n, value)),
          ),
      ],
    );
  }
}

/// The origin filter chips All, Local, Peers and Remote (doc 09, Library),
/// shown only while the server has federation on. A null [selected] is
/// All.
class LibraryOriginChips extends ConsumerWidget {
  /// Creates the chips.
  const new({required this.selected, required this.onSelected, super.key});

  /// The current origin; null is All.
  final LibraryOrigin? selected;

  /// Called with the chosen origin.
  final ValueChanged<LibraryOrigin> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final federation = ref.watch(
      serverCapabilitiesProvider.select((c) => c.federation),
    );
    if (!federation) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final current = selected ?? LibraryOrigin.all;
    return Wrap(
      spacing: Spacing.x8,
      runSpacing: Spacing.x8,
      children: [
        for (final origin in LibraryOrigin.values)
          ChoiceChip(
            label: Text(switch (origin) {
              LibraryOrigin.all => l10n.libraryOriginAll,
              LibraryOrigin.local => l10n.libraryOriginLocal,
              LibraryOrigin.peers => l10n.libraryOriginPeers,
              LibraryOrigin.remote => l10n.libraryOriginRemote,
            }),
            selected: origin == current,
            onSelected: (_) {
              if (origin != current) onSelected(origin);
            },
          ),
      ],
    );
  }
}
