// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';

/// What `PlaybackController` does about a failure of its current item
/// (doc 06, Controller Behaviour, Failure policy).
sealed class FailureDecision {
  const new();
}

/// Resolve the item again and load it at the last known position after
/// [delay].
final class RetryAfter extends FailureDecision {
  /// Creates the decision.
  const new(this.delay);

  /// How long to wait first.
  final Duration delay;
}

/// Renew the session credential, resolve the item again and load it at the
/// last known position.
final class RefreshAndRetry extends FailureDecision {
  /// Creates the decision.
  const new();
}

/// Record the item as failed with [kind] and advance as `Next` would.
final class SkipItem extends FailureDecision {
  /// Creates the decision.
  const new(this.kind);

  /// The error recorded for the item.
  final PlaybackErrorKind kind;
}

/// Skip an item that cannot be played offline, as `Next` would, without a
/// retry and without counting it as a failed item.
final class SkipUnavailableOffline extends FailureDecision {
  /// Creates the decision.
  const new();
}

/// Stop playback with [kind]; the queue is kept.
final class StopPlayback extends FailureDecision {
  /// Creates the decision.
  const new(this.kind);

  /// The error recorded for the item.
  final PlaybackErrorKind kind;
}

/// The failure policy of one controller: one retry per item for network
/// errors and HTTP 5xx, one credential renewal per item for 401, and a stop
/// after [maxConsecutiveFailedItems] failed items in a row.
///
/// Items that cannot be played offline are skipped outside that count; a
/// full pass over the play order without a playable item stops playback.
final class FailurePolicy {
  /// Creates a policy with no failures counted.
  new();

  /// How long a network or 5xx failure waits before its retry.
  static const Duration retryDelay = Duration(seconds: 1);

  /// How many failed items in a row stop playback.
  static const int maxConsecutiveFailedItems = 3;

  int _failedItems = 0;
  int _offlineSkips = 0;
  bool _retried = false;
  bool _refreshed = false;

  /// A different item became current: its retries are unused.
  void onNewItem() {
    _retried = false;
    _refreshed = false;
  }

  /// An item played, or the user chose what to play: the run of failed items
  /// is over.
  void resetCount() {
    _failedItems = 0;
    _offlineSkips = 0;
  }

  /// The current item resolved to a source: the run of items that cannot
  /// be played offline is over.
  void onPlayable() => _offlineSkips = 0;

  /// The current item cannot be played offline (`NotAvailableOffline`) in
  /// a play order of [playOrderLength] items: it is skipped, unless every
  /// item of one full pass was skipped.
  FailureDecision onNotAvailableOffline(int playOrderLength) {
    _offlineSkips++;
    if (_offlineSkips >= playOrderLength) {
      return const StopPlayback(PlaybackErrorKind.notAvailableOffline);
    }
    return const SkipUnavailableOffline();
  }

  /// The engine reported [error] for the current item.
  FailureDecision onEngineError(EngineError error) {
    switch (error.kind) {
      case EngineErrorKind.unauthorized:
        if (_refreshed) {
          return const StopPlayback(PlaybackErrorKind.unauthorized);
        }
        _refreshed = true;
        return const RefreshAndRetry();
      case EngineErrorKind.network:
        return _retryOnce();
      case EngineErrorKind.http when _isServerError(error.httpStatus):
        return _retryOnce();
      case EngineErrorKind.http ||
          EngineErrorKind.notFound ||
          EngineErrorKind.decode ||
          EngineErrorKind.unknown:
        return _failItem(PlaybackErrorKind.itemUnavailable);
    }
  }

  /// The current item cannot be streamed at all (`NotPlayable`).
  FailureDecision onNotPlayable() =>
      _failItem(PlaybackErrorKind.itemUnavailable);

  /// Resolving the current item failed for another reason.
  FailureDecision onResolveError() => _failItem(PlaybackErrorKind.itemFailed);

  /// Renewing the credential for a [RefreshAndRetry] failed.
  FailureDecision onRefreshFailed() =>
      const StopPlayback(PlaybackErrorKind.unauthorized);

  FailureDecision _retryOnce() {
    if (_retried) return _failItem(PlaybackErrorKind.itemFailed);
    _retried = true;
    return const RetryAfter(retryDelay);
  }

  FailureDecision _failItem(PlaybackErrorKind kind) {
    _failedItems++;
    if (_failedItems >= maxConsecutiveFailedItems) {
      return const StopPlayback(PlaybackErrorKind.serverUnreachable);
    }
    return SkipItem(kind);
  }

  static bool _isServerError(int? status) =>
      status != null && status >= 500 && status <= 599;
}
