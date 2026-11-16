// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The QR scanner seam (doc 02, Platform Seams; doc 04, Device Link).
///
/// `createQrScanner` returns, on Android, iOS, macOS and web, a scanner over
/// `mobile_scanner` that decodes QR codes only; on Windows and Linux one
/// whose [QrScanner.start] reports [QrScannerError.unsupported]
/// (`PlatformCapabilities.canScanQr` is false there). `mobile_scanner` is
/// imported only under this directory.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner_web.dart'
    if (dart.library.io) 'package:soundspan/platform/qr_scanner/qr_scanner_io.dart';

export 'qr_scanner_web.dart'
    if (dart.library.io) 'qr_scanner_io.dart'
    show createQrScanner;

/// Why a [QrScanner] cannot scan.
enum QrScannerError {
  /// The user denied the camera permission.
  permissionDenied,

  /// The device has no usable camera.
  noCamera,

  /// The platform has no scanner.
  unsupported,
}

/// A camera QR-code scanner. One instance serves one scan screen.
abstract interface class QrScanner {
  /// Builds the camera preview. Emits raw decoded strings on [results].
  Widget buildPreview(BuildContext context);

  /// The decoded content of each QR code the camera sees.
  Stream<String> get results;

  /// Why scanning failed.
  Stream<QrScannerError> get errors;

  /// Starts the camera; the OS asks for the camera permission the first
  /// time.
  Future<void> start();

  /// Stops the camera.
  Future<void> stop();

  /// Stops the camera and releases the scanner; it is not used again.
  Future<void> dispose();
}

/// A new [QrScanner] for each scan screen; tests override it.
final Provider<QrScanner Function()> qrScannerFactoryProvider =
    Provider<QrScanner Function()>((ref) => createQrScanner);

/// The [QrScanner] of a platform without a camera scanner: [start] reports
/// [QrScannerError.unsupported].
class UnsupportedQrScanner implements QrScanner {
  /// Creates the scanner.
  new();

  final _errors = StreamController<QrScannerError>.broadcast();

  @override
  Widget buildPreview(BuildContext context) => const SizedBox.shrink();

  @override
  Stream<String> get results => const Stream.empty();

  @override
  Stream<QrScannerError> get errors => _errors.stream;

  @override
  Future<void> start() async => _errors.add(QrScannerError.unsupported);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _errors.close();
}
