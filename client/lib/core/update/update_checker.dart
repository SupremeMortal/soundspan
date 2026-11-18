// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:soundspan/app/build_config.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/release_feed/release_feed.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/providers/package_info.dart';

final AppLogger _log = AppLogger.scope('Update');

/// The tag prefix of client releases, which the server's tags lack.
const String clientTagPrefix = 'client-v';

/// The shortest time between two checks that are not forced.
const Duration updateCheckInterval = Duration(hours: 24);

/// What the last check found.
@immutable
sealed class UpdateState {
  const new();
}

/// No newer client release is known.
final class UpToDate extends UpdateState {
  /// Creates the state.
  const new();

  @override
  bool operator ==(Object other) => other is UpToDate;

  @override
  int get hashCode => (UpToDate).hashCode;

  @override
  String toString() => 'UpToDate()';
}

/// Client release [version] is newer than the running one; its page is
/// [htmlUrl].
final class UpdateAvailable extends UpdateState {
  /// Creates the state.
  const new(this.version, this.htmlUrl);

  /// The newer version, such as `0.2.0` or `0.2.0-rc.1`.
  final String version;

  /// The release page on GitHub.
  final Uri htmlUrl;

  @override
  bool operator ==(Object other) =>
      other is UpdateAvailable &&
      other.version == version &&
      other.htmlUrl == htmlUrl;

  @override
  int get hashCode => Object.hash(version, htmlUrl);

  @override
  String toString() => 'UpdateAvailable($version, $htmlUrl)';
}

/// The repository whose client releases are checked,
/// [BuildConfig.releaseRepository] unless overridden.
final Provider<String> releaseRepositoryProvider = Provider<String>(
  (ref) => BuildConfig.releaseRepository,
);

/// Whether this build checks for updates at all: a desktop platform, a
/// release repository and the `stable` channel. The user's setting comes
/// on top ([updateCheckSettingProvider]).
final Provider<bool> updateCheckSupportedProvider = Provider<bool>(
  (ref) =>
      ref.watch(platformCapabilitiesProvider).hasUpdateNotice &&
      ref.watch(releaseRepositoryProvider).isNotEmpty &&
      ref.watch(buildChannelProvider) == 'stable',
);

/// The stored "Check for new versions"; on when not stored.
final StreamProvider<bool> updateCheckSettingProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(appSettingsProvider)
      .watch(AppSettingKeys.updateCheck)
      .map((value) => value ?? true),
);

/// The version whose banner the user dismissed, if any.
final StreamProvider<String?> dismissedUpdateVersionProvider =
    StreamProvider<String?>(
      (ref) => ref
          .watch(appSettingsProvider)
          .watch(AppSettingKeys.updateDismissedVersion),
    );

/// The update the shell banner shows: the available one unless its version,
/// or a higher one, was dismissed. Null while the dismissal is being read.
final Provider<UpdateAvailable?> updateNoticeProvider =
    Provider<UpdateAvailable?>((ref) {
      final state = ref.watch(updateCheckerProvider);
      if (state is! UpdateAvailable) return null;
      final dismissed = ref.watch(dismissedUpdateVersionProvider);
      if (!dismissed.hasValue) return null;
      final dismissedVersion = _parse(dismissed.value);
      if (dismissedVersion == null) return state;
      final version = _parse(state.version);
      return version != null && version > dismissedVersion ? state : null;
    });

/// Checks GitHub for a client release newer than the running one (doc 10,
/// Update Notice); a root provider.
///
/// [check] runs after the shell's first frame and at most once per
/// [updateCheckInterval], unless forced by "Check now". A failure is logged
/// at `fine` and keeps the previous state.
class UpdateChecker extends Notifier<UpdateState> {
  bool _running = false;

  @override
  UpdateState build() => const UpToDate();

  /// Asks the [ReleaseFeed] for releases when the check is enabled and
  /// [updateCheckInterval] passed since the last one, or at once when
  /// [force] is set. No request is made while the check is disabled.
  Future<void> check({bool force = false}) async {
    if (_running || !ref.read(updateCheckSupportedProvider)) return;
    final settings = ref.read(appSettingsProvider);
    _running = true;
    try {
      if (await settings.read(AppSettingKeys.updateCheck) == false) return;
      final now = ref.read(clockProvider).now();
      final last = await settings.read(AppSettingKeys.updateLastCheckedAt);
      if (!force &&
          last != null &&
          now.difference(last) < updateCheckInterval) {
        return;
      }
      final repository = ref.read(releaseRepositoryProvider);
      try {
        final running = _parse(
          (await ref.read(packageInfoProvider.future)).version,
        );
        if (running == null) throw const FormatException('Running version');
        final releases = await ref.read(releaseFeedProvider).fetch(repository);
        final found = _evaluate(releases, running, repository);
        if (ref.mounted) state = found;
      } on Object catch (error) {
        _log.fine('Update check failed', {'error': error.toString()});
      }
      await settings.write(AppSettingKeys.updateLastCheckedAt, now);
    } finally {
      _running = false;
    }
  }

  /// Hides the banner for [version] and every lower one.
  Future<void> dismiss(String version) => ref
      .read(appSettingsProvider)
      .write(AppSettingKeys.updateDismissedVersion, version);
}

/// The [UpdateChecker].
final NotifierProvider<UpdateChecker, UpdateState> updateCheckerProvider =
    NotifierProvider<UpdateChecker, UpdateState>(UpdateChecker.new);

UpdateState _evaluate(
  List<ReleaseInfo> releases,
  Version running,
  String repository,
) {
  ReleaseInfo? best;
  Version? bestVersion;
  for (final release in releases) {
    if (release.draft || !release.tag.startsWith(clientTagPrefix)) continue;
    final version = _parse(release.tag.substring(clientTagPrefix.length));
    if (version == null) continue;
    if (bestVersion == null || version > bestVersion) {
      best = release;
      bestVersion = version;
    }
  }
  if (best == null || bestVersion == null || bestVersion <= running) {
    return const UpToDate();
  }
  final url = best.htmlUrl;
  final onReleasePage =
      url.scheme == 'https' &&
      url.host == 'github.com' &&
      url.path.startsWith('/$repository/releases/');
  return onReleasePage
      ? UpdateAvailable(bestVersion.toString(), url)
      : const UpToDate();
}

/// [text] as a semantic version without build metadata, or null.
Version? _parse(String? text) {
  if (text == null) return null;
  try {
    final version = Version.parse(text);
    return Version(
      version.major,
      version.minor,
      version.patch,
      pre: version.isPreRelease ? version.preRelease.join('.') : null,
    );
  } on FormatException {
    return null;
  }
}
