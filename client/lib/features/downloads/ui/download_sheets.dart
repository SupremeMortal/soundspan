// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The sheets that explain a download that did not fully start: the
/// server's limit, downloads turned off, the device limit, and the tracks
/// that cannot be downloaded (doc 07, Requesting a Download; Storage
/// Accounting and Quota). No text here names a source.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/shared/util/byte_format.dart';

/// The message of an unavailable item: the three reasons the server names,
/// and "Not available" for any other.
String unavailableReasonMessage(
  AppLocalizations l10n,
  DownloadUnavailableReason? reason,
) => switch (reason) {
  DownloadUnavailableReason.downloadsDisabled =>
    l10n.downloadUnavailableDisabled,
  DownloadUnavailableReason.trackUnavailable => l10n.downloadUnavailableGone,
  DownloadUnavailableReason.sourceUnavailable =>
    l10n.downloadUnavailableAccount,
  null => l10n.downloadUnavailableOther,
};

/// Shows the sheet that explains [state] of collection [kind]/[refId], if
/// any: a server block, a device-limit shortfall, or the tracks that
/// cannot be downloaded, in that order. Does nothing when everything is
/// on its way.
Future<void> showCollectionDownloadSheet(
  BuildContext context,
  WidgetRef ref,
  CollectionKind kind,
  String refId,
  CollectionDownloadState state,
) async {
  final controller = ref.read(downloadControllerProvider);
  final Widget sheet;
  final shortfall = state.quotaShortfall;
  if (state.blockedReason == CollectionBlock.serverQuota) {
    final detail = state.blockedDetail ?? const {};
    int bytes(String name) => switch (detail[name]) {
      final num value => value.toInt(),
      _ => 0,
    };
    final router = GoRouter.maybeOf(context);
    sheet = ServerQuotaSheet(
      neededBytes: bytes('estimatedBytes'),
      usedBytes: bytes('usedBytes'),
      limitBytes: bytes('limitBytes'),
      onManage: () =>
          router?.go('${RoutePaths.library}/${LibraryTab.downloads.name}'),
    );
  } else if (state.blockedReason == CollectionBlock.disabledByServer) {
    sheet = const DownloadsDisabledSheet();
  } else if (shortfall != null) {
    sheet = QuotaShortfallSheet(
      shortfall: shortfall,
      onRaiseLimit: () async {
        final bytes = await controller.deviceLimitToFitAll();
        if (bytes == null) return false;
        await controller.raiseDeviceLimit(bytes);
        return true;
      },
    );
  } else if (state.unavailableCount > 0) {
    final items = await controller.unavailableItems(kind, refId);
    if (items.isEmpty || !context.mounted) return;
    sheet = UnavailableItemsSheet(items: items);
  } else {
    return;
  }
  if (!context.mounted) return;
  final colors = context.colors;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: colors.surfaceOverlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.large)),
    ),
    builder: (_) => SafeArea(child: sheet),
  );
}

/// The common layout of the download sheets: a title, body lines, and
/// actions at the end.
class _SheetBody extends StatelessWidget {
  const new({required this.title, required this.lines, required this.actions});

  final String title;
  final List<Widget> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.x24,
        0,
        Spacing.x24,
        Spacing.x16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.typography.subtitle.copyWith(
                color: colors.content,
              ),
            ),
          ),
          const SizedBox(height: Spacing.x12),
          ...lines,
          const SizedBox(height: Spacing.x16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Spacing.x8,
            runSpacing: Spacing.x8,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.x4),
    child: Text(
      text,
      style: context.typography.body.copyWith(
        color: context.colors.contentBody,
      ),
    ),
  );
}

String _size(BuildContext context, int bytes) =>
    formatBytes(bytes, Localizations.localeOf(context).toString());

/// The server refused the download because the user's limit there is
/// reached: what it needs, what is used and the limit, and "Manage
/// downloads". No browser link is opened from here.
class ServerQuotaSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({
    required this.neededBytes,
    required this.usedBytes,
    required this.limitBytes,
    required this.onManage,
    super.key,
  });

  /// What the download needs.
  final int neededBytes;

  /// What the user's downloads already use on the server.
  final int usedBytes;

  /// The user's limit on the server.
  final int limitBytes;

  /// Opens the Downloads tab.
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetBody(
      title: l10n.downloadServerQuotaTitle,
      lines: [
        _Line(l10n.downloadSizeNeeded(_size(context, neededBytes))),
        _Line(l10n.downloadSizeUsed(_size(context, usedBytes))),
        _Line(l10n.downloadSizeLimit(_size(context, limitBytes))),
        const SizedBox(height: Spacing.x8),
        _Line(l10n.downloadServerQuotaBody),
      ],
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onManage();
          },
          child: Text(l10n.downloadManage),
        ),
      ],
    );
  }
}

/// The server's administrator turned downloads off.
class DownloadsDisabledSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetBody(
      title: l10n.downloadUnavailableDisabled,
      lines: const [],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.downloadClose),
        ),
      ],
    );
  }
}

/// Part of the download does not fit in the device limit: how much more
/// it needs and the room left, with "Raise limit" and "Download what
/// fits".
class QuotaShortfallSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({required this.shortfall, required this.onRaiseLimit, super.key});

  /// What the waiting items need and the room left for them.
  final QuotaShortfall shortfall;

  /// Raises the device limit so everything fits; answers false when free
  /// disk space, not the limit, is the bound, and the sheet explains that.
  final Future<bool> Function() onRaiseLimit;

  @override
  State<QuotaShortfallSheet> createState() => _QuotaShortfallSheetState();
}

class _QuotaShortfallSheetState extends State<QuotaShortfallSheet> {
  bool _diskFull = false;
  bool _busy = false;

  Future<void> _raise() async {
    setState(() => _busy = true);
    final raised = await widget.onRaiseLimit();
    if (!mounted) return;
    if (raised) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _diskFull = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shortfall = widget.shortfall;
    final missing = shortfall.neededBytes - shortfall.availableBytes;
    return _SheetBody(
      title: l10n.downloadShortfallTitle(
        _size(context, missing < 0 ? 0 : missing),
      ),
      lines: [
        _Line(l10n.downloadSizeNeeded(_size(context, shortfall.neededBytes))),
        _Line(
          l10n.downloadSizeAvailable(_size(context, shortfall.availableBytes)),
        ),
        if (_diskFull) ...[
          const SizedBox(height: Spacing.x8),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.downloadRaiseLimitDiskFull,
              style: context.typography.body.copyWith(
                color: context.colors.danger,
              ),
            ),
          ),
        ],
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.downloadWhatFits),
        ),
        FilledButton(
          onPressed: _busy || _diskFull ? null : () => unawaited(_raise()),
          child: Text(l10n.downloadRaiseLimit),
        ),
      ],
    );
  }
}

/// The tracks of a collection that cannot be downloaded, greyed out, each
/// with its reason.
class UnavailableItemsSheet extends StatelessWidget {
  /// Creates the sheet listing [items].
  const new({required this.items, super.key});

  /// The unavailable tracks.
  final List<UnavailableDownload> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    return _SheetBody(
      title: l10n.downloadUnavailableTitle,
      lines: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.x8),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.copyWith(color: colors.contentMuted),
                  ),
                  Text(
                    unavailableReasonMessage(l10n, item.reason),
                    style: typography.bodySmall.copyWith(
                      color: colors.contentMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.downloadClose),
        ),
      ],
    );
  }
}
