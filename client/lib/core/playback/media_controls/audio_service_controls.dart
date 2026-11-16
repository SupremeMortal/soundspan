// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The `audio_service` adapter of the OS media controls (doc 06, OS Media
/// Controls): the Android notification and lock screen, Now Playing on iOS
/// and macOS, the Media Session API on the web and MPRIS on Linux.
///
/// It translates [MediaSessionState] into what `audio_service` shows and
/// its buttons into [MediaCommandHandler] calls; it holds no playback state
/// and owns no engine (Spike S3 finding). The plugin itself is started
/// through an [AudioServiceStarter], so everything here runs without it.
library;

import 'package:audio_service/audio_service.dart' as svc;
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/shared/clock.dart';

/// The Android notification channel of playback (doc 10, Playback
/// service).
const String playbackChannelId = 'io.soundspan.app.playback';

/// The MPRIS bus name prefix on Linux. `audio_service_mpris` requests
/// `<prefix>.instance<pid>`, built from the channel id it is given.
const String mprisBusNamePrefix = 'org.mpris.MediaPlayer2.$_mprisName';

/// The MPRIS player name: the channel id and the identity
/// `audio_service_mpris` derives from the config on Linux.
const String _mprisName = 'soundspan';

/// The skip interval the OS controls step by when they skip on their own.
const Duration _skipInterval = Duration(seconds: 15);

/// Starts `audio_service` with the handler [builder] makes and [config],
/// returning that handler. Called once per process.
typedef AudioServiceStarter = Future<SoundspanAudioHandler> Function(
  SoundspanAudioHandler Function() builder,
  svc.AudioServiceConfig config,
);

/// The `audio_service` configuration of [operatingSystem] (a value of
/// `Platform.operatingSystem`, or `web`).
///
/// [channelName] is the localized name of the Android notification channel.
/// On Linux `audio_service_mpris` derives the bus name from the channel id
/// and the MPRIS identity from the channel name, so both are `soundspan`
/// there.
svc.AudioServiceConfig audioServiceConfigFor({
  required String operatingSystem,
  required String channelName,
}) {
  final linux = operatingSystem == 'linux';
  return svc.AudioServiceConfig(
    androidNotificationChannelId: linux ? _mprisName : playbackChannelId,
    androidNotificationChannelName: linux ? _mprisName : channelName,
    // androidStopForegroundOnPause keeps its default, true, which an
    // ongoing notification requires.
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_stat_soundspan',
    fastForwardInterval: _skipInterval,
    rewindInterval: _skipInterval,
  );
}

/// The `audio_service` handler: every button is forwarded to [commands].
///
/// It holds no playback state; what it shows is published to it by
/// [AudioServiceControls.update]. `click` keeps its default, which pauses
/// or plays from the last published playing flag.
class SoundspanAudioHandler extends svc.BaseAudioHandler
    with svc.QueueHandler, svc.SeekHandler {
  /// Creates a handler forwarding to [commands].
  new(this.commands);

  /// Where the buttons go.
  final MediaCommandHandler commands;

  @override
  Future<void> play() => commands.play();

  @override
  Future<void> pause() => commands.pause();

  @override
  Future<void> stop() => commands.stop();

  @override
  Future<void> seek(Duration position) => commands.seek(position);

  @override
  Future<void> skipToNext() => commands.next();

  @override
  Future<void> skipToPrevious() => commands.previous();

  @override
  Future<void> fastForward() => commands.skipForward();

  @override
  Future<void> rewind() => commands.skipBackward();
}

/// What `audio_service` shows for [state]: the media item (null for
/// [MediaSessionState.empty]) and the playback state, positioned at
/// [updateTime].
///
/// The buttons are previous, play or pause, and next; an item with skip
/// actions and no next (a single episode) gets rewind and fast-forward in
/// place of previous and next. With both, the skips sit between them in
/// the expanded notification and previous, play/pause and next stay
/// compact.
(svc.MediaItem?, svc.PlaybackState) audioServiceStateOf(
  MediaSessionState state, {
  required DateTime updateTime,
}) {
  final id = state.queueItemId;
  if (id == null) {
    return (null, svc.PlaybackState(updateTime: updateTime));
  }
  final actions = state.actions;
  final skips =
      actions.contains(MediaAction.skipForward) ||
      actions.contains(MediaAction.skipBackward);
  final playPause = actions.contains(MediaAction.pause)
      ? svc.MediaControl.pause
      : actions.contains(MediaAction.play)
      ? svc.MediaControl.play
      : null;
  final previous = actions.contains(MediaAction.previous)
      ? svc.MediaControl.skipToPrevious
      : null;
  final next = actions.contains(MediaAction.next)
      ? svc.MediaControl.skipToNext
      : null;
  final rewind = actions.contains(MediaAction.skipBackward)
      ? svc.MediaControl.rewind
      : null;
  final forward = actions.contains(MediaAction.skipForward)
      ? svc.MediaControl.fastForward
      : null;
  final compact = <svc.MediaControl?>[
    if (skips && next == null) rewind else previous,
    playPause,
    if (skips && next == null) forward else next,
  ];
  final controls = <svc.MediaControl>[
    ?compact[0],
    if (skips && next != null) ?rewind,
    ?playPause,
    if (skips && next != null) ?forward,
    ?compact[2],
  ];
  final item = svc.MediaItem(
    id: id,
    title: state.title,
    artist: state.artist,
    album: state.album.isEmpty ? null : state.album,
    duration: state.duration,
    artUri: state.artworkUri,
  );
  return (
    item,
    svc.PlaybackState(
      processingState: state.buffering
          ? svc.AudioProcessingState.buffering
          : svc.AudioProcessingState.ready,
      playing: state.playing,
      controls: controls,
      androidCompactActionIndices: [
        for (final c in compact)
          if (c != null) controls.indexOf(c),
      ],
      systemActions: {
        if (actions.contains(MediaAction.seek)) svc.MediaAction.seek,
        if (actions.contains(MediaAction.stop)) svc.MediaAction.stop,
      },
      updatePosition: state.position,
      updateTime: updateTime,
      speed: state.speed,
    ),
  );
}

/// [MediaControls] over `audio_service`.
final class AudioServiceControls implements MediaControls {
  /// Creates the controls; `start` starts the plugin with `config` at
  /// [init], and `clock` stamps every published position.
  new({required this._config, required this._start, required this._clock});

  final svc.AudioServiceConfig Function() _config;
  final AudioServiceStarter _start;
  final Clock _clock;
  SoundspanAudioHandler? _handler;

  @override
  Future<void> init(MediaCommandHandler handler) async {
    _handler = await _start(() => SoundspanAudioHandler(handler), _config());
  }

  @override
  void update(MediaSessionState state) {
    final handler = _handler;
    if (handler == null) return;
    _publish(handler, state);
  }

  @override
  Future<void> dispose() async {
    final handler = _handler;
    _handler = null;
    if (handler != null) _publish(handler, MediaSessionState.empty);
  }

  void _publish(SoundspanAudioHandler handler, MediaSessionState state) {
    final (item, playback) = audioServiceStateOf(
      state,
      updateTime: _clock.now(),
    );
    handler.mediaItem.add(item);
    handler.playbackState.add(playback);
  }
}
