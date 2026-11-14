// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web address outside the app, in the system browser.
abstract interface class UrlOpener {
  /// Opens [url]; completes with whether a browser accepted it.
  Future<bool> open(Uri url);
}

/// The [UrlOpener] of the running app, through `url_launcher`.
class LauncherUrlOpener implements UrlOpener {
  /// Creates the opener.
  const new();

  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

/// The app's [UrlOpener]; tests override it.
final Provider<UrlOpener> urlOpenerProvider = Provider<UrlOpener>(
  (ref) => const LauncherUrlOpener(),
);
