// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:soundspan_api/src/probe_transport_io.dart';
import 'package:test/test.dart';

DioException _error(Object error) => DioException(
  requestOptions: RequestOptions(path: 'https://h/api/health'),
  type: DioExceptionType.connectionError,
  error: error,
);

void main() {
  group('transport failure mapping', () {
    test('connection to a closed local port is connectionRefused', () async {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();
      final client = ProbeClient();
      addTearDown(client.close);
      await expectLater(
        client.get(Uri.parse('http://127.0.0.1:$port/api/health')),
        throwsA(
          isA<ProbeTransportException>().having(
            (e) => e.kind,
            'kind',
            TransportFailure.connectionRefused,
          ),
        ),
      );
    });

    test('failed host lookup maps to hostLookup', () {
      expect(
        mapTransportError(
          _error(
            const SocketException(
              "Failed host lookup: 'nowhere.invalid'",
              osError: OSError('Name or service not known', -2),
            ),
          ),
        ),
        TransportFailure.hostLookup,
      );
    });

    test('a refusal named only by its OS error code is connectionRefused', () {
      for (final code in [111, 61, 10061]) {
        expect(
          mapTransportError(
            _error(SocketException('x', osError: OSError('', code))),
          ),
          TransportFailure.connectionRefused,
          reason: 'errno $code',
        );
      }
    });

    test('HandshakeException maps to tls', () {
      expect(
        mapTransportError(_error(const HandshakeException('bad cert'))),
        TransportFailure.tls,
      );
      expect(
        mapTransportError(_error(const TlsException('x'))),
        TransportFailure.tls,
      );
      expect(
        mapTransportError(_error(const CertificateException('x'))),
        TransportFailure.tls,
      );
    });

    test('connect timeout maps to timeout', () {
      final options = RequestOptions(path: 'https://h/api/health');
      expect(
        mapTransportError(
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 10),
            requestOptions: options,
          ),
        ),
        TransportFailure.timeout,
      );
      expect(
        mapTransportError(
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 10),
            requestOptions: options,
          ),
        ),
        TransportFailure.timeout,
      );
      expect(
        mapTransportError(
          DioException.sendTimeout(
            timeout: const Duration(seconds: 10),
            requestOptions: options,
          ),
        ),
        TransportFailure.timeout,
      );
    });

    test('unknown socket error maps to connection', () {
      expect(
        mapTransportError(
          _error(
            const SocketException(
              'Connection reset by peer',
              osError: OSError('', 104),
            ),
          ),
        ),
        TransportFailure.connection,
      );
      expect(
        mapTransportError(_error(StateError('?'))),
        TransportFailure.connection,
      );
    });
  });

  group('ProbeClient against a local server', () {
    late HttpServer server;
    late Uri base;
    late ProbeClient client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      server.listen((request) async {
        final response = request.response;
        switch (request.uri.path) {
          case '/moved/api/health':
            response
              ..statusCode = 301
              ..headers.set('Location', '/other/api/health');
          case '/text':
            response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write('<html>hello</html>');
          case '/array':
            response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write('[1, 2]');
          default:
            expect(request.headers.value('authorization'), isNull);
            response
              ..statusCode = 503
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'status': 'starting', 'version': '2.6.1'}));
        }
        await response.close();
      });
      client = ProbeClient();
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test('a redirect is returned, not followed', () async {
      final uri = base.replace(path: '/moved/api/health');
      final response = await client.get(uri);
      expect(response.status, 301);
      expect(response.uri, uri);
      expect(response.location, base.replace(path: '/other/api/health'));
      expect(response.json, isNull);
    });

    test('non-JSON and JSON bodies', () async {
      final html = await client.get(base.replace(path: '/text'));
      expect(html.status, 200);
      expect(html.json, isNull);
      expect(html.location, isNull);

      final array = await client.get(base.replace(path: '/array'));
      expect(array.json, isNull);

      final health = await client.get(base.replace(path: '/api/health'));
      expect(health.status, 503, reason: 'every status is accepted');
      expect(health.json, {'status': 'starting', 'version': '2.6.1'});
    });
  });
}
