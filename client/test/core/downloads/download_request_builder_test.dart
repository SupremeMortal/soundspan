// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_request_builder.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Holds the profile's credential and records every `ensureFresh` call.
class _Session {
  new(this.current);

  Credentials? current;
  Credentials fresh = const JwtCredentials(
    accessToken: 'fresh',
    refreshToken: 'r',
  );
  final List<Duration> asked = [];

  Future<Credentials> ensureFresh({required Duration minRemaining}) async {
    asked.add(minRemaining);
    return fresh;
  }
}

DownloadItem _item({
  String itemKey = 't:pb-1',
  String? downloadUrl = '/api/offline/download/pb-1?quality=high&sig=a%2Bb',
}) => DownloadItem(
  itemKey: itemKey,
  mediaType: MediaType.track,
  metaJson: '{}',
  status: DownloadStatus.queued,
  downloadUrl: downloadUrl,
  receivedBytes: 0,
  attempts: 0,
  serverConfirmed: false,
  requestedAt: DateTime.utc(2026),
);

void main() {
  final paths = DownloadPaths(
    ProfilePaths.derive(
      appSupport: '/support',
      appCache: '/cache',
      profileId: 'prof-1',
    ),
  );
  final urls = StreamUrls(Uri.parse('https://music.example.com/proxy/sub'));

  DownloadRequestBuilder builder(_Session session) => DownloadRequestBuilder(
    paths: paths,
    urls: urls,
    currentCredentials: () => session.current,
    ensureFresh: session.ensureFresh,
  );

  test('a JWT session is refreshed for 12 hours before the request is '
      'built, and its fresh token authenticates the request', () async {
    final session = _Session(
      const JwtCredentials(accessToken: 'stale', refreshToken: 'r'),
    );

    final request = await builder(session)
        .build(_item(), wifiOnly: false, userInitiated: true);

    expect(session.asked, [const Duration(hours: 12)]);
    expect(request.headers, {'Authorization': 'Bearer fresh'});
  });

  test('an API-key session is not refreshed and sends X-API-Key', () async {
    final session = _Session(const ApiKeyCredentials(apiKey: 'key-1'));

    final request = await builder(session)
        .build(_item(), wifiOnly: false, userInitiated: false);

    expect(session.asked, isEmpty);
    expect(request.headers, {'X-API-Key': 'key-1'});
  });

  test('the URL keeps the reverse-proxy sub-path and the server query string '
      'unchanged', () async {
    final session = _Session(const ApiKeyCredentials(apiKey: 'k'));

    final request = await builder(session)
        .build(_item(), wifiOnly: false, userInitiated: false);

    expect(
      request.url.toString(),
      'https://music.example.com/proxy/sub/api/offline/download/pb-1'
      '?quality=high&sig=a%2Bb',
    );
  });

  test('task id, directory and .part file name follow itemKeyHash', () async {
    final session = _Session(const ApiKeyCredentials(apiKey: 'k'));
    final hash = itemKeyHash(const TrackItemKey('pb-1'));

    final request = await builder(session)
        .build(_item(), wifiOnly: true, userInitiated: true);

    expect(request.taskId, hash);
    expect(request.profileId, 'prof-1');
    expect(request.relativeDirectory, p.join('media', hash.substring(0, 2)));
    expect(request.filename, '$hash.part');
    expect(
      p.join(request.relativeDirectory, request.filename),
      paths.relativePartFile(hash),
    );
    expect(request.group, 'p:prof-1');
    expect(request.metaData, 't:pb-1');
    expect(request.requiresWifi, isTrue);
    expect(request.highPriority, isTrue);
  });

  test('an episode item is keyed by its own hash', () async {
    final session = _Session(const ApiKeyCredentials(apiKey: 'k'));
    const key = EpisodeItemKey(podcastId: 'pod', episodeId: 'ep');

    final request = await builder(session).build(
      _item(
        itemKey: key.encode(),
        downloadUrl: '/api/podcasts/pod/episodes/ep/stream',
      ),
      wifiOnly: false,
      userInitiated: false,
    );

    expect(request.taskId, itemKeyHash(key));
    expect(request.metaData, 'e:pod:ep');
    expect(request.requiresWifi, isFalse);
    expect(request.highPriority, isFalse);
  });

  test('an item without a download URL is refused', () async {
    final session = _Session(const ApiKeyCredentials(apiKey: 'k'));

    await expectLater(
      builder(
        session,
      ).build(_item(downloadUrl: null), wifiOnly: false, userInitiated: false),
      throwsStateError,
    );
  });
}
