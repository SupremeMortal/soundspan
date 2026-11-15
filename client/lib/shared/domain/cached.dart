// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart' show ApiException;

/// A value read from the cache, with how fresh it is (doc 05, Read Policy:
/// Stale-While-Revalidate).
final class Cached<T> {
  /// A cached [value] fetched at [fetchedAt].
  const new({
    required this.value,
    required this.fetchedAt,
    this.refreshing = false,
    this.refreshError,
  });

  /// The value.
  final T value;

  /// When [value] was fetched from the server, in UTC.
  final DateTime fetchedAt;

  /// Whether a refresh of [value] is in flight.
  final bool refreshing;

  /// Why the last refresh failed; non-null when [value] is shown but could
  /// not be refreshed.
  final ApiException? refreshError;

  @override
  // Every field is final; `meta` is not imported so the domain stays pure.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is Cached<T> &&
      other.value == value &&
      other.fetchedAt == fetchedAt &&
      other.refreshing == refreshing &&
      other.refreshError == refreshError;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(value, fetchedAt, refreshing, refreshError);

  @override
  String toString() =>
      'Cached($value, fetchedAt: $fetchedAt, refreshing: $refreshing, '
      'refreshError: $refreshError)';
}
