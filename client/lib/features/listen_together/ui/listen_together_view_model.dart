// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/realtime/realtime_providers.dart';
import 'package:soundspan/core/realtime/socket_client.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/listen_together_controller.dart';
import 'package:soundspan/features/listen_together/listen_together_providers.dart';

/// The states of the profile's [ListenTogetherController]; the first is
/// the current one.
final StreamProvider<ListenTogetherState> listenTogetherStateProvider =
    StreamProvider<ListenTogetherState>(
      (ref) => ref.watch(listenTogetherControllerProvider).state,
      dependencies: [listenTogetherControllerProvider],
    );

/// Whether this device is in a Listen Together group: the playback
/// controller has a remote driver attached. Read from the playback state
/// alone, so surfaces that only mark the group (the avatar menu, the
/// sidebar) do not open the controller.
final Provider<bool> inListenTogetherGroupProvider = Provider<bool>(
  (ref) =>
      ref.watch(playbackControllerProvider.exists) &&
      ref.watch(
        playbackStateProvider.select(
          (snapshot) => snapshot.value?.remoteAttached ?? false,
        ),
      ),
  dependencies: [playbackControllerProvider, playbackStateProvider],
);

/// The group this device is in while the playback controller is attached
/// to it, else null. The controller is read only while attached.
final Provider<ListenTogetherActive?>
attachedListenTogetherProvider = Provider<ListenTogetherActive?>((ref) {
  if (!ref.watch(inListenTogetherGroupProvider)) return null;
  return switch (ref.watch(listenTogetherStateProvider).value) {
    final ListenTogetherActive active => active,
    _ => null,
  };
}, dependencies: [inListenTogetherGroupProvider, listenTogetherStateProvider]);

/// Whether a command matching [test] is awaiting its acknowledgement in
/// the attached group.
bool isGroupCommandPending(
  ListenTogetherActive? group,
  bool Function(PlaybackCommand command) test,
) => group?.pending.any(test) ?? false;

/// Whether [command] is a play, pause or toggle command.
bool isPlayPauseCommand(PlaybackCommand command) =>
    command is PlayCommand ||
    command is PauseCommand ||
    command is TogglePlayPauseCommand ||
    command is StopCommand;

/// What the Listen Together lobby lists: the group the user is a member
/// of, if any, and the public groups.
typedef ListenTogetherLobby = ({Group? mine, List<GroupSummary> discover});

/// The lobby's groups, from `GET /listen-together/mine` and
/// `GET /listen-together/discover`.
final FutureProvider<ListenTogetherLobby> listenTogetherLobbyProvider =
    FutureProvider<ListenTogetherLobby>((ref) async {
      final repository = ref.watch(listenTogetherRepositoryProvider);
      final (mine, discover) = await (
        repository.mine(),
        repository.discover(),
      ).wait;
      return (mine: mine, discover: discover);
    }, dependencies: [listenTogetherRepositoryProvider]);

/// The state of the Listen Together socket's connection.
final StreamProvider<SocketConnectionState> listenTogetherConnectionProvider =
    StreamProvider<SocketConnectionState>((ref) {
      final socket = ref.watch(socketClientProvider);
      return Stream<SocketConnectionState>.multi((listener) {
        listener.add(socket.connectionState);
        final subscription = socket.connectionStates.listen(
          listener.add,
          onDone: listener.close,
        );
        listener.onCancel = subscription.cancel;
      });
    }, dependencies: [socketClientProvider]);
