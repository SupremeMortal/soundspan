// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The login rate limit. It exhausts the server's login limiter for the
/// runner's address for the rest of its 15-minute window, after which even
/// correct logins are refused, so it runs last (tag `contract-destructive`).
@Tags(['contract-destructive'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The most failed logins the test sends; the server allows 40 per window.
const _maxAttempts = 45;

/// One 429 the server sent, as it arrived.
final class _RateLimitReply {
  new({
    required this.contentType,
    required this.retryAfter,
    required this.body,
  });

  final String? contentType;
  final String? retryAfter;
  final String body;
}

/// Counts every request it sends and keeps the last 429 response.
final class _RecordingAdapter implements HttpClientAdapter {
  new(this._inner);

  final HttpClientAdapter _inner;

  /// Requests sent so far.
  int requests = 0;

  /// The last 429, or null.
  _RateLimitReply? rateLimited;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final response = await _inner.fetch(options, requestStream, cancelFuture);
    if (response.statusCode != 429) return response;
    final bytes = await response.stream.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    final body = bytes.takeBytes();
    rateLimited = _RateLimitReply(
      contentType: response.headers[Headers.contentTypeHeader]?.join(),
      retryAfter: response.headers['retry-after']?.join(),
      body: utf8.decode(body),
    );
    return ResponseBody.fromBytes(
      body,
      response.statusCode,
      headers: response.headers,
      statusMessage: response.statusMessage,
      isRedirect: response.isRedirect,
    )..redirects = response.redirects;
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

void main() {
  test('repeated failed logins end in a plain-text 429 with Retry-After, '
      'surfaced as RateLimited without a retry storm', () async {
    final credentials = ContractCredentials.load();
    final guard = SchemaMismatchGuard(platformHttpClientAdapter());
    final recorder = _RecordingAdapter(guard);
    final api = SoundspanApi.anonymous(
      credentials.baseUrl,
      userAgent: 'soundspan-contract-test',
      adapter: recorder,
    );
    addTearDown(() {
      api.close();
      guard.verify();
    });
    final wrongLogin = LoginRequest(
      username: credentials.listener.username,
      password: '${credentials.listener.password}-wrong',
    );

    RateLimited? limited;
    var attempts = 0;
    while (limited == null && attempts < _maxAttempts) {
      attempts++;
      try {
        await api.send((rest) => rest.session.login(body: wrongLogin));
        fail('a wrong password signed in');
      } on Unauthenticated {
        continue;
      } on RateLimited catch (error) {
        limited = error;
      }
    }

    expect(limited, isNotNull, reason: 'no 429 after $attempts failed logins');
    final reply = recorder.rateLimited!;
    expect(reply.contentType, isNot(contains('json')));
    expect(reply.body, isNotEmpty);
    expect(() => jsonDecode(reply.body), throwsFormatException);
    final retryAfter = int.tryParse(reply.retryAfter ?? '');
    expect(retryAfter, isNotNull, reason: 'Retry-After: ${reply.retryAfter}');
    expect(limited!.status, 429);
    expect(limited.retryAfter, Duration(seconds: retryAfter!));

    // One request per attempt: the transport did not retry the 429, and
    // nothing follows it.
    expect(recorder.requests, attempts);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(recorder.requests, attempts);
  });
}
