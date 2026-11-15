// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/probe/probe_failure.dart';
import 'package:soundspan_api/soundspan_api.dart';

ProbeFailureClass? _transport(TransportFailure kind, {bool isWeb = false}) =>
    classifyProbeFailure(transport: kind, hasHealthBody: false, isWeb: isWeb);

ProbeFailureClass? _status(int status, {bool hasHealthBody = false}) =>
    classifyProbeFailure(
      status: status,
      hasHealthBody: hasHealthBody,
      isWeb: false,
    );

void main() {
  test('dns', () {
    expect(_transport(TransportFailure.hostLookup), ProbeFailureClass.dns);
  });

  test('refused', () {
    expect(
      _transport(TransportFailure.connectionRefused),
      ProbeFailureClass.refused,
    );
  });

  test('timeout', () {
    expect(_transport(TransportFailure.timeout), ProbeFailureClass.timeout);
    expect(
      _transport(TransportFailure.connection),
      ProbeFailureClass.timeout,
      reason: 'an unclassified native transport failure reads as no answer',
    );
  });

  test('tls', () {
    expect(_transport(TransportFailure.tls), ProbeFailureClass.tls);
  });

  test('blockedByProxy (401 and 403)', () {
    expect(_status(401), ProbeFailureClass.blockedByProxy);
    expect(_status(403), ProbeFailureClass.blockedByProxy);
  });

  test('notSoundspan (404 and a non-JSON 200, plus JSON without status)', () {
    expect(_status(404), ProbeFailureClass.notSoundspan);
    expect(_status(200), ProbeFailureClass.notSoundspan);
    expect(_status(418), ProbeFailureClass.notSoundspan);
    expect(_status(302), ProbeFailureClass.notSoundspan);
  });

  test('serverError (500 without a health body)', () {
    expect(_status(500), ProbeFailureClass.serverError);
    expect(_status(502), ProbeFailureClass.serverError);
    expect(_status(503), ProbeFailureClass.serverError);
  });

  test('corsOrNetwork', () {
    for (final kind in TransportFailure.values) {
      expect(
        _transport(kind, isWeb: true),
        ProbeFailureClass.corsOrNetwork,
        reason: kind.name,
      );
    }
  });

  test('a 503 with a health body is not a failure', () {
    expect(_status(503, hasHealthBody: true), isNull);
    expect(_status(200, hasHealthBody: true), isNull);
  });
}
