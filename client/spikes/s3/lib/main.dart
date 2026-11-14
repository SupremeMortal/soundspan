// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Spike S3 harness: the engine and its controller are created in the main
/// isolate by `main()`, outside the `audio_service` handler; the handler holds
/// no state and only forwards commands and mirrors the controller's state.
///
/// Every second the app writes one logcat line with tag `SPIKE_S3`; `run.sh`
/// reads those lines to answer the spike's questions.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final start = await _bumpStartCounter();
  final controller = SpikeController(AudioPlayer());
  await controller.load();
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await AudioService.init(
    builder: () => SpikeHandler(controller),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'io.soundspan.app.playback',
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_soundspan',
    ),
  );
  final reporter = _Reporter(controller, start)..engineCreated();
  Timer.periodic(const Duration(seconds: 1), (_) => reporter.tick());
  runApp(SpikeApp(controller));
}

/// Owns the engine, like `PlaybackController` in doc 06; nothing else calls
/// the player.
class SpikeController {
  /// Wraps [player].
  SpikeController(this.player);

  /// The single engine of the process.
  final AudioPlayer player;

  /// Loads the bundled tone on a loop.
  Future<void> load() async {
    await player.setLoopMode(LoopMode.one);
    await player.setAsset('assets/tone.wav');
  }

  /// Starts playback; the returned future of `AudioPlayer.play` is not awaited
  /// because it completes only when playback stops.
  Future<void> play() async {
    unawaited(player.play());
  }

  /// Pauses playback.
  Future<void> pause() => player.pause();

  /// Stops playback.
  Future<void> stop() => player.stop();

  /// Seeks within the tone.
  Future<void> seek(Duration position) => player.seek(position);
}

/// Holds no state of its own: forwards transport commands to the controller
/// and mirrors the controller's player state.
class SpikeHandler extends BaseAudioHandler with SeekHandler {
  /// Mirrors [controller] into `playbackState` and `mediaItem`.
  SpikeHandler(this.controller) {
    mediaItem.add(
      const MediaItem(id: 'tone', title: 'Spike S3 tone', artist: 'soundspan'),
    );
    controller.player.playbackEventStream.listen((_) => _mirror());
    controller.player.playingStream.listen((_) => _mirror());
  }

  /// The controller every command is forwarded to.
  final SpikeController controller;

  void _mirror() {
    final player = controller.player;
    playbackState.add(
      PlaybackState(
        controls: [
          if (player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0],
        processingState: switch (player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: player.playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ),
    );
  }

  @override
  Future<void> play() {
    _log('event=handler-play');
    return controller.play();
  }

  @override
  Future<void> pause() {
    _log('event=handler-pause');
    return controller.pause();
  }

  @override
  Future<void> stop() async {
    _log('event=handler-stop');
    await controller.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => controller.seek(position);
}

/// The spike's UI: a tap anywhere starts playback, so the driver has a way to
/// start it when no media button reaches the session.
class SpikeApp extends StatelessWidget {
  /// Creates the UI over [controller].
  const SpikeApp(this.controller, {super.key});

  /// The controller a tap starts.
  final SpikeController controller;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      _log('event=ui-play');
      unawaited(controller.play());
    },
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('Spike S3')),
    ),
  );
}

class _Reporter {
  _Reporter(this.controller, this.start);

  final SpikeController controller;
  final int start;
  String? _entry;
  int _ticks = 0;
  int _playedMs = 0;
  int? _lastPositionMs;

  void engineCreated() => _log('event=engine start=$start');

  void tick() {
    _ticks++;
    // An activity launch resumes the app within the first seconds; an engine
    // created by the playback service (media button) has no activity.
    if (_entry == null &&
        (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
            _ticks >= 3)) {
      _entry =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed
          ? 'activity'
          : 'service';
    }
    final player = controller.player;
    final positionMs = player.position.inMilliseconds;
    // The tone loops, so the position wraps; playedMs accumulates the
    // advance between ticks, adding one tone length across a wrap.
    final last = _lastPositionMs;
    if (last != null) {
      var delta = positionMs - last;
      if (delta < 0) delta += player.duration?.inMilliseconds ?? 0;
      _playedMs += delta;
    }
    _lastPositionMs = positionMs;
    _log(
      'event=tick start=$start playing=${player.playing} '
      'positionMs=$positionMs playedMs=$_playedMs '
      'entry=${_entry ?? 'pending'}',
    );
  }
}

Future<int> _bumpStartCounter() async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}/spike_s3_starts');
  final previous = file.existsSync()
      ? int.tryParse(file.readAsStringSync().trim()) ?? 0
      : 0;
  file.writeAsStringSync('${previous + 1}');
  return previous + 1;
}

/// Writes one logcat line with tag `SPIKE_S3` through the device's `log`
/// command, so the driver can filter by tag.
void _log(String message) {
  final line =
      'pid=$pid wallMs=${DateTime.now().millisecondsSinceEpoch} $message';
  unawaited(
    Process.run('/system/bin/log', [
      '-t',
      'SPIKE_S3',
      line,
    ]).then((_) {}, onError: (Object _) => debugPrint('SPIKE_S3 $line')),
  );
}
