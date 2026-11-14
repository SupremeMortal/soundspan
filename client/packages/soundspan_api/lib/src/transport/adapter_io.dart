// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// HTTP/1.1 keep-alive with at most 6 connections per host. Certificates
/// are checked against the OS store only: no `badCertificateCallback`.
HttpClientAdapter platformHttpClientAdapter() => IOHttpClientAdapter(
  createHttpClient: () => HttpClient()..maxConnectionsPerHost = 6,
);
