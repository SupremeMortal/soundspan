// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/profile/settings/settings_repository.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockSessionClient extends Mock implements api.SessionClient;

api.UserSettings _wire({
  String loudnessMode = 'album',
  String playbackQuality = 'high',
  int maxCacheSizeMb = 2048,
}) => api.UserSettings.fromJson({
  'userId': 'u-1',
  'displayName': null,
  'playbackQuality': playbackQuality,
  'loudnessMode': loudnessMode,
  'maxCacheSizeMb': maxCacheSizeMb,
  'offlineEnabled': false,
  'shareListeningStatus': true,
  'shareOnlinePresence': true,
  'showTidalExplore': false,
  'showYtMusicExplore': false,
  'tidalStreamingQuality': 'HIGH',
  'wifiOnly': false,
  'ytMusicQuality': 'HIGH',
});

void main() {
  late _MockSessionClient client;
  late SettingsRepository repository;

  setUpAll(() => registerFallbackValue(const api.UpdateSettingsRequest()));

  setUp(() {
    client = _MockSessionClient();
    repository = SettingsRepository(client);
  });

  test('fetch maps playbackQuality, loudnessMode and maxCacheSizeMb', () async {
    when(() => client.getSettings()).thenAnswer((_) async => _wire());

    final settings = await repository.fetch();

    verify(() => client.getSettings()).called(1);
    expect(
      settings,
      const UserSettings(
        playbackQuality: 'high',
        loudnessMode: LoudnessMode.album,
        maxCacheSizeMb: 2048,
      ),
    );
  });

  test('every known loudnessMode maps to its domain value', () async {
    for (final mode in ['off', 'track', 'album', 'auto']) {
      when(() => client.getSettings())
          .thenAnswer((_) async => _wire(loudnessMode: mode));

      final settings = await repository.fetch();

      expect(settings.loudnessMode.name, mode);
    }
  });

  test('an unknown loudnessMode decodes to unknown', () async {
    when(() => client.getSettings())
        .thenAnswer((_) async => _wire(loudnessMode: 'dynamic'));

    final settings = await repository.fetch();

    expect(settings.loudnessMode, LoudnessMode.unknown);
  });

  test('update sends only loudnessMode when only it is given', () async {
    when(() => client.updateSettings(body: any(named: 'body')))
        .thenAnswer((_) async => _wire(loudnessMode: 'track'));

    final settings = await repository.update(loudnessMode: LoudnessMode.track);

    final body =
        verify(() => client.updateSettings(body: captureAny(named: 'body')))
                .captured
                .single
            as api.UpdateSettingsRequest;
    expect(body.toJson(), {'loudnessMode': 'track'});
    expect(settings.loudnessMode, LoudnessMode.track);
  });

  test('update sends only playbackQuality when only it is given', () async {
    when(() => client.updateSettings(body: any(named: 'body')))
        .thenAnswer((_) async => _wire(playbackQuality: 'low'));

    final settings = await repository.update(playbackQuality: 'low');

    final body =
        verify(() => client.updateSettings(body: captureAny(named: 'body')))
                .captured
                .single
            as api.UpdateSettingsRequest;
    expect(body.toJson(), {'playbackQuality': 'low'});
    expect(settings.playbackQuality, 'low');
  });

  test('update sends both fields when both are given', () async {
    when(() => client.updateSettings(body: any(named: 'body')))
        .thenAnswer((_) async => _wire());

    await repository.update(
      playbackQuality: 'original',
      loudnessMode: LoudnessMode.off,
    );

    final body =
        verify(() => client.updateSettings(body: captureAny(named: 'body')))
                .captured
                .single
            as api.UpdateSettingsRequest;
    expect(body.toJson(), {
      'playbackQuality': 'original',
      'loudnessMode': 'off',
    });
  });

  test('update never sends an unknown loudnessMode back', () async {
    when(() => client.updateSettings(body: any(named: 'body')))
        .thenAnswer((_) async => _wire());

    await repository.update(
      playbackQuality: 'medium',
      loudnessMode: LoudnessMode.unknown,
    );

    final body =
        verify(() => client.updateSettings(body: captureAny(named: 'body')))
                .captured
                .single
            as api.UpdateSettingsRequest;
    expect(body.toJson(), {'playbackQuality': 'medium'});
  });

  test('an ApiException propagates unchanged', () async {
    const failure = api.Unauthenticated(status: 401);
    when(() => client.getSettings()).thenThrow(failure);

    await expectLater(repository.fetch(), throwsA(same(failure)));
  });
}
