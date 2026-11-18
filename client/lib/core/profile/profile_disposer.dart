// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';

/// A closer of a profile-scoped resource.
typedef ProfileCloser = Future<void> Function();

/// The asynchronous closers of one profile scope.
///
/// `ref.onDispose` is synchronous, so a resource that closes asynchronously
/// (a database, a socket, an engine) registers its close here as well.
/// `ProfileRuntime` awaits [closeAll] before it disposes the profile
/// container, and [closeAfterDispose] after it.
class ProfileDisposer {
  /// Creates an empty registry; failures are logged to the given logger.
  new(this._logger);

  final AppLogger _logger;
  final List<ProfileCloser> _closers = [];
  final List<ProfileCloser> _afterDispose = [];

  /// Adds [closer]; it runs once, in [closeAll].
  void register(ProfileCloser closer) => _closers.add(closer);

  /// Adds [closer] for a store whose close waits on its watchers, such as a
  /// drift database, which waits on every watch query's listeners. A
  /// listener that Riverpod paused (a screen that is not shown) only lets
  /// go when the profile container cancels it, so [closer] runs once, in
  /// [closeAfterDispose], after the container is disposed.
  void registerAfterDispose(ProfileCloser closer) => _afterDispose.add(closer);

  /// Runs every closer added with [register] once, in reverse registration
  /// order, each after the previous one completed. A closer that fails is
  /// logged and the rest still run.
  Future<void> closeAll() => _run(_closers);

  /// Runs every closer added with [registerAfterDispose] once, like
  /// [closeAll].
  Future<void> closeAfterDispose() => _run(_afterDispose);

  Future<void> _run(List<ProfileCloser> registered) async {
    final closers = registered.reversed.toList();
    registered.clear();
    for (final closer in closers) {
      try {
        await closer();
      } on Object catch (error, stackTrace) {
        _logger.warning('A profile closer failed', const {}, error, stackTrace);
      }
    }
  }
}

/// The [ProfileDisposer] of the profile scope.
final Provider<ProfileDisposer> profileDisposerProvider =
    Provider<ProfileDisposer>((ref) {
      ref.watch(profileContextProvider);
      return ProfileDisposer(ref.read(appLoggerProvider('Profile')));
    }, dependencies: [profileContextProvider]);
