// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/platform/paths/paths.dart';

/// The active profile, as seen by everything in its profile scope (doc 02,
/// Riverpod Structure). Nothing in it is mutable.
@immutable
final class ProfileContext {
  /// Creates the context of [profile] with its directories [paths].
  const new({required this.profile, this.paths});

  /// The profile record as it was when the scope was created.
  final Profile profile;

  /// The profile's directories; null on web, where there are no files.
  final ProfilePaths? paths;

  @override
  bool operator ==(Object other) =>
      other is ProfileContext &&
      other.profile == profile &&
      other.paths == paths;

  @override
  int get hashCode => Object.hash(profile, paths);

  @override
  String toString() => 'ProfileContext(${profile.id})';
}

/// The [ProfileContext] of the profile scope.
///
/// `ProfileRuntime` overrides it in each profile container; read anywhere
/// else it throws. Every profile-scoped provider lists it, directly or
/// through another scoped provider, in its `dependencies`.
final Provider<ProfileContext> profileContextProvider =
    Provider<ProfileContext>(
      (ref) => throw StateError(
        'profileContextProvider was read outside a profile scope',
      ),
      dependencies: const [],
    );
