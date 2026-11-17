// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The download actions every surface shares: pin with its follow-up
/// sheet, and remove behind a confirmation (doc 09, Track Actions).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/features/downloads/ui/download_sheets.dart';
import 'package:soundspan/shared/domain/track.dart';

final AppLogger _log = AppLogger.scope('DownloadActions');

/// The key of the confirm button of the remove-download dialog.
const Key removeDownloadConfirmKey = ValueKey('download.remove.confirm');

/// Pins collection [kind]/[refId] with [snapshot], then shows the sheet
/// its state calls for, if any (a server block, a device-limit shortfall,
/// unavailable tracks).
Future<void> pinCollection(
  BuildContext context,
  WidgetRef ref,
  CollectionKind kind,
  String refId,
  CollectionSnapshot snapshot,
) async {
  final controller = ref.read(downloadControllerProvider);
  try {
    await controller.pin(kind, refId, snapshot: snapshot);
  } on Object catch (error, stackTrace) {
    _log.warning('Could not pin ${kind.name}', const {}, error, stackTrace);
    return;
  }
  final state = await controller.watchCollection(kind, refId).first;
  if (state == null || !context.mounted) return;
  await showCollectionDownloadSheet(context, ref, kind, refId, state);
}

/// The snapshot of a single [track] for [pinCollection].
CollectionSnapshot trackSnapshot(Track track) => CollectionSnapshot(
  title: track.meta.title,
  subtitle: track.meta.artist,
  artworkRef: track.meta.artworkRef,
  tracks: [track],
);

/// Asks whether to remove a download and, when confirmed, unpins
/// collection [kind]/[refId].
Future<void> confirmAndUnpin(
  BuildContext context,
  WidgetRef ref,
  CollectionKind kind,
  String refId,
) async {
  if (!await confirmRemoveDownload(context)) return;
  await ref.read(downloadControllerProvider).unpin(kind, refId);
}

/// The dialog confirming that a download is removed; true when confirmed.
Future<bool> confirmRemoveDownload(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.downloadRemoveTitle),
      content: Text(l10n.downloadRemoveBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.downloadCancel),
        ),
        TextButton(
          key: removeDownloadConfirmKey,
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.downloadRemoveConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
