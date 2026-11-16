// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

/// The [QrScanner] over `mobile_scanner` (Android, iOS, macOS and web): QR
/// codes only, each code reported once while it stays in view.
class MobileQrScanner implements QrScanner {
  /// Creates the scanner; the camera stays off until [start].
  new();

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final StreamController<QrScannerError> _errors =
      StreamController<QrScannerError>.broadcast();

  @override
  Widget buildPreview(BuildContext context) => MobileScanner(
    controller: _controller,
    errorBuilder: (_, _) => const SizedBox.shrink(),
  );

  @override
  Stream<String> get results => _controller.barcodes.expand(
    (capture) => [
      for (final barcode in capture.barcodes)
        if (barcode.rawValue case final value? when value.isNotEmpty) value,
    ],
  );

  @override
  Stream<QrScannerError> get errors => _errors.stream;

  @override
  Future<void> start() async {
    try {
      await _controller.start();
    } on MobileScannerException catch (error) {
      final mapped = qrScannerErrorOf(error.errorCode);
      if (mapped != null && !_errors.isClosed) _errors.add(mapped);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _controller.stop();
    } on MobileScannerException {
      // Stopping a scanner that never started is not a failure.
    }
  }

  @override
  Future<void> dispose() async {
    await _controller.dispose();
    await _errors.close();
  }
}

/// The [QrScannerError] a `mobile_scanner` failure [code] means, or null
/// for the lifecycle codes a repeated start or stop raises.
QrScannerError? qrScannerErrorOf(MobileScannerErrorCode code) => switch (code) {
  MobileScannerErrorCode.permissionDenied => QrScannerError.permissionDenied,
  MobileScannerErrorCode.unsupported ||
  MobileScannerErrorCode.genericError => QrScannerError.noCamera,
  MobileScannerErrorCode.controllerAlreadyInitialized ||
  MobileScannerErrorCode.controllerDisposed ||
  MobileScannerErrorCode.controllerUninitialized ||
  MobileScannerErrorCode.controllerInitializing ||
  MobileScannerErrorCode.controllerNotAttached => null,
};
