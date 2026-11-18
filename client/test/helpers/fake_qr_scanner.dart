// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

/// A [QrScanner] a test drives: it [scan]s values and [fail]s with errors,
/// and counts [start] and [stop] calls.
class FakeQrScanner implements QrScanner {
  /// Creates the fake.
  new();

  final StreamController<String> _results = StreamController<String>.broadcast(
    sync: true,
  );
  final StreamController<QrScannerError> _errors =
      StreamController<QrScannerError>.broadcast(sync: true);

  /// How often [start] was called.
  int starts = 0;

  /// How often [stop] was called.
  int stops = 0;

  /// Whether [dispose] was called.
  bool disposed = false;

  /// Whether the camera runs: started and not stopped since.
  bool get running => _running;
  bool _running = false;

  @override
  Widget buildPreview(BuildContext context) =>
      const ColoredBox(color: Color(0xFF000000), child: SizedBox.expand());

  @override
  Stream<String> get results => _results.stream;

  @override
  Stream<QrScannerError> get errors => _errors.stream;

  @override
  Future<void> start() async {
    starts++;
    _running = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    _running = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    _running = false;
  }

  /// Reports [value] as a decoded QR code.
  void scan(String value) => _results.add(value);

  /// Reports [error].
  void fail(QrScannerError error) => _errors.add(error);
}
