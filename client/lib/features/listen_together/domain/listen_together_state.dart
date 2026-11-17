// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/listen_together/domain/group.dart';

/// Why a group stopped for this device without it leaving.
enum GroupEndReason {
  /// The host ended the group.
  ended,

  /// This user was removed from the group.
  membershipRevoked,
}

/// Where this device is in Listen Together (doc 08).
sealed class ListenTogetherState {
  const new();
}

/// In no group.
final class ListenTogetherIdle extends ListenTogetherState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'ListenTogetherIdle()';
}

/// Creating or joining a group.
final class ListenTogetherJoining extends ListenTogetherState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'ListenTogetherJoining()';
}

/// In [group]; [offsetMs] is the server clock minus the monotonic clock
/// (null before the first measurement), and [canControl] says whether this
/// device may control playback.
final class ListenTogetherActive extends ListenTogetherState {
  /// Creates the state.
  const new({
    required this.group,
    required this.offsetMs,
    required this.canControl,
  });

  /// The group as the server last described it.
  final Group group;

  /// The server clock minus the monotonic clock, in milliseconds.
  final int? offsetMs;

  /// Whether this device may control playback.
  final bool canControl;

  @override
  String toString() =>
      'ListenTogetherActive(${group.id}, offset: $offsetMs, '
      'canControl: $canControl)';
}

/// Leaving or ending the group.
final class ListenTogetherLeaving extends ListenTogetherState {
  /// Creates the state.
  const new();

  @override
  String toString() => 'ListenTogetherLeaving()';
}

/// The group stopped for this device because of [reason].
final class ListenTogetherEnded extends ListenTogetherState {
  /// Creates the state.
  const new(this.reason);

  /// Why the group stopped.
  final GroupEndReason reason;

  @override
  String toString() => 'ListenTogetherEnded(${reason.name})';
}
