// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/media_controls/media_controls.dart';

/// [MediaControls] that record what they are given.
class FakeMediaControls implements MediaControls {
  /// The handler [init] was given, if any.
  MediaCommandHandler? handler;

  /// How many times [init] was called.
  int initCount = 0;

  /// Every state [update] was given, in order.
  final List<MediaSessionState> updates = [];

  /// Whether [dispose] was called.
  bool disposed = false;

  /// The last state given, or null before any.
  MediaSessionState? get last => updates.isEmpty ? null : updates.last;

  @override
  Future<void> init(MediaCommandHandler handler) async {
    initCount++;
    this.handler = handler;
  }

  @override
  void update(MediaSessionState state) => updates.add(state);

  @override
  Future<void> dispose() async => disposed = true;
}
