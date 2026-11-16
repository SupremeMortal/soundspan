// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';

/// Lets a profile-scoped service take part in sign-out (doc 04, Sign-Out).
/// Registered through `signOutParticipantsProvider`; the order of the list
/// is the order of execution.
abstract interface class SignOutParticipant {
  /// Steps 1 and 2 of signing out: stop what uses the credential.
  Future<void> onSignOut({required bool removeDownloads});

  /// Extra work for "Remove this server", before the outbox flush.
  Future<void> beforeRemove();
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

/// The [SignOutParticipant]s of the profile scope, in execution order.
final Provider<List<SignOutParticipant>> signOutParticipantsProvider =
    Provider<List<SignOutParticipant>>(
      (ref) => [SocketSignOutParticipant(ref.watch(socketClientProvider))],
      dependencies: [socketClientProvider],
    );
