// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Records one scrubbed response per declared capture step from the seeded
/// contract server, for the decode smoke test of `soundspan_api`.
///
/// ```sh
/// dart run tool/capture_fixtures.dart [--out <dir>]
/// ```
///
/// Reads `.seed/credentials.json` (written by `seed.ts`) and writes
/// `<operationId>[.<variant>].json` files to `<dir>`, by default
/// `../packages/soundspan_api/test/fixtures/`. Every step runs even when an
/// earlier one failed; the tool exits 1 when any step failed or the server
/// answered `RESPONSE_SCHEMA_MISMATCH`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../test/support.dart';
import 'src/capture_steps.dart';

/// Where fixtures go without `--out`.
const _defaultOut = '../packages/soundspan_api/test/fixtures';

Future<void> main(List<String> args) async {
  final out = switch (args) {
    [] => _defaultOut,
    ['--out', final dir] => dir,
    _ => _usage(),
  };
  final credentialsFile = File(credentialsPath);
  if (!credentialsFile.existsSync()) {
    stderr.writeln(
      '$credentialsPath is missing: start the contract server and run '
      'seed.ts first (run.sh --capture does both).',
    );
    exit(1);
  }
  final credentials = ContractCredentials.fromJson(
    jsonDecode(credentialsFile.readAsStringSync()) as Map<String, Object?>,
  );
  final guards = <SchemaMismatchGuard>[];
  final context = CaptureContext(
    credentials: credentials,
    adapter: () {
      final guard = SchemaMismatchGuard(platformHttpClientAdapter());
      guards.add(guard);
      return guard;
    },
  );
  Directory(out).createSync(recursive: true);
  final failures = <String>[];
  try {
    await context.signIn();
  } on Object catch (error) {
    stderr.writeln(
      'Signing the seeded accounts in failed: ${_describe(error)}',
    );
    exit(1);
  }
  for (final step in captureSteps) {
    try {
      final response = await step.request(context);
      final status = response.statusCode ?? 0;
      final contentType = response.headers.value(Headers.contentTypeHeader);
      if (status < 200 || status > 299) {
        throw StateError('answered $status');
      }
      if (contentType == null || !contentType.contains('json')) {
        throw StateError('answered $contentType, not JSON');
      }
      final body = scrub(context.decode(response));
      File('$out/${step.fileName}').writeAsStringSync(encodeFixture(body));
      stdout.writeln('ok   ${step.fileName}');
    } on Object catch (error) {
      failures.add('${step.fileName}: ${_describe(error)}');
      stdout.writeln('FAIL ${step.fileName}: ${_describe(error)}');
    }
  }
  context.close();
  for (final guard in guards) {
    try {
      guard.verify();
    } on Object catch (error) {
      failures.add('$error');
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln('${failures.length} capture step(s) failed:');
    failures.forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln('Wrote ${captureSteps.length} fixtures to $out');
}

String _describe(Object error) => switch (error) {
  ApiException() => '$error',
  DioException(:final response?) => '${response.statusCode}: ${response.data}',
  _ => '$error',
};

Never _usage() {
  stderr.writeln('Usage: dart run tool/capture_fixtures.dart [--out <dir>]');
  exit(64);
}
