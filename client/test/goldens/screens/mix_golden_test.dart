// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/mixes/mixes.dart';

import '../../features/detail_fixtures.dart';
import '../../helpers/fake_mix_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/golden.dart';

class _MixesOn extends ServerCapabilitiesNotifier {
  @override
  ServerCapabilities build() => ServerCapabilities(
    serverVersion: Version.tryParse('2.7.0'),
    hasP6SelfRevoke: true,
    hasP7PlayMarker: true,
    hasP8PlayedAt: true,
    autoPlaylists: true,
  );
}

void main() {
  final mixes = FakeMixRepository();
  mixes.mixes['m1'] = MixDetail(
    id: 'm1',
    name: 'Daily Mix 1',
    description: 'Upbeat picks from the artists you play most',
    artworkRefs: const ['cover-1', 'cover-2', 'cover-3', 'cover-4'],
    tracks: [
      for (var n = 1; n <= 4; n++)
        fixtureTrack(n, artworkRef: 'cover-$n', playable: n != 3),
    ],
  );
  goldenMatrix(
    'mix',
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: const MixDetailScreen(mixId: 'm1'),
    ),
    overrides: [
      ...FakeRepositories().overrides,
      mixes.providerOverride,
      serverCapabilitiesProvider.overrideWith(_MixesOn.new),
    ],
  );
}
