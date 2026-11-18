// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:soundspan/platform/qr_scanner/mobile_qr_scanner.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

void main() {
  test('the Linux test host gets the unsupported scanner', () {
    expect(createQrScanner(), isA<UnsupportedQrScanner>());
  });

  test('the unsupported scanner reports unsupported on start', () async {
    final scanner = UnsupportedQrScanner();
    final errors = <QrScannerError>[];
    final subscription = scanner.errors.listen(errors.add);
    await scanner.start();
    await pumpEventQueue();
    expect(errors, [QrScannerError.unsupported]);
    await scanner.stop();
    await subscription.cancel();
    await scanner.dispose();
  });

  test('mobile_scanner failures map to scanner errors', () {
    expect(
      qrScannerErrorOf(MobileScannerErrorCode.permissionDenied),
      QrScannerError.permissionDenied,
    );
    for (final code in [
      MobileScannerErrorCode.unsupported,
      MobileScannerErrorCode.genericError,
    ]) {
      expect(qrScannerErrorOf(code), QrScannerError.noCamera, reason: '$code');
    }
    for (final code in [
      MobileScannerErrorCode.controllerAlreadyInitialized,
      MobileScannerErrorCode.controllerDisposed,
      MobileScannerErrorCode.controllerUninitialized,
      MobileScannerErrorCode.controllerInitializing,
      MobileScannerErrorCode.controllerNotAttached,
    ]) {
      expect(qrScannerErrorOf(code), isNull, reason: '$code');
    }
  });
}
