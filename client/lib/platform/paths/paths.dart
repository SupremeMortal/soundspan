// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The paths seam: where the app's files live (doc 05, Files on Disk).
///
/// `resolveAppPaths()` returns the native implementation, rooted in the
/// platform's application support and cache directories, or on web an
/// implementation without files whose getters throw.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:path/path.dart' as p;

export 'paths_web.dart'
    if (dart.library.io) 'paths_io.dart'
    show resolveAppPaths;

/// Where the app keeps its files.
abstract interface class AppPaths {
  /// The application support directory: `app.db`, logs and the durable
  /// profile trees.
  String get appSupport;

  /// The application cache directory, which the OS may purge.
  String get appCache;

  /// The directory of the rolling log files: `<appSupport>/logs`.
  String get logs;

  /// The directories and database files of profile [profileId].
  ///
  /// Throws an [ArgumentError] when [profileId] is not a single, plain path
  /// segment.
  ProfilePaths profile(String profileId);

  /// Deletes both directory trees of profile [profileId]; trees that do not
  /// exist are not an error.
  Future<void> deleteProfileTree(String profileId);
}

/// The files of one profile.
///
/// ```text
/// <appSupport>/profiles/<id>/     supportRoot
///   state.db  media/  art/
/// <appCache>/profiles/<id>/       cacheRoot
///   cache.db  images/
/// ```
@immutable
final class ProfilePaths {
  /// Derives the paths of profile [profileId] from the two roots.
  ///
  /// Throws an [ArgumentError] when [profileId] is empty, `.`, `..`, or
  /// contains a path separator, so two profiles never share a directory.
  factory derive({
    required String appSupport,
    required String appCache,
    required String profileId,
  }) {
    if (profileId.isEmpty ||
        profileId == '.' ||
        profileId == '..' ||
        profileId.contains('/') ||
        profileId.contains(r'\')) {
      throw ArgumentError.value(profileId, 'profileId', 'not a path segment');
    }
    return ProfilePaths._(
      profileId: profileId,
      supportRoot: p.join(appSupport, 'profiles', profileId),
      cacheRoot: p.join(appCache, 'profiles', profileId),
    );
  }

  const new _({
    required this.profileId,
    required this.supportRoot,
    required this.cacheRoot,
  });

  /// The profile these paths belong to.
  final String profileId;

  /// `<appSupport>/profiles/<id>`: durable files of the profile.
  final String supportRoot;

  /// `<appCache>/profiles/<id>`: disposable files of the profile.
  final String cacheRoot;

  /// `state.db`: the profile's durable state database.
  String get stateDb => p.join(supportRoot, 'state.db');

  /// `media/`: downloaded tracks and episodes.
  String get media => p.join(supportRoot, 'media');

  /// `art/`: artwork pinned for downloaded items and OS media controls.
  String get art => p.join(supportRoot, 'art');

  /// `cache.db`: the profile's cache database.
  String get cacheDb => p.join(cacheRoot, 'cache.db');

  /// `images/`: the image cache store.
  String get images => p.join(cacheRoot, 'images');

  @override
  bool operator ==(Object other) =>
      other is ProfilePaths &&
      other.profileId == profileId &&
      other.supportRoot == supportRoot &&
      other.cacheRoot == cacheRoot;

  @override
  int get hashCode => Object.hash(profileId, supportRoot, cacheRoot);

  @override
  String toString() => 'ProfilePaths($supportRoot, $cacheRoot)';
}

/// The log directory under [appSupport].
String logsDirectory(String appSupport) => p.join(appSupport, 'logs');
