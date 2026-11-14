// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/app_logger.dart';

import 'recording_sink.dart';

void main() {
  late RecordingSink sink;

  setUp(() {
    sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
  });

  tearDown(AppLogging.reset);

  test('scope, message, level and fields reach the sink', () {
    AppLogger.scope('Downloads').info('x', {'bytes': 3});

    expect(sink.entries, hasLength(1));
    final entry = sink.entries.single;
    expect(entry.scope, 'Downloads');
    expect(entry.message, 'x');
    expect(entry.level, 'info');
    expect(entry.fields, {'bytes': 3});
  });

  test('warning and severe carry the error and stack trace', () {
    final log = AppLogger.scope('Auth');
    final trace = StackTrace.current;
    log
      ..warning('retry', const {}, StateError('w'), trace)
      ..severe('gave up', const {'attempt': 3}, 'boom');

    expect(sink.entries.map((e) => e.level), ['warning', 'severe']);
    expect(sink.entries.first.error, contains('w'));
    expect(sink.entries.first.stackTrace, trace.toString());
    expect(sink.entries.last.error, 'boom');
    expect(sink.entries.last.fields, {'attempt': 3});
  });

  test('fine is delivered when releaseMode is false', () {
    AppLogger.scope('Api').fine('detail');
    expect(sink.entries.map((e) => e.level), ['fine']);
  });

  test('fine is dropped when releaseMode is true', () {
    AppLogging.configure(sinks: [sink], releaseMode: true);
    AppLogger.scope('Api')
      ..fine('detail')
      ..info('lifecycle');
    expect(sink.entries.map((e) => e.message), ['lifecycle']);
  });

  test('the entry a sink receives is already redacted', () {
    AppLogging.setServerBaseUrl(Uri.parse('https://music.example.com/s'));
    AppLogger.scope('Api')
        .info('GET https://music.example.com/s/api/me', {'apiKey': 'k-123'});

    final entry = sink.entries.single;
    expect(entry.fields['apiKey'], '<redacted>');
    expect(entry.message, 'GET <server>/api/me');
  });

  test('a throwing sink does not throw and later sinks still receive', () {
    final later = RecordingSink();
    AppLogging.configure(sinks: [ThrowingSink(), later], releaseMode: false);

    expect(() => AppLogger.scope('Api').info('one'), returnsNormally);
    expect(() => AppLogger.scope('Api').info('two'), returnsNormally);
    expect(later.entries.map((e) => e.message), ['one', 'two']);
  });

  test('nothing is delivered after reset', () {
    AppLogging.reset();
    AppLogger.scope('Api').info('dropped');
    expect(sink.entries, isEmpty);
  });

  test('appLoggerProvider returns a scoped logger', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(appLoggerProvider('Shell')).info('up');

    expect(sink.entries.single.scope, 'Shell');
  });
}
