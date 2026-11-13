// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Build-time configuration of the client.
///
/// [channel] comes from `--dart-define-from-file` (`config/dev.json` or
/// `config/release.json`). The server versions are source constants because
/// they describe what the code was tested against.
abstract final class BuildConfig {
  /// The release channel: `dev` for local runs, `stable` for releases.
  static const String channel = String.fromEnvironment(
    'CHANNEL',
    defaultValue: 'dev',
  );

  /// The oldest server version this client supports.
  static const String minServer = '2.6.1';

  /// The newest server version this client was tested against.
  static const String maxTestedServer = '2.6.1';
}
