// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/session/downloads_sign_out_participant.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

/// Lets a profile-scoped service take part in sign-out (doc 04, Sign-Out).
/// Registered through `signOutParticipantsProvider`; the order of the list
/// is the order of execution.
abstract interface class SignOutParticipant {
  /// Steps 1 and 2 of signing out: stop what uses the credential.
  Future<void> onSignOut({required bool removeDownloads});

  /// Extra work for "Remove this server", before the outbox flush.
  Future<void> beforeRemove();
}

/// What a profile holds in downloaded files on this device.
@immutable
final class DownloadsSummary {
  /// Creates the summary of [itemCount] files holding [bytes] bytes.
  const new({required this.itemCount, required this.bytes});

  /// The number of downloaded items.
  final int itemCount;

  /// Their size on disk, in bytes.
  final int bytes;

  @override
  bool operator ==(Object other) =>
      other is DownloadsSummary &&
      other.itemCount == itemCount &&
      other.bytes == bytes;

  @override
  int get hashCode => Object.hash(itemCount, bytes);

  @override
  String toString() => 'DownloadsSummary($itemCount, $bytes)';
}

/// Implemented by a [SignOutParticipant] that may hold downloads of the
/// profile; when one reports downloads, sign-out offers "Also remove
/// downloads" and removal warns that they will be deleted.
abstract interface class ReportsDownloads {
  /// The profile's downloads on this device, or null when it cannot tell.
  Future<DownloadsSummary?> downloadsSummary();
}

/// Playback's part in sign-out: stop, which ends the open play, and wait
/// until the play is written to the outbox, so the outbox pass that
/// follows can send it (doc 06, Play Reporting).
final class PlaybackSignOutParticipant implements SignOutParticipant {
  /// Creates the participant of the controller [_controller] returns;
  /// [_written] completes when the plays it ended are stored.
  const new(this._controller, this._written);

  final PlaybackController Function() _controller;
  final Future<void> Function() _written;

  @override
  Future<void> onSignOut({required bool removeDownloads}) async {
    await _controller().stop();
    // The ended play reaches the reporter as a stream event; let it arrive
    // before waiting for the reporter's writes.
    await Future<void>.delayed(Duration.zero);
    await _written();
  }

  @override
  Future<void> beforeRemove() async {}
}

/// The socket's part in sign-out: leave the group, disconnect and dispose,
/// so nothing reconnects with a credential that is about to be revoked.
final class SocketSignOutParticipant implements SignOutParticipant {
  /// Creates the participant of the given client.
  const new(this._client);

  final SocketClient _client;

  @override
  Future<void> onSignOut({required bool removeDownloads}) => _client.signOut();

  @override
  Future<void> beforeRemove() async {}
}

/// The [SignOutParticipant]s of the profile scope, in execution order:
/// playback, the socket, then downloads where the platform can download.
/// The playback controller is read when sign-out runs.
final Provider<List<SignOutParticipant>> signOutParticipantsProvider =
    Provider<List<SignOutParticipant>>(
      (ref) => [
        PlaybackSignOutParticipant(
          () => ref.read(playbackControllerProvider),
          () => playsWritten(ref.read(playbackControllerProvider)),
        ),
        SocketSignOutParticipant(ref.watch(socketClientProvider)),
        if (ref.watch(platformCapabilitiesProvider).canDownload)
          ref.watch(downloadsSignOutParticipantProvider),
      ],
      dependencies: [
        socketClientProvider,
        playbackControllerProvider,
        downloadsSignOutParticipantProvider,
      ],
    );
