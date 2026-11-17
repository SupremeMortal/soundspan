// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/platform/release_feed/release_feed.dart';

/// A [ReleaseFeed] that answers [releases], or throws [error] when set.
class FakeReleaseFeed implements ReleaseFeed {
  /// Creates a feed that answers [releases].
  new({this.releases = const []});

  /// What [fetch] answers.
  List<ReleaseInfo> releases;

  /// When set, [fetch] throws it.
  Exception? error;

  /// When set, [fetch] completes with this completer's future instead.
  Completer<List<ReleaseInfo>>? pending;

  /// The repositories [fetch] was called with, in order.
  final List<String> requests = [];

  @override
  Future<List<ReleaseInfo>> fetch(String repository) async {
    requests.add(repository);
    final error = this.error;
    if (error != null) throw error;
    return await (pending?.future ?? Future.value(releases));
  }
}

/// A published release of [repository] tagged [tag].
ReleaseInfo release(
  String tag, {
  String repository = 'owner/soundspan',
  bool draft = false,
}) => ReleaseInfo(
  tag: tag,
  htmlUrl: Uri.parse('https://github.com/$repository/releases/tag/$tag'),
  draft: draft,
);
