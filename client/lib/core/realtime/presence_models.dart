// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:soundspan/shared/domain/track.dart';

/// What an online user is doing (doc 08, Social Presence).
enum PresenceStatus {
  /// Playing something.
  playing,

  /// Paused on something.
  paused,

  /// Neither playing nor paused, or not sharing what they play.
  idle,
}

/// A user of this server who is online and shares their presence.
@immutable
final class OnlineUser {
  /// Creates an online user.
  const new({
    required this.id,
    required this.displayName,
    required this.status,
    this.nowPlaying,
  });

  /// The user's id.
  final String id;

  /// The name the user goes by.
  final String displayName;

  /// What the user is doing.
  final PresenceStatus status;

  /// What the user plays, as display data; null when nothing is shared.
  final TrackMeta? nowPlaying;

  @override
  bool operator ==(Object other) =>
      other is OnlineUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.status == status &&
      other.nowPlaying == nowPlaying;

  @override
  int get hashCode => Object.hash(id, displayName, status, nowPlaying);
}

/// A user of a connected (federated) server who is online.
@immutable
final class OnlinePeerUser {
  /// Creates an online peer user.
  const new({
    required this.peerName,
    required this.displayName,
    required this.status,
    this.nowPlaying,
  });

  /// The name of the server the user is on.
  final String peerName;

  /// The name the user goes by.
  final String displayName;

  /// What the user is doing.
  final PresenceStatus status;

  /// What the user plays (title, artist and album only); null when nothing
  /// is shared.
  final TrackMeta? nowPlaying;

  @override
  bool operator ==(Object other) =>
      other is OnlinePeerUser &&
      other.peerName == peerName &&
      other.displayName == displayName &&
      other.status == status &&
      other.nowPlaying == nowPlaying;

  @override
  int get hashCode => Object.hash(peerName, displayName, status, nowPlaying);
}

/// Who is online: [users] of this server, without the current user, and
/// [peers] of connected servers.
@immutable
final class PresenceRoster {
  /// Creates a roster.
  const new({this.users = const [], this.peers = const []});

  /// Users of this server, in the server's order.
  final List<OnlineUser> users;

  /// Users of connected servers; empty without federation.
  final List<OnlinePeerUser> peers;

  @override
  bool operator ==(Object other) =>
      other is PresenceRoster &&
      listEquals(other.users, users) &&
      listEquals(other.peers, peers);

  @override
  int get hashCode => Object.hash(Object.hashAll(users), Object.hashAll(peers));
}
