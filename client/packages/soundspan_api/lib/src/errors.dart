// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The sealed [ApiException] hierarchy: the only errors the package throws.
library;

import 'package:meta/meta.dart';

/// A failed server call.
///
/// Classified by HTTP status first, then by the server's `code`. An unknown
/// `code` keeps the status-level class and is carried in [code].
@immutable
sealed class ApiException implements Exception {
  const new({this.status, this.code, this.serverMessage});

  /// The HTTP status, or null when no response arrived.
  final int? status;

  /// The server's `code`, verbatim, when present.
  final String? code;

  /// The server's `error` string, for logs; the UI shows localized text.
  final String? serverMessage;

  /// The class name, for [toString].
  String get _kind;

  @override
  String toString() => '$_kind(status: $status, code: $code)';
}

/// No response arrived: DNS failure, connection refused, timeout or TLS
/// failure.
final class Offline extends ApiException {
  /// Creates an [Offline].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'Offline';
}

/// 401: the request carried no valid credential.
final class Unauthenticated extends ApiException {
  /// Creates an [Unauthenticated].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'Unauthenticated';
}

/// 403.
final class Forbidden extends ApiException {
  /// Creates a [Forbidden].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'Forbidden';
}

/// 404 without the `FEATURE_DISABLED` code.
final class NotFound extends ApiException {
  /// Creates a [NotFound].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'NotFound';
}

/// 404 with the code `FEATURE_DISABLED`: an optional server feature is off.
final class FeatureDisabled extends ApiException {
  /// Creates a [FeatureDisabled].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'FeatureDisabled';
}

/// 409. Known codes have the subclasses [SourceUnavailable],
/// [CacheLimitExceeded] and [DownloadsDisabled].
base class Conflict extends ApiException {
  /// Creates a [Conflict].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'Conflict';
}

/// 409 with the code `SOURCE_UNAVAILABLE`.
final class SourceUnavailable extends Conflict {
  /// Creates a [SourceUnavailable].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'SourceUnavailable';
}

/// 409 with the code `CACHE_LIMIT_EXCEEDED`.
final class CacheLimitExceeded extends Conflict {
  /// Creates a [CacheLimitExceeded].
  const new({
    required this.limitBytes,
    required this.usedBytes,
    required this.estimatedBytes,
    super.status,
    super.code,
    super.serverMessage,
  });

  /// The server's `cacheLimitBytes`.
  final int limitBytes;

  /// The server's `cacheUsedBytes`.
  final int usedBytes;

  /// The server's `estimatedTotalBytes` for the refused request.
  final int estimatedBytes;

  @override
  String get _kind => 'CacheLimitExceeded';
}

/// 409 with the code `SOURCE_DOWNLOADS_DISABLED`.
final class DownloadsDisabled extends Conflict {
  /// Creates a [DownloadsDisabled].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'DownloadsDisabled';
}

/// 400, or another 4xx with a JSON error body that has no class of its own;
/// [code] distinguishes `METADATA_REQUIRED` and the like.
final class InvalidRequest extends ApiException {
  /// Creates an [InvalidRequest].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'InvalidRequest';
}

/// 429. The body is usually plain text.
final class RateLimited extends ApiException {
  /// Creates a [RateLimited].
  const new({
    required this.retryAfter,
    super.status,
    super.code,
    super.serverMessage,
  });

  /// The server's `Retry-After`; 60 s when it is missing or unparseable.
  final Duration retryAfter;

  @override
  String get _kind => 'RateLimited';
}

/// A 2xx JSON body that failed to decode into its model: a contract bug.
final class InvalidResponse extends ApiException {
  /// Creates an [InvalidResponse].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'InvalidResponse';
}

/// 502, 503 or 504 with the code `UPSTREAM_FAILED`.
final class Upstream extends ApiException {
  /// Creates an [Upstream].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'Upstream';
}

/// Any other 5xx, including one with an HTML body.
final class ServerError extends ApiException {
  /// Creates a [ServerError].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'ServerError';
}

/// The answer did not come from a soundspan server: a 2xx whose body is not
/// JSON where JSON is expected, or a 4xx (other than 429) whose body is not
/// the `{ error }` shape.
final class NotSoundspan extends ApiException {
  /// Creates a [NotSoundspan].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'NotSoundspan';
}

/// Anything no other class fits: an unclassifiable transport failure or an
/// unexpected status such as a 3xx.
final class Unexpected extends ApiException {
  /// Creates an [Unexpected].
  const new({super.status, super.code, super.serverMessage});
  @override
  String get _kind => 'Unexpected';
}
