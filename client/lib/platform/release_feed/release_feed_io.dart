// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:soundspan/platform/release_feed/release_feed.dart';

/// The [ReleaseFeed] of a native app: the GitHub REST API, without
/// credentials.
ReleaseFeed createReleaseFeed() => const GitHubReleaseFeed();

/// Reads `GET https://api.github.com/repos/<repository>/releases` with
/// `dart:io`, giving up after [timeout].
class GitHubReleaseFeed implements ReleaseFeed {
  /// Creates the feed.
  const new();

  /// How long a request may take, connection included.
  static const Duration timeout = Duration(seconds: 10);

  @override
  Future<List<ReleaseInfo>> fetch(String repository) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'soundspan-client';
    try {
      return await _fetch(client, repository).timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<List<ReleaseInfo>> _fetch(HttpClient client, String repository) async {
    final url = Uri.https('api.github.com', '/repos/$repository/releases', {
      'per_page': '30',
    });
    final request = await client.getUrl(url);
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub answered ${response.statusCode}', uri: url);
    }
    return parseReleases(jsonDecode(body));
  }
}
