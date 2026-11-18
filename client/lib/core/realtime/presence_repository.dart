// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/realtime/presence_models.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The presence operations over the generated `SocialClient` (doc 03,
/// "Home, discovery, social"; doc 08, Social Presence).
///
/// A now-playing entry is display data only: title, artist, album, duration
/// and artwork reference.
class PresenceRepository {
  /// A repository over [_client] for the user [currentUserId], who is left
  /// out of every roster.
  new(this._client, {required this.currentUserId});

  final api.SocialClient _client;

  /// The id of the signed-in user.
  final String currentUserId;

  /// `POST /social/presence/heartbeat`: marks the user online.
  Future<void> heartbeat() async {
    await _client.sendPresenceHeartbeat();
  }

  /// `GET /social/online`: who is online, without the current user.
  ///
  /// `peers` is not declared by the client-surface spec, so it is read from
  /// the response's additional properties; an entry that does not have the
  /// expected shape is left out.
  Future<PresenceRoster> online() async {
    final response = await _client.listOnlineUsers();
    return PresenceRoster(
      users: [
        for (final user in response.users)
          if (user.id != currentUserId) _user(user),
      ],
      peers: _peers(response.additionalProperties['peers']),
    );
  }

  OnlineUser _user(api.OnlineUser user) => OnlineUser(
    id: user.id,
    displayName: user.displayName,
    status: switch (user.listeningStatus) {
      api.OnlineUserListeningStatusKnown(:final value) => switch (value) {
        api.OnlineUserListeningStatusValue.playing => PresenceStatus.playing,
        api.OnlineUserListeningStatusValue.paused => PresenceStatus.paused,
        api.OnlineUserListeningStatusValue.idle => PresenceStatus.idle,
      },
      _ => PresenceStatus.idle,
    },
    nowPlaying: switch (user.listeningTrack) {
      final track? => TrackMeta(
        title: track.title,
        artist: track.artistName,
        album: track.albumTitle,
        durationSec: track.duration.round(),
        artworkRef: track.coverArt,
      ),
      null => null,
    },
  );

  List<OnlinePeerUser> _peers(Object? value) {
    if (value is! List) return const [];
    return [
      for (final peer in value)
        if (peer case {
          'peerName': final String peerName,
          'users': final List<Object?> users,
        })
          for (final user in users) ?_peerUser(peerName, user),
    ];
  }

  OnlinePeerUser? _peerUser(String peerName, Object? user) {
    if (user case {
      'username': final String username,
      'status': final String status,
    }) {
      final displayName = switch (user['displayName']) {
        final String name when name.trim().isNotEmpty => name,
        _ => username,
      };
      final track = switch (user['track']) {
        {
          'title': final String title,
          'artist': final String artist,
          'album': final String album,
        } =>
          TrackMeta(title: title, artist: artist, album: album, durationSec: 0),
        _ => null,
      };
      return OnlinePeerUser(
        peerName: peerName,
        displayName: displayName,
        status: switch (status) {
          'playing' => PresenceStatus.playing,
          'paused' => PresenceStatus.paused,
          _ => PresenceStatus.idle,
        },
        nowPlaying: track,
      );
    }
    return null;
  }
}
