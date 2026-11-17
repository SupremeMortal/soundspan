// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/playback_command.dart';
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

/// Why a command sent to the group did not take effect; the UI turns it
/// into a message (doc 08, Commands From This Device).
sealed class GroupCommandError {
  const new();
}

/// The server answered the command with an error.
final class GroupCommandRejected extends GroupCommandError {
  /// Creates the error with the server's [message] and [code], if any.
  const new({this.message, this.code});

  /// The server's message.
  final String? message;

  /// The server's error code.
  final String? code;

  @override
  String toString() => 'GroupCommandRejected($code, $message)';
}

/// No acknowledgement arrived within the five seconds a command waits.
final class GroupCommandTimedOut extends GroupCommandError {
  /// Creates the error.
  const new();

  @override
  String toString() => 'GroupCommandTimedOut()';
}

/// The socket was not connected, so nothing was sent.
final class GroupCommandOffline extends GroupCommandError {
  /// Creates the error.
  const new();

  @override
  String toString() => 'GroupCommandOffline()';
}

/// Only the host controls playback in this group; nothing was sent.
final class HostControlsPlayback extends GroupCommandError {
  /// Creates the error.
  const new();

  @override
  String toString() => 'HostControlsPlayback()';
}

/// The group has no such control (shuffle, repeat); nothing was sent.
final class RemoteCommandUnsupported extends GroupCommandError {
  /// Creates the error.
  const new();

  @override
  String toString() => 'RemoteCommandUnsupported()';
}

/// [count] items could not be added to the group: episodes and tracks
/// without a playback id. The others were sent.
final class ItemsNotShareable extends GroupCommandError {
  /// Creates the error.
  const new(this.count);

  /// How many items were left out.
  final int count;

  @override
  String toString() => 'ItemsNotShareable($count)';
}

/// In [group]; [offsetMs] is the server clock minus the monotonic clock
/// (null before the first measurement), and [canControl] says whether this
/// device may control playback. [pending] holds the commands sent and
/// awaiting an acknowledgement, and [lastCommandError] why the latest
/// failed command failed.
final class ListenTogetherActive extends ListenTogetherState {
  /// Creates the state.
  const new({
    required this.group,
    required this.offsetMs,
    required this.canControl,
    this.pending = const {},
    this.lastCommandError,
  });

  /// The group as the server last described it.
  final Group group;

  /// The server clock minus the monotonic clock, in milliseconds.
  final int? offsetMs;

  /// Whether this device may control playback.
  final bool canControl;

  /// The commands sent to the server and not yet acknowledged; each leaves
  /// on its acknowledgement, an error, or after five seconds.
  final Set<PlaybackCommand> pending;

  /// Why the latest command that failed failed; null before the first.
  final GroupCommandError? lastCommandError;

  @override
  String toString() =>
      'ListenTogetherActive(${group.id}, offset: $offsetMs, '
      'canControl: $canControl, pending: ${pending.length}, '
      'error: $lastCommandError)';
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
