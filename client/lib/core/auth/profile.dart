// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/core/storage/app/profile_enums.dart';

export 'package:soundspan/core/storage/app/profile_enums.dart';

part 'profile.freezed.dart';

/// A server profile: one user signed in to one server (doc 04, Profile
/// Record). Secrets are never part of it.
@freezed
abstract class Profile with _$Profile {
  /// Creates a profile record.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Profile({
    /// The profile id, a UUID v4; names its directories and secret keys.
    required String id,

    /// The normalized server base URL, without a trailing slash; may
    /// include a path prefix.
    required Uri baseUrl,

    /// The name the user gave the server; defaults to the host.
    required String displayName,

    /// The server's id of the signed-in user.
    required String userId,

    /// The signed-in user's username.
    required String username,

    /// The signed-in user's role on the server.
    required String role,

    /// How the credential was obtained.
    required AuthKind authKind,

    /// The playback device id, a UUID v4. Not a secret.
    required String deviceId,

    /// When the credential was issued.
    required DateTime credentialCreatedAt,

    /// Whether the profile is signed in.
    required ProfileState state,

    /// When the profile was last the active one.
    required DateTime lastUsedAt,

    /// The signed-in user's display name, if they have one.
    String? userDisplayName,

    /// When the credential expires, if it does.
    DateTime? credentialExpiresAt,

    /// The server version seen at the last capability refresh.
    String? serverVersion,

    /// The server's feature flags from the last capability refresh.
    Map<String, Object?>? features,

    /// When [features] was fetched.
    DateTime? featuresFetchedAt,
  }) = _Profile;
}
