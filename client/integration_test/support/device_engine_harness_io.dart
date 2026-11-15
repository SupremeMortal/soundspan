// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

import 'device_engine_harness_base.dart';
import 'engine_conformance.dart';
import 'tone_server.dart';

/// What every native harness of one test run shares: the in-process tone
/// server and the app's temporary directory.
final class DeviceEngineSetup {
  new _(this._server, this._temp);

  /// Starts the tone server and finds the temporary directory.
  static Future<DeviceEngineSetup> start() async {
    // The suite talks to a real server; a test binding may mock HttpClient.
    HttpOverrides.global = null;
    // The macOS sandbox container's cache directory may not exist yet.
    final temp = await getTemporaryDirectory();
    await temp.create(recursive: true);
    return DeviceEngineSetup._(await ToneServer.start(), temp);
  }

  final ToneServer _server;
  final Directory _temp;

  /// The platform the engine runs on.
  String get platform => Platform.operatingSystem;

  /// A harness for one test.
  EngineHarness harness() => _NativeHarness(_server, _temp);

  /// Stops the tone server.
  Future<void> close() => _server.close();
}

final class _NativeHarness extends DeviceEngineHarnessBase {
  new(this._server, this._temp) : super(_server.baseUrl);

  final ToneServer _server;
  final Directory _temp;
  final List<File> _files = [];

  @override
  bool get credentialsInQuery => false;

  @override
  EngineSource localFile(String queueItemId) {
    final file = File(
      '${_temp.path}/conformance-${DateTime.now().microsecondsSinceEpoch}'
      '-$queueItemId.wav',
    )..writeAsBytesSync(ToneServer.wav(const Duration(seconds: 3)));
    _files.add(file);
    return EngineSource(queueItemId: queueItemId, uri: Uri.file(file.path));
  }

  @override
  Future<Map<String, String>> credentialsSeenFor(String queueItemId) async =>
      _server.lastRequest(pathOf(queueItemId))?.headers ?? const {};

  @override
  Future<void> disableNetwork() async => _server.reachable = false;

  /// 20 ms on Android and on iOS hardware. 100 ms, the largest tolerance
  /// doc 06 allows, on macOS, whose transition between the two loaded
  /// items is not reliably gapless (Spike S1 finding), and on the iOS
  /// simulator, whose index and position reports jitter by tens of
  /// milliseconds around a transition from run to run. Gapless playback on
  /// a Mac and an iPhone is confirmed on real hardware.
  @override
  Duration get gapTolerance =>
      Platform.isMacOS ||
          (Platform.isIOS &&
              Platform.environment.containsKey('SIMULATOR_DEVICE_NAME'))
      ? const Duration(milliseconds: 100)
      : const Duration(milliseconds: 20);

  @override
  Set<ConformanceCase> get skipped => const {};

  @override
  Future<void> dispose() async {
    await super.dispose();
    _server.reachable = true;
    for (final file in _files) {
      if (file.existsSync()) file.deleteSync();
    }
  }
}
