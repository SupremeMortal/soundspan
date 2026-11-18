// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/qr_scanner/mobile_qr_scanner.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

/// The web [QrScanner], over `mobile_scanner`.
QrScanner createQrScanner() => MobileQrScanner();
