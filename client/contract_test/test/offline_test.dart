// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Offline" of doc 03's endpoint inventory: every operation
/// of that table through the generated client, each `downloadUrl` fetched
/// through a plain HTTP client with `StreamUrls`, the server's cache limit,
/// and revocation through the admin switch, against the seeded server with
/// response validation on.
@Tags(['contract'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

/// An album of the fixture library, and its artist.
const _album = 'Stone Garden';
const _albumArtist = 'Contract Basalt';

/// The artist of the seeded playlist's tracks.
const _playlistArtist = 'Contract Aurora';

/// A random version-4 UUID: the server requires a UUID `deviceId`.
String _deviceId() {
  final random = Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) random.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}

/// GETs [uri] with [headers] through a plain HTTP client and drains the
/// body; returns the status and the `ETag`.
Future<({int status, String? etag})> _get(
  Uri uri,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    await response.drain<void>();
    return (
      status: response.statusCode,
      etag: response.headers.value(HttpHeaders.etagHeader),
    );
  } finally {
    client.close(force: true);
  }
}

/// Sets the admin switch `offlineDownloadsEnabled` with [token], the
/// admin's access token. `POST /system-settings` is not part of the client
/// surface, so it is sent through a plain HTTP client.
Future<void> _setOfflineDownloads(
  Uri baseUrl,
  String token, {
  required bool enabled,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      baseUrl.resolve('/api/system-settings'),
    );
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({'offlineDownloadsEnabled': enabled}));
    final response = await request.close();
    await response.drain<void>();
    expect(response.statusCode, 200, reason: 'POST /system-settings');
  } finally {
    client.close(force: true);
  }
}

void main() {
  late ContractCredentials credentials;
  late JwtCredentials session;
  late SoundspanApi api;
  late StreamUrls urls;
  late String deviceId;

  setUp(() async {
    credentials = ContractCredentials.load();
    final login = await logIn(credentials, credentials.listener);
    session = JwtCredentials(
      accessToken: login.token,
      refreshToken: login.refreshToken,
    );
    api = credentialedApi(credentials, InMemoryCredentialProvider(session));
    urls = StreamUrls(credentials.baseUrl);
    deviceId = _deviceId();
  });

  Future<String> albumId() async {
    final page = await api.send((rest) => rest.library2.listAlbums(limit: 100));
    return page.albums.singleWhere((album) => album.title == _album).id;
  }

  Future<OfflineItemsResponse> request(String kind, String id) => api.send(
    (rest) => rest.offline.requestOfflineItems(
      body: RequestOfflineItemsRequest(
        deviceId: deviceId,
        id: id,
        kind: RequestOfflineItemsRequestKind.fromJson(kind),
      ),
    ),
  );

  /// When [artist] was last played, or null.
  Future<DateTime?> lastPlayed(String artist) async {
    final recent = await api.send(
      (rest) => rest.library2.listRecentlyListened(limit: 100),
    );
    return recent.items
        .where((item) => item.name == artist)
        .firstOrNull
        ?.lastPlayedAt;
  }

  for (final (kind, artist) in [
    ('album', _albumArtist),
    ('playlist', _playlistArtist),
  ]) {
    test('a $kind resolves to downloadable items whose downloadUrl answers '
        '200 with a strong ETag and records no play (P7)', () async {
      final id = kind == 'album' ? await albumId() : credentials.playlistId;
      final started = DateTime.now().toUtc();

      final response = await request(kind, id);

      expect(response.items, isNotEmpty);
      for (final item in response.items) {
        expect(item.downloadable, isTrue, reason: item.playbackId);
        final url = urls.resolve(item.downloadUrl!);
        expect(url.queryParameters['report'], '0');
        final answer = await _get(url, urls.authHeaders(session));
        expect(answer.status, 200, reason: item.playbackId);
        expect(answer.etag, isNotNull);
        expect(answer.etag, isNot(startsWith('W/')));
      }
      // Other contract tests record plays of this artist dated in the past;
      // a download that counted as a play would be dated after `started`.
      final last = await lastPlayed(artist);
      if (last != null) expect(last.isAfter(started), isFalse);
    });
  }

  test('complete, then list shows the item and stats counts it; delete '
      'removes it', () async {
    final item = (await request('album', await albumId())).items.first;
    final quality = item.quality!.toJson();

    final completed = await api.send(
      (rest) => rest.offline.completeOfflineItem(
        body: CompleteOfflineItemRequest(
          deviceId: deviceId,
          playbackId: item.playbackId,
          quality: CompleteOfflineItemRequestQuality.fromJson(quality),
          sizeBytes: 4096,
        ),
      ),
    );
    expect(completed.playbackId, item.playbackId);

    final listed = await api.send(
      (rest) => rest.offline.listOfflineItems(deviceId: deviceId),
    );
    expect(listed.items, hasLength(1));
    expect(listed.items.single.playbackId, item.playbackId);
    expect(listed.items.single.revoked, isFalse);
    expect(listed.items.single.sizeBytes, 4096);

    final stats = await api.send(
      (rest) => rest.offline.getOfflineStats(deviceId: deviceId),
    );
    expect(stats.device?.deviceId, deviceId);
    expect(stats.device?.trackCount, 1);
    expect(stats.device?.usedMb, greaterThan(0));

    final deleted = await api.send(
      (rest) => rest.offline.deleteOfflineItems(
        body: DeleteOfflineItemsRequest(
          deviceId: deviceId,
          playbackIds: [item.playbackId],
        ),
      ),
    );
    expect(deleted.deletedCount, 1);
    final after = await api.send(
      (rest) => rest.offline.listOfflineItems(deviceId: deviceId),
    );
    expect(after.items, isEmpty);
  });

  test('a cache limit below the estimate answers CacheLimitExceeded with the '
      'three byte values', () async {
    final id = await albumId();
    final before = await api.send((rest) => rest.session.getSettings());
    addTearDown(
      () => api.send(
        (rest) => rest.session.updateSettings(
          body: UpdateSettingsRequest(maxCacheSizeMb: before.maxCacheSizeMb),
        ),
      ),
    );
    await api.send(
      (rest) => rest.session.updateSettings(
        body: const UpdateSettingsRequest(maxCacheSizeMb: 0),
      ),
    );

    await expectLater(
      request('album', id),
      throwsA(
        isA<CacheLimitExceeded>()
            .having((e) => e.limitBytes, 'limitBytes', 0)
            .having((e) => e.usedBytes, 'usedBytes', greaterThanOrEqualTo(0))
            .having((e) => e.estimatedBytes, 'estimatedBytes', greaterThan(0)),
      ),
    );
  });

  test('the admin switch revokes a completed item and refuses new ones; '
      'delete removes it', () async {
    final admin = await logIn(credentials, credentials.admin);
    final id = await albumId();
    final item = (await request('album', id)).items.first;
    await api.send(
      (rest) => rest.offline.completeOfflineItem(
        body: CompleteOfflineItemRequest(
          deviceId: deviceId,
          playbackId: item.playbackId,
          quality: CompleteOfflineItemRequestQuality.fromJson(
            item.quality!.toJson(),
          ),
          sizeBytes: 4096,
        ),
      ),
    );

    addTearDown(
      () =>
          _setOfflineDownloads(credentials.baseUrl, admin.token, enabled: true),
    );
    await _setOfflineDownloads(
      credentials.baseUrl,
      admin.token,
      enabled: false,
    );

    final listed = await api.send(
      (rest) => rest.offline.listOfflineItems(deviceId: deviceId),
    );
    expect(listed.items.single.playbackId, item.playbackId);
    expect(listed.items.single.revoked, isTrue);

    // The server answers 200 with every item refused, rather than 409
    // SOURCE_DOWNLOADS_DISABLED for the request as a whole.
    final refused = await request('album', id);
    expect(refused.items, isNotEmpty);
    for (final refusedItem in refused.items) {
      expect(refusedItem.downloadable, isFalse);
      expect(refusedItem.reason, OfflineItemReason.sourceDownloadsDisabled);
    }

    final deleted = await api.send(
      (rest) => rest.offline.deleteOfflineItems(
        body: DeleteOfflineItemsRequest(
          deviceId: deviceId,
          playbackIds: [item.playbackId],
        ),
      ),
    );
    expect(deleted.deletedCount, 1);
  });
}
