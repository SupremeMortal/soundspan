// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';

/// An [AudioSessionGateway] that records every call and whose events and
/// focus answers a test scripts.
class FakeAudioSessionGateway implements AudioSessionGateway {
  /// Creates the gateway; [osDucksItself] as on Android when true.
  new({this.osDucksItself = false});

  final StreamController<AudioSessionEvent> _events =
      StreamController<AudioSessionEvent>.broadcast(sync: true);

  @override
  final bool osDucksItself;

  /// What [setActive] answers when asked for focus.
  bool grantFocus = true;

  /// Every call, as `configure(music)`, `setActive(true)`.
  final List<String> calls = [];

  /// Whether focus is held: the last [setActive] asked for it and got it.
  bool active = false;

  @override
  Future<void> configure(AudioFocusProfile profile) async {
    calls.add('configure(${profile.name})');
  }

  @override
  Future<bool> setActive(bool active) async {
    calls.add('setActive($active)');
    if (!active) {
      this.active = false;
      return true;
    }
    this.active = grantFocus;
    return grantFocus;
  }

  @override
  Stream<AudioSessionEvent> get events => _events.stream;

  /// Delivers [event] as the OS would.
  void emit(AudioSessionEvent event) => _events.add(event);
}
