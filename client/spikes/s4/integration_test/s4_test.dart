// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Spike S4 harness (docs/designs/flutter-client/13-milestones-and-work-breakdown.md,
// Spikes, row S4). Every case prints one machine-readable `S4RESULT {json}`
// line; the workflow copies those lines into the job summary. A case fails
// only on a harness error, never on a "no" answer.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smtc_windows/smtc_windows.dart';

const _title = 'Spike S4 Title';
const _artist = 'Spike S4 Artist';
const _album = 'Spike S4 Album';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  SMTCWindows? smtc;
  final buttons = <String>[];
  StreamSubscription<PressedButton>? buttonSub;

  tearDownAll(() async {
    await buttonSub?.cancel();
    await smtc?.dispose();
    _emit('button_events', {'received': buttons});
  });

  testWidgets('initialises', (tester) async {
    final result = await _attempt(() async {
      await SMTCWindows.initialize();
      final s = SMTCWindows(
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: false,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      );
      smtc = s;
      buttonSub = s.buttonPressStream.listen((b) => buttons.add(b.name));
      await s.enableSmtc();
      await s.setIsPlayEnabled(true);
      await s.setIsPauseEnabled(true);
      await s.setIsNextEnabled(true);
      await s.setIsPrevEnabled(true);
      await s.setPlaybackStatus(PlaybackStatus.playing);
    });
    _emit('initialises', result);
  });

  testWidgets('accepts_metadata', (tester) async {
    final s = smtc;
    final result = s == null
        ? {'ok': false, 'error': 'not initialised'}
        : await _attempt(
            () => s.updateMetadata(
              const MusicMetadata(
                title: _title,
                artist: _artist,
                album: _album,
                albumArtist: _artist,
              ),
            ),
          );
    _emit('accepts_metadata', result);
  });

  testWidgets('accepts_timeline', (tester) async {
    final s = smtc;
    final result = s == null
        ? {'ok': false, 'error': 'not initialised'}
        : await _attempt(() async {
            await s.updateTimeline(
              const PlaybackTimeline(
                startTimeMs: 0,
                endTimeMs: 215000,
                positionMs: 42000,
                minSeekTimeMs: 0,
                maxSeekTimeMs: 215000,
              ),
            );
            await s.setPosition(const Duration(seconds: 43));
          });
    _emit('accepts_timeline', result);
  });

  testWidgets('accepts_thumbnail', (tester) async {
    final s = smtc;
    if (s == null) {
      _emit('accepts_thumbnail', {'ok': false, 'error': 'not initialised'});
      return;
    }
    // The design passes artwork as a local file URI (doc 06, OS Media
    // Controls), so the harness writes the bundled PNG to a file first.
    final bytes = await rootBundle.load('assets/cover.png');
    final dir = await Directory.systemTemp.createTemp('spike_s4');
    final file = File('${dir.path}${Platform.pathSeparator}cover.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    final uri = Uri.file(file.path).toString();
    final result = await _attempt(() async {
      await s.updateMetadata(
        MusicMetadata(
          title: _title,
          artist: _artist,
          album: _album,
          albumArtist: _artist,
          thumbnail: uri,
        ),
      );
      await s.setPlaybackStatus(PlaybackStatus.playing);
    });
    _emit('accepts_thumbnail', {...result, 'uri': uri});
  });

  testWidgets('system_reads_back_metadata', (tester) async {
    if (smtc == null) {
      _emit('system_reads_back_metadata', {
        'ok': false,
        'error': 'not initialised',
      });
      return;
    }
    Map<String, Object?> last = {'ok': false, 'error': 'no attempt'};
    // The system session manager picks the update up asynchronously.
    for (var attempt = 1; attempt <= 10; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      last = (await tester.runAsync(_readBack))!;
      last['attempt'] = attempt;
      final sessions = last['sessions'];
      if (sessions is List && sessions.any(_matches)) {
        break;
      }
    }
    final sessions = last['sessions'];
    final match = sessions is List
        ? sessions.cast<Object?>().firstWhere(_matches, orElse: () => null)
        : null;
    _emit('system_reads_back_metadata', {
      ...last,
      'readBackAvailable': last['ok'] == true,
      'matched': match != null,
      'match': match,
      'expected': {
        'title': _title,
        'artist': _artist,
        'playbackStatus': 'Playing',
      },
    });
  });
}

bool _matches(Object? session) =>
    session is Map &&
    session['title'] == _title &&
    session['artist'] == _artist &&
    session['playbackStatus'] == 'Playing';

Future<Map<String, Object?>> _attempt(Future<void> Function() body) async {
  final watch = Stopwatch()..start();
  try {
    await body();
    return {'ok': true, 'ms': watch.elapsedMilliseconds};
  } on Object catch (e) {
    return {
      'ok': false,
      'error': e.toString(),
      'ms': watch.elapsedMilliseconds,
    };
  }
}

// Reads the system's view of every media session through
// Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager.
// Windows PowerShell 5.1 (not pwsh) projects WinRT types.
const _readBackScript = r'''
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, [Type]$type) {
  $task = $asTaskGeneric.MakeGenericMethod($type).Invoke($null, @($op))
  $task.Wait(-1) | Out-Null
  $task.Result
}
[Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime] | Out-Null
[Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media.Control, ContentType = WindowsRuntime] | Out-Null
$manager = Await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
$current = $manager.GetCurrentSession()
$result = @()
foreach ($session in $manager.GetSessions()) {
  $props = Await ($session.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
  $info = $session.GetPlaybackInfo()
  $timeline = $session.GetTimelineProperties()
  $result += [pscustomobject]@{
    appId = $session.SourceAppUserModelId
    current = ($null -ne $current -and $current.SourceAppUserModelId -eq $session.SourceAppUserModelId)
    title = $props.Title
    artist = $props.Artist
    album = $props.AlbumTitle
    hasThumbnail = ($null -ne $props.Thumbnail)
    playbackStatus = $info.PlaybackStatus.ToString()
    positionMs = [int64]$timeline.Position.TotalMilliseconds
    endTimeMs = [int64]$timeline.EndTime.TotalMilliseconds
  }
}
ConvertTo-Json -Compress -Depth 4 -InputObject @($result)
''';

Future<Map<String, Object?>> _readBack() async {
  try {
    final r = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      _readBackScript,
    ]);
    final out = (r.stdout as String).trim();
    if (r.exitCode != 0 || out.isEmpty) {
      return {
        'ok': false,
        'exitCode': r.exitCode,
        'stdout': out,
        'stderr': (r.stderr as String).trim(),
      };
    }
    return {'ok': true, 'sessions': jsonDecode(out)};
  } on Object catch (e) {
    return {'ok': false, 'error': e.toString()};
  }
}

void _emit(String name, Map<String, Object?> data) {
  // ignore: avoid_print
  print('S4RESULT ${jsonEncode({'case': name, ...data})}');
}
