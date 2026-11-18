// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The track preferences the server confirmed in this profile session, by
/// `playbackId`.
///
/// The players show a queue entry's like through it: a queue holds the
/// track as it was queued, and the cache may hold no copy of a track played
/// from a radio, a mix or a catalogue search, so once a like leaves the
/// outbox only this record still knows it.
final class ConfirmedTrackPreferences {
  final Map<String, Preference> _values = {};
  final StreamController<String> _changes = StreamController.broadcast(
    sync: true,
  );

  /// The confirmed preference of [playbackId], if any.
  Preference? operator [](String playbackId) => _values[playbackId];

  /// Records [preference] as the server's answer for [playbackId].
  void record(String playbackId, Preference preference) {
    if (_values[playbackId] == preference) return;
    _values[playbackId] = preference;
    if (!_changes.isClosed) _changes.add(playbackId);
  }

  /// The confirmed preference of [playbackId] now and on every change.
  Stream<Preference?> watch(String playbackId) =>
      Stream<Preference?>.multi((listener) {
        listener.add(_values[playbackId]);
        final sub = _changes.stream
            .where((id) => id == playbackId)
            .listen((_) => listener.add(_values[playbackId]));
        listener.onCancel = sub.cancel;
      });

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();
}

/// The profile's [ConfirmedTrackPreferences].
final Provider<ConfirmedTrackPreferences> confirmedTrackPreferencesProvider =
    Provider<ConfirmedTrackPreferences>((ref) {
      final confirmed = ConfirmedTrackPreferences();
      ref.onDispose(() => unawaited(confirmed.dispose()));
      return confirmed;
    }, dependencies: [profileContextProvider]);
