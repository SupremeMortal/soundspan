// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// How a profile's credential was obtained.
enum AuthKind {
  /// Username and password, optionally with a second factor: a JWT session.
  password,

  /// A device-link code: an API key.
  deviceLink,

  /// A pasted API key.
  apiKey,
}

/// Whether a profile can talk to its server.
enum ProfileState {
  /// Signed in.
  active,

  /// Signed out: the credential is gone, the profile and its data are kept.
  signedOut,
}
