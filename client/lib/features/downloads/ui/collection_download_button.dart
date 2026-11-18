// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/features/downloads/ui/download_actions.dart';
import 'package:soundspan/features/downloads/ui/download_glyph_mapper.dart';
import 'package:soundspan/features/downloads/ui/download_providers.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

/// The Download button of an album's or playlist's `ActionBar`: Download
/// pins the collection with the [snapshot] of what the page shows; once
/// pinned it shows the collection's glyph and its action is "Remove
/// download", behind a confirmation.
class CollectionDownloadButton extends ConsumerWidget {
  /// Creates the button of collection [kind]/[refId].
  const new({
    required this.kind,
    required this.refId,
    required this.snapshot,
    super.key,
  });

  /// The button for the action bar, or null where the platform does not
  /// download, so the bar leaves it out.
  static Widget? orNull(
    WidgetRef ref, {
    required CollectionKind kind,
    required String refId,
    required CollectionSnapshot Function() snapshot,
  }) => ref.watch(downloadsAvailableProvider)
      ? CollectionDownloadButton(kind: kind, refId: refId, snapshot: snapshot)
      : null;

  /// The key of the Download button.
  static const Key downloadKey = ValueKey('CollectionDownloadButton.download');

  /// The key of the Remove download button.
  static const Key removeKey = ValueKey('CollectionDownloadButton.remove');

  /// The collection's kind.
  final CollectionKind kind;

  /// The album or playlist id.
  final String refId;

  /// What the page shows of the collection, read when it is pinned.
  final CollectionSnapshot Function() snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref
        .watch(collectionDownloadStateProvider((kind: kind, refId: refId)))
        .value;
    if (state == null) {
      return IconButton(
        key: downloadKey,
        tooltip: l10n.menuDownload,
        color: context.colors.contentSecondary,
        icon: const Icon(Icons.download_rounded),
        onPressed: () =>
            unawaited(pinCollection(context, ref, kind, refId, snapshot())),
      );
    }
    final glyph = glyphOfCollection(state);
    return IconButton(
      key: removeKey,
      tooltip: l10n.menuRemoveDownload,
      icon: DownloadGlyph(
        state: glyph == DownloadGlyphState.none
            ? DownloadGlyphState.queued
            : glyph,
        size: 24,
      ),
      onPressed: () => unawaited(confirmAndUnpin(context, ref, kind, refId)),
    );
  }
}
