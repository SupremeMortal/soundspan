// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The audio-session seam (doc 02, Platform Seams; doc 06, Audio Focus and
/// Interruptions).
///
/// `createAudioSessionGateway` returns, on Android, iOS and macOS, a
/// gateway over `package:audio_session`; on Windows, Linux and web, one
/// that is always granted focus and reports no events.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway_web.dart'
    if (dart.library.io) 'package:soundspan/platform/audio_session/audio_session_gateway_io.dart';

export 'audio_session_gateway_web.dart'
    if (dart.library.io) 'audio_session_gateway_io.dart'
    show createAudioSessionGateway;

/// What the session plays, which decides how the OS treats it.
enum AudioFocusProfile {
  /// Music: tracks.
  music,

  /// Spoken word: podcast episodes.
  speech,
}

/// Something the OS did to the app's audio session.
@immutable
sealed class AudioSessionEvent {
  const new();
}

/// Another audio source took focus: a call, an alarm, another media app.
final class InterruptionBegan extends AudioSessionEvent {
  /// Creates the event.
  const new();

  @override
  bool operator ==(Object other) => other is InterruptionBegan;

  @override
  int get hashCode => (InterruptionBegan).hashCode;

  @override
  String toString() => 'InterruptionBegan()';
}

/// The interruption ended; [shouldResume] when the OS says playback may
/// resume.
final class InterruptionEnded extends AudioSessionEvent {
  /// Creates the event.
  const new({required this.shouldResume});

  /// Whether the OS allows playback to resume.
  final bool shouldResume;

  @override
  bool operator ==(Object other) =>
      other is InterruptionEnded && other.shouldResume == shouldResume;

  @override
  int get hashCode => Object.hash(InterruptionEnded, shouldResume);

  @override
  String toString() => 'InterruptionEnded(shouldResume: $shouldResume)';
}

/// Another source asked for focus for a moment, such as a navigation
/// prompt; playback may go on, more quietly.
final class DuckBegan extends AudioSessionEvent {
  /// Creates the event.
  const new();

  @override
  bool operator ==(Object other) => other is DuckBegan;

  @override
  int get hashCode => (DuckBegan).hashCode;

  @override
  String toString() => 'DuckBegan()';
}

/// The transient request that ducked playback ended.
final class DuckEnded extends AudioSessionEvent {
  /// Creates the event.
  const new();

  @override
  bool operator ==(Object other) => other is DuckEnded;

  @override
  int get hashCode => (DuckEnded).hashCode;

  @override
  String toString() => 'DuckEnded()';
}

/// The output became noisy: headphones were unplugged or a Bluetooth
/// device disconnected.
final class BecameNoisy extends AudioSessionEvent {
  /// Creates the event.
  const new();

  @override
  bool operator ==(Object other) => other is BecameNoisy;

  @override
  int get hashCode => (BecameNoisy).hashCode;

  @override
  String toString() => 'BecameNoisy()';
}

/// The app's audio session: its profile, its focus, and what the OS does
/// to it.
abstract interface class AudioSessionGateway {
  /// Configures the session for [profile].
  Future<void> configure(AudioFocusProfile profile);

  /// Asks for audio focus ([active]) or gives it up; false when focus is
  /// denied.
  Future<bool> setActive(bool active);

  /// What the OS does to the session.
  Stream<AudioSessionEvent> get events;

  /// Whether the OS lowers the app's volume itself for a transient request
  /// (Android); elsewhere the app ducks.
  bool get osDucksItself;
}

/// An [AudioSessionGateway] where the platform has no audio focus: focus
/// is always granted and nothing happens to the session (Windows, Linux,
/// web; doc 06: "Output device change on desktop: no action").
class NoopAudioSessionGateway implements AudioSessionGateway {
  /// Creates the gateway.
  const new();

  @override
  Future<void> configure(AudioFocusProfile profile) async {}

  @override
  Future<bool> setActive(bool active) async => true;

  @override
  Stream<AudioSessionEvent> get events => const Stream.empty();

  @override
  bool get osDucksItself => false;
}

/// The app's [AudioSessionGateway]; tests override it.
final Provider<AudioSessionGateway> audioSessionGatewayProvider =
    Provider<AudioSessionGateway>((ref) => createAudioSessionGateway());
