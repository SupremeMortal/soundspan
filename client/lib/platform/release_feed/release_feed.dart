// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The release-feed seam: the client's releases on GitHub, for the desktop
/// update notice (doc 10, Update Notice).
///
/// `createReleaseFeed()` asks the GitHub API with `dart:io` on native
/// targets; on web it answers no releases. This is the only request the
/// client makes to a host other than the user's server, so it does not go
/// through `soundspan_api`.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/release_feed/release_feed_web.dart'
    if (dart.library.io) 'package:soundspan/platform/release_feed/release_feed_io.dart';

export 'release_feed_web.dart'
    if (dart.library.io) 'release_feed_io.dart'
    show createReleaseFeed;

/// One release of a repository.
@immutable
final class ReleaseInfo {
  /// Creates the release tagged [tag], published at [htmlUrl].
  const new({required this.tag, required this.htmlUrl, required this.draft});

  /// The release's tag, such as `client-v0.2.0`.
  final String tag;

  /// The release's page.
  final Uri htmlUrl;

  /// Whether the release is an unpublished draft.
  final bool draft;

  @override
  bool operator ==(Object other) =>
      other is ReleaseInfo &&
      other.tag == tag &&
      other.htmlUrl == htmlUrl &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(tag, htmlUrl, draft);

  @override
  String toString() => 'ReleaseInfo($tag, $htmlUrl, draft: $draft)';
}

/// The releases of a repository.
abstract interface class ReleaseFeed {
  /// The latest releases of [repository] (`owner/name`), newest first;
  /// throws when they cannot be read.
  Future<List<ReleaseInfo>> fetch(String repository);
}

/// The releases in a GitHub list-releases response [json]; entries without
/// a tag or page are left out.
///
/// Throws a [FormatException] when [json] is not a list.
List<ReleaseInfo> parseReleases(Object? json) {
  if (json is! List<Object?>) {
    throw const FormatException('The releases are not a list');
  }
  return [
    for (final entry in json)
      if (entry case {
        'tag_name': final String tag,
        'html_url': final String page,
      })
        if (Uri.tryParse(page) case final Uri url)
          ReleaseInfo(tag: tag, htmlUrl: url, draft: entry['draft'] == true),
  ];
}

/// The app's [ReleaseFeed]; tests override it.
final Provider<ReleaseFeed> releaseFeedProvider = Provider<ReleaseFeed>(
  (ref) => createReleaseFeed(),
);
