// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/realtime/presence_controller.dart';
import 'package:soundspan/core/realtime/presence_models.dart';
import 'package:soundspan/shared/domain/track.dart';

/// A [PresenceController] whose state a test sets with [emit], and which
/// counts [open], [close] and [retry] calls.
final class FakePresenceController implements PresenceController {
  /// Starts in [initial].
  new([PresenceState initial = const PresenceState()]) : _state = initial;

  PresenceState _state;
  final StreamController<PresenceState> _states =
      StreamController<PresenceState>.broadcast(sync: true);

  /// How many times the panel or sheet opened.
  int opens = 0;

  /// How many times it closed.
  int closes = 0;

  /// How many times Retry was pressed.
  int retries = 0;

  @override
  PresenceState get state => _state;

  @override
  Stream<PresenceState> get states => _states.stream;

  @override
  DateTime? get lastHeartbeat => null;

  /// Moves to [state].
  void emit(PresenceState state) {
    _state = state;
    _states.add(state);
  }

  @override
  void open() => opens++;

  @override
  void close() => closes++;

  @override
  Future<void> retry() async => retries++;

  @override
  Future<void> dispose() async {}

  /// The override that puts this controller in the scope.
  Override get providerOverride =>
      presenceControllerProvider.overrideWithValue(this);
}

/// Capabilities with federation [federation].
final class FixedCapabilities extends ServerCapabilitiesNotifier {
  /// Creates capabilities with federation [federation].
  new({this.federation = false});

  /// Whether federation is on.
  final bool federation;

  @override
  ServerCapabilities build() => ServerCapabilities(
    serverVersion: null,
    hasP6SelfRevoke: true,
    hasP7PlayMarker: true,
    hasP8PlayedAt: true,
    federation: federation,
  );
}

/// The override for capabilities with federation [federation].
Override capabilitiesOverride({bool federation = false}) =>
    serverCapabilitiesProvider.overrideWith(
      () => FixedCapabilities(federation: federation),
    );

/// Three users: one playing, one paused, one idle.
const PresenceRoster threeUsers = PresenceRoster(
  users: [
    OnlineUser(
      id: 'a',
      displayName: 'Ana',
      status: PresenceStatus.playing,
      nowPlaying: TrackMeta(
        title: 'Blue Hour',
        artist: 'The Lanterns',
        album: 'Night Roads',
        durationSec: 200,
        artworkRef: 'art-a',
      ),
    ),
    OnlineUser(
      id: 'b',
      displayName: 'Ben',
      status: PresenceStatus.paused,
      nowPlaying: TrackMeta(
        title: 'Low Tide',
        artist: 'Harbour',
        album: 'Coast',
        durationSec: 180,
        artworkRef: 'art-b',
      ),
    ),
    OnlineUser(id: 'c', displayName: 'Cy', status: PresenceStatus.idle),
  ],
);

/// One user of a connected server.
const List<OnlinePeerUser> onePeer = [
  OnlinePeerUser(
    peerName: 'North',
    displayName: 'Nia',
    status: PresenceStatus.playing,
    nowPlaying: TrackMeta(
      title: 'Far',
      artist: 'Band',
      album: 'Away',
      durationSec: 0,
    ),
  ),
];

/// [threeUsers] and [onePeer].
final PresenceRoster threeUsersAndPeer = PresenceRoster(
  users: threeUsers.users,
  peers: onePeer,
);
