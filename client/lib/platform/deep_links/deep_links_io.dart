// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:soundspan/platform/deep_links/deep_links.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// The native [DeepLinks]. Windows and Linux read the `soundspan:`
/// arguments of the launch and of the later launches the single-instance
/// runner forwards through [desktopShell]; the other targets use
/// `app_links`.
DeepLinks createDeepLinks({
  required List<String> launchArguments,
  required DesktopShell desktopShell,
}) => Platform.isWindows || Platform.isLinux
    ? LaunchArgumentDeepLinks(
        launchArguments: launchArguments,
        launches: desktopShell.secondInstanceLaunches,
      )
    : AppLinksDeepLinks(AppLinks());

/// [DeepLinks] from `app_links` (Android, iOS, macOS).
class AppLinksDeepLinks implements DeepLinks {
  /// Wraps the `app_links` instance.
  new(this._appLinks);

  final AppLinks _appLinks;

  @override
  Future<Uri?> initialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}

/// [DeepLinks] from command-line arguments (Windows, Linux): the first
/// `soundspan:` argument of the launch, then those of every later launch
/// forwarded by the single-instance runner.
class LaunchArgumentDeepLinks implements DeepLinks {
  /// Creates the links of the launch arguments and of later launches.
  new({required this._launchArguments, required this._launches});

  final List<String> _launchArguments;
  final Stream<List<String>> _launches;

  @override
  Future<Uri?> initialLink() async {
    final links = deepLinksIn(_launchArguments);
    return links.isEmpty ? null : links.first;
  }

  @override
  Stream<Uri> get links => _launches.expand(deepLinksIn);
}
