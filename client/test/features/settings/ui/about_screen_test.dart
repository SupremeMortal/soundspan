// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/features/settings/ui/about/about_section.dart';
import 'package:soundspan/features/settings/ui/settings_screen.dart';
import 'package:soundspan/platform/log_export/log_export.dart';
import 'package:soundspan/shared/providers/package_info.dart';

import '../../../core/logging/recording_sink.dart';
import '../../../helpers/fake_log_exporter.dart';
import '../../../helpers/golden.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_root.dart';

/// The package info of a `1.2.3+45` build.
final PackageInfo fakePackageInfo = PackageInfo(
  appName: 'soundspan',
  packageName: 'com.soundspan.client',
  version: '1.2.3',
  buildNumber: '45',
);

List<Override> aboutOverrides(
  FakeLogExporter exporter, {
  String channel = 'stable',
}) => [
  packageInfoProvider.overrideWith((ref) async => fakePackageInfo),
  buildChannelProvider.overrideWithValue(channel),
  logExporterProvider.overrideWithValue(exporter),
];

Future<void> pumpRows(
  WidgetTester tester,
  FakeLogExporter exporter, {
  String channel = 'stable',
}) async {
  await tester.pumpApp(
    const Scaffold(body: Column(children: [VersionTile(), ExportLogsTile()])),
    overrides: aboutOverrides(exporter, channel: channel),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the version and build number on stable', (tester) async {
    await pumpRows(tester, FakeLogExporter());
    expect(find.text('1.2.3 (45)'), findsOneWidget);
    expect(find.textContaining('stable'), findsNothing);
  });

  testWidgets('shows the channel when it is not stable', (tester) async {
    await pumpRows(tester, FakeLogExporter(), channel: 'dev');
    expect(find.text('1.2.3 (45) · dev'), findsOneWidget);
  });

  testWidgets('Export logs calls the exporter once and is disabled while '
      'it runs', (tester) async {
    final exporter = FakeLogExporter()..pending = Completer<LogExportResult>();
    await pumpRows(tester, exporter);

    await tester.tap(find.text('Export logs'));
    await tester.pump();
    expect(exporter.calls, 1);
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Export logs'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Export logs'), warnIfMissed: false);
    await tester.pump();
    expect(exporter.calls, 1);

    exporter.pending!.complete(LogExportResult.done);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Export logs'),
              matching: find.byType(ListTile),
            ),
          )
          .enabled,
      isTrue,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final (result, message) in [
    (LogExportResult.done, 'Logs exported'),
    (LogExportResult.nothingToExport, 'No logs to export'),
    (LogExportResult.failed, 'Couldn’t export logs'),
  ]) {
    testWidgets('$result shows "$message"', (tester) async {
      await pumpRows(tester, FakeLogExporter(result: result));
      await tester.tap(find.text('Export logs'));
      await tester.pump();
      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('cancelled shows no message', (tester) async {
    await pumpRows(tester, FakeLogExporter(result: LogExportResult.cancelled));
    await tester.tap(find.text('Export logs'));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failed is logged at warning', (tester) async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
    addTearDown(AppLogging.reset);
    await pumpRows(tester, FakeLogExporter(result: LogExportResult.failed));
    await tester.tap(find.text('Export logs'));
    await tester.pump();
    expect(
      sink.entries.where((e) => e.level == 'warning' && e.scope == 'Settings'),
      hasLength(1),
    );
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets('Settings → About keeps the pending-changes row and meets '
        'the guidelines at ${size.width.toInt()}', (tester) async {
      final root = await tester.pumpSoundspanApp(
        stored: StoredProfile.signedIn,
        size: size,
        overrides: aboutOverrides(FakeLogExporter()),
      );
      root.container.read(routerProvider).go(SettingsSection.about.path);
      await tester.pumpAndSettle();
      expect(find.byType(PendingChangesTile), findsOneWidget);
      expect(find.text('1.2.3 (45)'), findsOneWidget);
      expect(find.text('Export logs'), findsOneWidget);
      expect(find.text('Licences'), findsOneWidget);
      await expectMeetsGuidelines(tester);
    });
  }

  goldenMatrix(
    'about_screen',
    sizes: const [TestSizes.compact, TestSizes.expanded],
    overrides: aboutOverrides(FakeLogExporter()),
    builder: (_) => const AboutSection(),
  );
}
