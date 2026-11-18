// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/downloads.dart';

import '../../features/downloads/ui/downloads_tab_test.dart' show sampleEntries;
import '../../helpers/fakes/fake_download_controller.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

const int _mb = 1024 * 1024;

void main() {
  final downloads = FakeDownloadController()
    ..setEntries(sampleEntries())
    ..setItem(
      const TrackItemKey('a'),
      itemState(DownloadStatus.completed, size: 30 * _mb),
    )
    ..setItem(
      const TrackItemKey('b'),
      itemState(DownloadStatus.running, received: 400),
    );

  goldenMatrix(
    'downloads_tab',
    overrides: downloads.overrides(),
    builder: (_) => const DownloadsTab(),
  );

  goldenMatrix(
    'downloads_server_quota_sheet',
    sizes: const [TestSizes.compact],
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: ServerQuotaSheet(
          neededBytes: 300 * _mb,
          usedBytes: 900 * _mb,
          limitBytes: 1024 * _mb,
          onManage: () {},
        ),
      ),
    ),
  );
}
