// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The deep-link seam (doc 02, Platform Seams; doc 10, Deep Links Summary).
///
/// `createDeepLinks` returns, on Android, iOS and macOS, links from
/// `app_links`; on Windows and Linux, the `soundspan:` arguments of the
/// launch and of every later launch the single-instance runner forwards;
/// on web, the page's `?link=<code>&server=<url>` query as one
/// `soundspan://link` URI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/deep_links/deep_links_web.dart'
    if (dart.library.io) 'package:soundspan/platform/deep_links/deep_links_io.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

export 'deep_links_web.dart'
    if (dart.library.io) 'deep_links_io.dart'
    show createDeepLinks;

/// The scheme of the app's links.
const String deepLinkScheme = 'soundspan';

/// Delivers the links that open the app. One implementation per platform
/// family.
abstract interface class DeepLinks {
  /// The link that started the app, or null when it was started without
  /// one. Read once.
  Future<Uri?> initialLink();

  /// The links received while the app runs.
  Stream<Uri> get links;
}

/// The `soundspan:` URIs among launch [arguments], in order; other
/// arguments and unparsable ones are skipped.
List<Uri> deepLinksIn(Iterable<String> arguments) => [
  for (final argument in arguments)
    if (argument.toLowerCase().startsWith('$deepLinkScheme:'))
      ?Uri.tryParse(argument),
];

/// The arguments the app was launched with (`main`'s), empty unless
/// bootstrap overrides it.
final Provider<List<String>> launchArgumentsProvider = Provider<List<String>>(
  (ref) => const [],
);

/// The app's [DeepLinks]; tests override it.
final Provider<DeepLinks> deepLinksProvider = Provider<DeepLinks>(
  (ref) => createDeepLinks(
    launchArguments: ref.watch(launchArgumentsProvider),
    desktopShell: ref.watch(desktopShellProvider),
  ),
);
