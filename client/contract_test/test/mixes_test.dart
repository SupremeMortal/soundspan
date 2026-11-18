// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Mixes" of doc 03's endpoint inventory: the Made For You
/// mixes and a mix's detail, against the seeded server with response
/// validation on. The contract server leaves `autoPlaylists` at its
/// default, on; a mix list may still be empty for the fixture library.
@Tags(['contract'])
library;

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late ContractCredentials credentials;
  late SoundspanApi api;
  late bool autoPlaylists;

  setUp(() async {
    credentials = ContractCredentials.load();
    api = await signedInApi(credentials, credentials.listener);
    final features = await api.send((rest) => rest.session.getSystemFeatures());
    autoPlaylists = features.autoPlaylists;
  });

  final featureDisabled = throwsA(
    isA<FeatureDisabled>()
        .having((error) => error.status, 'status', 404)
        .having((error) => error.code, 'code', 'FEATURE_DISABLED'),
  );

  test('the mixes list and the detail of the first mix, or FeatureDisabled '
      'for both', () async {
    if (!autoPlaylists) {
      await expectLater(
        api.send((rest) => rest.discovery.listMixes()),
        featureDisabled,
      );
      await expectLater(
        api.send((rest) => rest.discovery.getMix(id: 'any')),
        featureDisabled,
      );
      return;
    }
    final mixes = await api.send((rest) => rest.discovery.listMixes());
    for (final mix in mixes) {
      expect(mix.id, isNotEmpty);
      expect(mix.name, isNotEmpty);
    }
    if (mixes.isEmpty) return;
    final detail = await api.send(
      (rest) => rest.discovery.getMix(id: mixes.first.id),
    );
    expect(detail.id, mixes.first.id);
    expect(detail.name, isNotEmpty);
    for (final track in detail.tracks) {
      // The fields the client's track mapper reads; `playbackId` may be
      // absent for a track the server cannot play.
      expect(track.id, isNotEmpty);
      expect(track.title, isNotEmpty);
      expect(track.duration, greaterThanOrEqualTo(0));
    }
  });
}
