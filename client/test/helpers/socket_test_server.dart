// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The scriptable socket.io server of `test/support/socket_server/`, run
/// with `node`. There is no maintained socket.io v4 server in Dart.
///
/// Its dependencies must be installed first:
/// `npm ci --prefix test/support/socket_server`.
class SocketTestServer {
  new _(this._process, this.port, this.pathPrefix);

  final Process _process;

  /// The port the server listens on, on 127.0.0.1.
  final int port;

  /// The reverse-proxy prefix the server's socket.io path carries.
  final String pathPrefix;

  /// The base URL a profile on this server would have.
  Uri get baseUrl => Uri.parse('http://127.0.0.1:$port$pathPrefix');

  /// Starts the server; fails with a clear message when `node` or the
  /// server's dependencies are missing.
  ///
  /// It clears `HttpOverrides.global`: flutter_test answers every
  /// `HttpClient` request with 400, and the socket and the control calls
  /// talk to a real server.
  static Future<SocketTestServer> start({String pathPrefix = ''}) async {
    HttpOverrides.global = null;
    final directory = _serverDirectory();
    if (!File('${directory.path}/node_modules/socket.io/package.json')
        .existsSync()) {
      throw StateError(
        'The socket test server has no dependencies: run '
        '"npm ci --prefix test/support/socket_server" in client/',
      );
    }
    final Process process;
    try {
      process = await Process.start(
        'node',
        ['server.mjs'],
        workingDirectory: directory.path,
        environment: {'SOCKET_PATH_PREFIX': pathPrefix},
      );
    } on ProcessException catch (error) {
      throw StateError(
        'The socket tests need Node.js on PATH (the version in .nvmrc): '
        '${error.message}',
      );
    }
    final port = Completer<int>();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final match = RegExp(r'^PORT=(\d+)$').firstMatch(line);
          if (match != null && !port.isCompleted) {
            port.complete(int.parse(match.group(1)!));
          }
        });
    final errors = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(errors.write);
    unawaited(
      process.exitCode.then((code) {
        if (!port.isCompleted) {
          port.completeError(
            StateError('The socket test server exited with $code: $errors'),
          );
        }
      }),
    );
    return SocketTestServer._(
      process,
      await port.future.timeout(const Duration(seconds: 20)),
      pathPrefix,
    );
  }

  static Directory _serverDirectory() {
    var directory = Directory.current;
    while (true) {
      final candidate = Directory(
        '${directory.path}/test/support/socket_server',
      );
      if (candidate.existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) {
        throw StateError('test/support/socket_server not found');
      }
      directory = parent;
    }
  }

  /// Sends a `/__control` command.
  Future<void> control(Map<String, Object?> command) async {
    await _request('POST', '/__control', command);
  }

  /// Emits [event] with [payload] to every socket, or to [room].
  Future<void> emit(String event, Object? payload, {String? room}) => control({
    'command': 'emit',
    'event': event,
    'payload': payload,
    'room': ?room,
  });

  /// Rejects the next handshake with [message].
  Future<void> rejectHandshake(String message) =>
      control({'command': 'rejectHandshake', 'message': message});

  /// Disconnects every socket from the server side.
  Future<void> disconnectAll() => control({'command': 'disconnect'});

  /// Scripts the next acknowledgements of [event].
  Future<void> scriptAcks(String event, List<Map<String, Object?>> responses) =>
      control({'command': 'ack', 'event': event, 'responses': responses});

  /// Forgets scripts, records and rejections.
  Future<void> reset() => control({'command': 'reset'});

  /// The `handshake.auth` payloads seen so far.
  Future<List<Map<String, Object?>>> handshakes() async => [
    for (final item in (await _request('GET', '/__handshakes', null))! as List)
      Map<String, Object?>.from(item as Map),
  ];

  /// The client events received so far, as `{ socketId, event, payload }`.
  Future<List<Map<String, Object?>>> events() async => [
    for (final item in (await _request('GET', '/__events', null))! as List)
      Map<String, Object?>.from(item as Map),
  ];

  /// The ids of the connected sockets.
  Future<List<String>> sockets() async => [
    for (final item in (await _request('GET', '/__sockets', null))! as List)
      item as String,
  ];

  Future<Object?> _request(String method, String path, Object? body) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:$port$path'),
      );
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw StateError('$method $path: ${response.statusCode} $text');
      }
      return jsonDecode(text);
    } finally {
      client.close();
    }
  }

  /// Stops the server.
  Future<void> close() async {
    _process.kill();
    await _process.exitCode;
  }
}
