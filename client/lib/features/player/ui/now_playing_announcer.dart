// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// Announces the new queue entry politely while a screen reader is on:
/// "Now playing `title` by `artist`", or "`title`, `podcast`" for an
/// episode (doc 09, Accessibility).
///
/// Only a change of the current entry while playing is announced: not the
/// entry already current when it starts listening (the queue restored at
/// start-up), not a change while paused, and an entry once however often
/// it is paused and resumed.
class NowPlayingAnnouncer extends ConsumerStatefulWidget {
  /// Creates the announcer around [child].
  const new({required this.child, super.key});

  /// The shell.
  final Widget child;

  @override
  ConsumerState<NowPlayingAnnouncer> createState() =>
      _NowPlayingAnnouncerState();
}

class _NowPlayingAnnouncerState extends ConsumerState<NowPlayingAnnouncer> {
  /// Whether a snapshot was seen yet; the first one sets [_currentId].
  bool _seen = false;

  /// The queue entry current in the last snapshot.
  String? _currentId;

  void _onSnapshot(PlaybackSnapshot snapshot) {
    final current = snapshot.current;
    final id = current?.queueItemId;
    if (!_seen) {
      _seen = true;
      _currentId = id;
      return;
    }
    if (id == _currentId) return;
    _currentId = id;
    if (current == null ||
        !snapshot.playing ||
        !SemanticsBinding.instance.semanticsEnabled ||
        !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final message = switch (current) {
      TrackQueueItem(:final track) when track.meta.artist.isEmpty =>
        l10n.playerAnnounceTrackNoArtist(track.meta.title),
      TrackQueueItem(:final track) => l10n.playerAnnounceTrack(
        track.meta.title,
        track.meta.artist,
      ),
      EpisodeQueueItem(:final episode, :final podcast) =>
        l10n.playerAnnounceEpisode(episode.title, podcast.title),
    };
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(playbackStateProvider, (_, next) {
      if (next.value case final snapshot?) _onSnapshot(snapshot);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
