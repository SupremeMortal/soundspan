// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Starts the engine conformance tone server as a process, for the web run
/// of `integration_test/engine_conformance_test.dart`, which cannot host a
/// server in the page. Every origin is allowed.
///
///   dart tool/tone_server.dart [--port <port>]
///
/// Prints `TONE_SERVER=<address>` once listening and serves until killed.
library;

import 'dart:io';

import '../integration_test/support/tone_server.dart';

Future<void> main(List<String> args) async {
  final at = args.indexOf('--port');
  final port = at >= 0 && at + 1 < args.length ? int.parse(args[at + 1]) : 0;
  final server = await ToneServer.start(port: port, cors: true);
  stdout.writeln('TONE_SERVER=${server.baseUrl}');
  await ProcessSignal.sigterm.watch().first;
  await server.close();
}
