// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Build-time configuration of the client.
///
/// [channel] comes from `--dart-define-from-file` (`config/dev.json` or
/// `config/release.json`), [releaseRepository] from the release workflow's
/// `--dart-define`. The server versions are source constants because
/// they describe what the code was tested against.
abstract final class BuildConfig {
  /// The release channel: `dev` for local runs, `stable` for releases.
  static const String channel = String.fromEnvironment(
    'CHANNEL',
    defaultValue: 'dev',
  );

  /// The GitHub repository (`owner/name`) whose client releases the
  /// desktop update notice checks; empty in local and test builds, which
  /// never check.
  static const String releaseRepository = String.fromEnvironment(
    'RELEASE_REPOSITORY',
  );

  /// The oldest server version this client supports.
  static const String minServer = '2.7.0';

  /// The newest server version this client was tested against.
  static const String maxTestedServer = '2.7.0';
}
