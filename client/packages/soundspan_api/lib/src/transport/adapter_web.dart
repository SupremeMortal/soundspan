// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Sends no cookies (`withCredentials` stays false): authentication is a
/// header.
HttpClientAdapter platformHttpClientAdapter() => BrowserHttpClientAdapter();
