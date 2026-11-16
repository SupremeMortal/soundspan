// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/platform/qr_scanner/mobile_qr_scanner.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

/// The native [QrScanner]: `mobile_scanner` on Android, iOS and macOS; an
/// [UnsupportedQrScanner] on Windows and Linux.
QrScanner createQrScanner() => Platform.isWindows || Platform.isLinux
    ? UnsupportedQrScanner()
    : MobileQrScanner();
