// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/deep_links/deep_links.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// The web [DeepLinks]: the page's `?link=<code>&server=<url>` query, once,
/// as `soundspan://link?code=…&server=…`. [launchArguments] and
/// [desktopShell] are unused on web.
DeepLinks createDeepLinks({
  required List<String> launchArguments,
  required DesktopShell desktopShell,
}) => QueryDeepLinks(Uri.base);

/// [DeepLinks] read from the query of the URL the app was loaded from.
class QueryDeepLinks implements DeepLinks {
  /// Creates the links of the page URL.
  new(this._page);

  final Uri _page;
  bool _read = false;

  @override
  Future<Uri?> initialLink() async {
    if (_read) return null;
    _read = true;
    return linkFromQuery(_page);
  }

  @override
  Stream<Uri> get links => const Stream.empty();
}

/// The `soundspan://link` URI for the `link` and `server` query parameters
/// of [page], or null when it has no `server`.
Uri? linkFromQuery(Uri page) {
  final query = page.queryParameters;
  final server = query['server'];
  if (server == null || server.isEmpty) return null;
  final code = query['link'];
  return Uri(
    scheme: deepLinkScheme,
    host: 'link',
    queryParameters: {
      if (code != null && code.isNotEmpty) 'code': code,
      'server': server,
    },
  );
}
