// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_scope.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/platform/log_export/log_export.dart';
import 'package:soundspan/shared/providers/package_info.dart';

final AppLogger _log = AppLogger.scope('Settings');

/// Settings → About: the app's version, the active profile's pending
/// changes, the log export and the row that opens the open-source licences.
class AboutSection extends StatelessWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
    children: [
      const VersionTile(),
      const ProfileScope(child: PendingChangesTile()),
      const ExportLogsTile(),
      ListTile(
        leading: const Icon(Icons.description_rounded),
        title: Text(AppLocalizations.of(context).settingsAboutLicenses),
        minTileHeight: Sizes.touchTarget,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => unawaited(
          GoRouter.of(context).push<void>(RoutePaths.settingsAboutLicenses),
        ),
      ),
    ],
  );
}

/// "Pending changes: N": the active profile's outbox count, shown once it
/// is known.
class PendingChangesTile extends ConsumerWidget {
  /// Creates the row; it reads the profile scope.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ValueListenableBuilder<int?>(
        valueListenable: ref.watch(outboxProvider).pendingCount,
        builder: (context, count, _) => count == null
            ? const SizedBox.shrink()
            : ListTile(
                leading: const Icon(Icons.cloud_upload_rounded),
                title: Text(
                  AppLocalizations.of(context)
                      .settingsAboutPendingChanges(count),
                ),
                minTileHeight: Sizes.touchTarget,
              ),
      );
}

/// "Version": `<version> (<build number>)`, followed by the release channel
/// when it is not `stable`. Nothing is shown until the version is read.
class VersionTile extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).value;
    if (info == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final channel = ref.watch(buildChannelProvider);
    return ListTile(
      leading: const Icon(Icons.info_outline_rounded),
      title: Text(l10n.settingsAboutVersion),
      subtitle: Text(
        channel == 'stable'
            ? l10n.settingsAboutVersionValue(info.version, info.buildNumber)
            : l10n.settingsAboutVersionWithChannel(
                info.version,
                info.buildNumber,
                channel,
              ),
      ),
      minTileHeight: Sizes.touchTarget,
    );
  }
}

/// "Export logs": hands the device's logs to the user through the
/// [LogExporter], disabled with a progress indicator while it runs, then
/// reports the result in a snackbar (nothing when the user cancelled).
class ExportLogsTile extends ConsumerStatefulWidget {
  /// Creates the row.
  const new({super.key});

  @override
  ConsumerState<ExportLogsTile> createState() => _ExportLogsTileState();
}

class _ExportLogsTileState extends ConsumerState<ExportLogsTile> {
  bool _running = false;

  Future<void> _export() async {
    setState(() => _running = true);
    final result = await ref.read(logExporterProvider).export();
    if (result == LogExportResult.failed) _log.warning('Export logs failed');
    if (!mounted) return;
    setState(() => _running = false);
    final l10n = AppLocalizations.of(context);
    final message = switch (result) {
      LogExportResult.done => l10n.settingsAboutExportLogsDone,
      LogExportResult.nothingToExport => l10n.settingsAboutExportLogsNothing,
      LogExportResult.failed => l10n.settingsAboutExportLogsFailed,
      LogExportResult.cancelled => null,
    };
    if (message != null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.bug_report_rounded),
    title: Text(AppLocalizations.of(context).settingsAboutExportLogs),
    minTileHeight: Sizes.touchTarget,
    enabled: !_running,
    trailing: _running
        ? const SizedBox.square(
            dimension: Spacing.x24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : null,
    onTap: _running ? null : () => unawaited(_export()),
  );
}
