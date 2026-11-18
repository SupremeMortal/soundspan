// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/paths/paths.dart';

/// Resolves the web [AppPaths]: there are no files on web.
Future<AppPaths> resolveAppPaths() async => const WebAppPaths();

/// The web [AppPaths]. Every path throws [UnsupportedError];
/// [deleteProfileTree] does nothing.
final class WebAppPaths implements AppPaths {
  /// Creates the web paths.
  const new();

  static Never _unsupported() =>
      throw UnsupportedError('There are no files on web');

  @override
  String get appSupport => _unsupported();

  @override
  String get appCache => _unsupported();

  @override
  String get logs => _unsupported();

  @override
  ProfilePaths profile(String profileId) => _unsupported();

  @override
  Future<void> deleteProfileTree(String profileId) async {}
}
