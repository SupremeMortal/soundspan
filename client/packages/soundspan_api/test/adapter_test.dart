// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'dart:io';

import 'package:dio/io.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  test('the native adapter allows 6 connections per host and no override of '
      'certificate checks', () {
    final adapter = platformHttpClientAdapter();
    expect(adapter, isA<IOHttpClientAdapter>());
    final client = (adapter as IOHttpClientAdapter).createHttpClient!();
    addTearDown(client.close);
    expect(client, isA<HttpClient>());
    expect(client.maxConnectionsPerHost, 6);
    expect(adapter.validateCertificate, isNull);
  });
}
