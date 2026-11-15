// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Runs the harness's SlowServer on all interfaces of the CI host for the
// Android emulator (which reaches the host at 10.0.2.2) and prints one
// `S5-HTTP {json}` line per request.
//
//   dart run tool/slow_server.dart [port]   (default 8765)

import 'dart:io';

import 'package:spike_s5/harness.dart';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8765 : int.parse(args.first);
  final server = await SlowServer.start(
    address: InternetAddress.anyIPv4,
    port: port,
    onExchange: (exchange) => stdout.writeln(exchange.toLine()),
  );
  stdout.writeln('S5-SLOW-SERVER listening on ${server.port}');
}
