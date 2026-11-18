// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/probe.dart';

/// On the web a CORS rejection, a refused connection, a failed lookup and a
/// timeout look alike, so every transport error is
/// [TransportFailure.connection].
TransportFailure mapTransportError(DioException error) =>
    TransportFailure.connection;
