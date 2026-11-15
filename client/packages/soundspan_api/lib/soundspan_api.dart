// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Transport, models and clients for the soundspan server API.
///
/// The public barrel of the `soundspan_api` package.
library;

export 'src/client.dart';
export 'src/config.dart';
export 'src/errors.dart';
export 'src/generated/soundspan_rest_client.dart';
export 'src/paging.dart';
export 'src/probe.dart';
export 'src/transport/adapter.dart';
export 'src/transport/dio_factory.dart';
export 'src/transport/error_mapper.dart' show guardDecode;
export 'src/transport/log_interceptor.dart' show ApiLogEntry, ApiLogSink;
export 'src/urls.dart';
