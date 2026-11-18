// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/realtime/socket_client.dart'
    show SocketConnectionState;
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/listen_together_controller.dart';
import 'package:soundspan/features/listen_together/listen_together_providers.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The user the fake controller acts for.
const String me = 'u-me';

/// A track of a group queue titled [title].
Track groupTrack(String title) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist $title',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: PlaybackId('pb-$title'),
);

/// A group named [name] hosted by [hostUserId] with [members] (by default
/// the host "alex", this user "me" and "sam", who is not connected),
/// playing "Song one".
Group sampleGroup({
  String id = 'g1',
  String name = 'Road trip',
  String hostUserId = 'u-alex',
  GroupType type = GroupType.hostFollower,
  GroupVisibility visibility = GroupVisibility.private,
  List<GroupMember>? members,
}) => Group(
  id: id,
  name: name,
  joinCode: 'ABC123',
  type: type,
  visibility: visibility,
  hostUserId: hostUserId,
  members:
      members ??
      const [
        GroupMember(userId: 'u-alex', username: 'alex', isConnected: true),
        GroupMember(userId: me, username: 'me', isConnected: true),
        GroupMember(userId: 'u-sam', username: 'sam', isConnected: false),
      ],
  playback: GroupPlayback(
    queue: [groupTrack('Song one'), groupTrack('Song two')],
    currentIndex: 0,
    isPlaying: true,
    positionMs: 0,
    serverTime: 0,
    stateVersion: 1,
  ),
);

/// A public group as discovery lists it.
GroupSummary sampleSummary({
  String id = 'g2',
  String name = 'Jazz night',
  String host = 'kim',
  int members = 4,
}) => GroupSummary(
  id: id,
  name: name,
  joinCode: 'JAZZ42',
  type: GroupType.collaborative,
  visibility: GroupVisibility.public,
  hostUsername: host,
  memberCount: members,
  isMember: false,
  isPlaying: true,
);

/// The active state of [group]; this device controls playback unless it
/// is a follower of a host-follower group.
ListenTogetherActive activeOf(
  Group group, {
  Set<PlaybackCommand> pending = const {},
  GroupCommandError? error,
}) => ListenTogetherActive(
  group: group,
  offsetMs: 0,
  canControl: group.canControl(me),
  pending: pending,
  lastCommandError: error,
);

/// A [ListenTogetherController] whose state a test sets and whose calls it
/// reads back from [calls].
class FakeListenTogetherController extends Fake
    implements ListenTogetherController {
  /// Every call, as `create(<name>,<visibility>,<fromQueue>)`,
  /// `join(<code>)`, `leave` and `end`.
  final List<String> calls = [];

  /// What `joinByCode` and `createGroup` throw, when set.
  Exception? joinError;

  final StreamController<ListenTogetherState> _states =
      StreamController<ListenTogetherState>.broadcast(sync: true);
  ListenTogetherState _current = const ListenTogetherIdle();

  @override
  String get userId => me;

  @override
  ListenTogetherState get current => _current;

  @override
  Stream<ListenTogetherState> get state =>
      Stream<ListenTogetherState>.multi((listener) {
        listener.add(_current);
        final subscription = _states.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });

  /// Moves to [state].
  void emit(ListenTogetherState state) {
    _current = state;
    _states.add(state);
  }

  @override
  Future<void> createGroup({
    required GroupVisibility visibility,
    required bool fromCurrentQueue,
    String? name,
  }) async {
    calls.add('create($name,${visibility.name},$fromCurrentQueue)');
    if (joinError case final error?) throw error;
  }

  @override
  Future<void> joinByCode(String joinCode) async {
    calls.add('join($joinCode)');
    if (joinError case final error?) throw error;
  }

  @override
  Future<void> leave() async => calls.add('leave');

  @override
  Future<void> endGroup() async => calls.add('end');
}

/// A [ListenTogetherRepository] answering the lobby's two requests from
/// [myGroup] and [discovered], counting them in [loads].
class FakeListenTogetherRepository extends Fake
    implements ListenTogetherRepository {
  /// The user's group.
  Group? myGroup;

  /// The public groups.
  List<GroupSummary> discovered = const [];

  /// How many times the lobby was loaded.
  int loads = 0;

  @override
  Future<Group?> mine() async {
    loads++;
    return myGroup;
  }

  @override
  Future<List<GroupSummary>> discover() async => discovered;
}

/// The overrides that put [controller] and [repository] behind the
/// screen, with the socket [connection].
List<Override> listenTogetherOverrides(
  FakeListenTogetherController controller,
  FakeListenTogetherRepository repository, {
  SocketConnectionState connection = SocketConnectionState.connected,
}) => [
  listenTogetherControllerProvider.overrideWithValue(controller),
  listenTogetherRepositoryProvider.overrideWithValue(repository),
  listenTogetherConnectionProvider.overrideWith(
    (ref) => Stream.value(connection),
  ),
];
