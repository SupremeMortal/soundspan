// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The `SecretStore` keys of a profile, all namespaced by its id (doc 04,
/// Secret Storage).
abstract final class SecretKeys {
  /// `p/<profileId>/refresh`: the refresh JWT.
  static String refresh(String profileId) => 'p/$profileId/refresh';

  /// `p/<profileId>/access`: the access JWT.
  static String access(String profileId) => 'p/$profileId/access';

  /// `p/<profileId>/apikey`: the API key.
  static String apiKey(String profileId) => 'p/$profileId/apikey';

  /// The three keys of [profileId].
  static List<String> all(String profileId) => [
    refresh(profileId),
    access(profileId),
    apiKey(profileId),
  ];
}
