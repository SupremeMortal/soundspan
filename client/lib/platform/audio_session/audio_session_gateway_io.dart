// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';
import 'package:soundspan/platform/audio_session/audio_session_mapping.dart';

/// The native [AudioSessionGateway]: over `package:audio_session` on
/// Android, iOS and macOS; a no-op on Windows and Linux.
AudioSessionGateway createAudioSessionGateway() =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS
    ? PluginAudioSessionGateway()
    : const NoopAudioSessionGateway();

/// [AudioSessionGateway] over `package:audio_session`. The plugin's session
/// is opened on first use.
class PluginAudioSessionGateway implements AudioSessionGateway {
  /// Creates the gateway.
  new();

  Future<AudioSession>? _session;
  Stream<AudioSessionEvent>? _events;

  Future<AudioSession> get _instance => _session ??= AudioSession.instance;

  @override
  Future<void> configure(AudioFocusProfile profile) async {
    final session = await _instance;
    await session.configure(audioSessionConfigurationOf(profile));
  }

  @override
  Future<bool> setActive(bool active) async {
    final session = await _instance;
    return await session.setActive(active);
  }

  @override
  Stream<AudioSessionEvent> get events => _events ??= Stream.multi((listener) {
    StreamSubscription<AudioInterruptionEvent>? interruptions;
    StreamSubscription<void>? noisy;
    var cancelled = false;
    unawaited(
      _instance.then((session) {
        if (cancelled) return;
        interruptions = session.interruptionEventStream.listen(
          (event) => listener.add(audioSessionEventOf(event)),
        );
        noisy = session.becomingNoisyEventStream.listen(
          (_) => listener.add(const BecameNoisy()),
        );
      }),
    );
    listener.onCancel = () async {
      cancelled = true;
      await interruptions?.cancel();
      await noisy?.cancel();
    };
  }, isBroadcast: true);

  @override
  bool get osDucksItself => Platform.isAndroid;
}
