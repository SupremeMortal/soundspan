// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:soundspan/platform/paths/paths.dart';

/// Resolves the native [AppPaths] from `path_provider`.
Future<AppPaths> resolveAppPaths() async => IoAppPaths(
  appSupport: (await getApplicationSupportDirectory()).path,
  appCache: (await getApplicationCacheDirectory()).path,
);

/// The native [AppPaths], rooted in two directories.
final class IoAppPaths implements AppPaths {
  /// Creates paths rooted in [appSupport] and [appCache].
  const new({required this.appSupport, required this.appCache});

  @override
  final String appSupport;

  @override
  final String appCache;

  @override
  String get logs => logsDirectory(appSupport);

  @override
  ProfilePaths profile(String profileId) => ProfilePaths.derive(
    appSupport: appSupport,
    appCache: appCache,
    profileId: profileId,
  );

  @override
  Future<void> deleteProfileTree(String profileId) async {
    final paths = profile(profileId);
    for (final root in [paths.supportRoot, paths.cacheRoot]) {
      final dir = Directory(root);
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
  }
}
