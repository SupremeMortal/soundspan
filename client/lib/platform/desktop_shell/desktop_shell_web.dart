// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// The web app has no window to manage: a [NoopDesktopShell].
DesktopShell createDesktopShell() => const NoopDesktopShell();
