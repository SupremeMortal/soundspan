// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

import 'device_engine_harness_base.dart';
import 'engine_conformance.dart';

/// The tone server started by `tool/tone_server.dart`, passed with
/// `--dart-define=TONE_SERVER=<address>`.
const String _toneServer = String.fromEnvironment('TONE_SERVER');

/// What every web harness of one test run shares: the tone server process.
final class DeviceEngineSetup {
  new _(this._baseUrl);

  /// Reads the tone server address.
  static Future<DeviceEngineSetup> start() async {
    if (_toneServer.isEmpty) {
      throw StateError(
        'Start tool/tone_server.dart and pass '
        '--dart-define=TONE_SERVER=<address>',
      );
    }
    return DeviceEngineSetup._(Uri.parse(_toneServer));
  }

  final Uri _baseUrl;
  final Dio _dio = Dio(BaseOptions(validateStatus: (_) => true));

  /// The platform the engine runs on.
  String get platform => 'web';

  /// A harness for one test.
  EngineHarness harness() => _WebHarness(_baseUrl, _dio);

  /// Closes the control connection.
  Future<void> close() async => _dio.close(force: true);
}

/// Credentials travel as the `token` query value; local files and the gap
/// measurement are not run on the web (doc 06: web is best-effort).
final class _WebHarness extends DeviceEngineHarnessBase {
  new(super.baseUrl, this._dio);

  final Dio _dio;

  @override
  bool get credentialsInQuery => true;

  @override
  EngineSource localFile(String queueItemId) =>
      throw UnsupportedError('No local files on the web');

  @override
  Future<Map<String, String>> credentialsSeenFor(String queueItemId) async {
    final response = await _dio.getUri<Map<String, Object?>>(
      baseUrl.replace(
        path: '/requests',
        queryParameters: {'path': pathOf(queueItemId)},
      ),
    );
    final query = response.data?['query'];
    if (query is! Map) return const {};
    return {if (query['token'] case final String token) 'token': token};
  }

  @override
  Future<void> disableNetwork() =>
      throw UnsupportedError('The web harness cannot take the network down');

  @override
  Duration get gapTolerance => const Duration(milliseconds: 20);

  @override
  Set<ConformanceCase> get skipped => const {
    ConformanceCase.localFileOffline,
    ConformanceCase.gapless,
  };
}
