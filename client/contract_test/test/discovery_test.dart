// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Discovery" of doc 03's endpoint inventory: the three
/// reads behind the Home discovery shelves and Explore, against the seeded
/// server with response validation on. The fixture server has no
/// third-party keys, so empty lists are acceptable.
@Tags(['contract'])
library;

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late ContractCredentials credentials;
  late SoundspanApi api;
  late bool discovery;

  setUp(() async {
    credentials = ContractCredentials.load();
    api = await signedInApi(credentials, credentials.listener);
    final features = await api.send((rest) => rest.session.getSystemFeatures());
    discovery = features.discovery;
  });

  /// Runs [call]: with discovery on it must decode; with it off it must
  /// throw [FeatureDisabled] with status 404 and code `FEATURE_DISABLED`.
  Future<void> gated<T>(
    Future<T> Function(SoundspanRestClient rest) call,
    void Function(T value) check,
  ) async {
    if (discovery) {
      check(await api.send(call));
      return;
    }
    await expectLater(
      api.send(call),
      throwsA(
        isA<FeatureDisabled>()
            .having((error) => error.status, 'status', 404)
            .having((error) => error.code, 'code', 'FEATURE_DISABLED'),
      ),
    );
  }

  test('recommendations for you', () async {
    await gated((rest) => rest.discovery.getRecommendationsForYou(limit: 20), (
      value,
    ) {
      for (final artist in value.artists) {
        expect(artist.id, isNotEmpty);
        expect(artist.name, isNotEmpty);
      }
    });
  });

  test('popular artists', () async {
    await gated((rest) => rest.discovery.listPopularArtists(limit: 20), (
      value,
    ) {
      for (final artist in value.artists) {
        expect(artist.name, isNotEmpty);
      }
    });
  });

  test('current discovery playlist', () async {
    await gated((rest) => rest.discovery.getCurrentDiscover(), (value) {
      expect(value.tracks, hasLength(value.totalCount));
      expect(value.weekEnd.isAfter(value.weekStart), isTrue);
      for (final track in value.tracks) {
        expect(track.playbackId, isNotEmpty);
      }
    });
  });
}
