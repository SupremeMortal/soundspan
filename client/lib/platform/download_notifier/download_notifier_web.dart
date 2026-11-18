// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/download_notifier/download_notifier.dart';

/// The [DownloadNotifier] of the web app, where there are no downloads.
DownloadNotifier createDownloadNotifier() => const NoopDownloadNotifier();
