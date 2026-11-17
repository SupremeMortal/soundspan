// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/media_controls/smtc_gateway.dart';
import 'package:soundspan_smtc/soundspan_smtc.dart';

/// The [SmtcGateway] of Windows: the in-repo C++/WinRT plugin
/// `soundspan_smtc` (doc 06, Spike S4 finding).
final class WindowsSmtcGateway implements SmtcGateway {
  /// Creates the gateway; nothing reaches the platform until [init].
  new() : _smtc = SoundspanSmtc();

  final SoundspanSmtc _smtc;

  static final Map<String, SmtcButton> _buttons = {
    for (final button in SmtcButton.values) button.name: button,
  };

  @override
  Future<void> init() => _smtc.initialize();

  @override
  Stream<SmtcButton> get buttonPresses => _smtc.events
      .map((e) => e is SmtcButtonEvent ? _buttons[e.button] : null)
      .where((b) => b != null)
      .cast<SmtcButton>();

  @override
  Stream<Duration> get seekRequests => _smtc.events
      .map((e) => e is SmtcSeekEvent ? e.position : null)
      .where((p) => p != null)
      .cast<Duration>();

  @override
  Future<void> setEnabledButtons(Set<SmtcButton> buttons) => _smtc.setButtons(
    play: buttons.contains(SmtcButton.play),
    pause: buttons.contains(SmtcButton.pause),
    next: buttons.contains(SmtcButton.next),
    previous: buttons.contains(SmtcButton.previous),
    stop: buttons.contains(SmtcButton.stop),
    fastForward: buttons.contains(SmtcButton.fastForward),
    rewind: buttons.contains(SmtcButton.rewind),
  );

  @override
  Future<void> setMetadata({
    required String title,
    required String artist,
    required String album,
    Uri? thumbnail,
  }) => _smtc.setMetadata(
    title: title,
    artist: artist,
    album: album,
    thumbnailPath: thumbnail != null && thumbnail.isScheme('file')
        ? thumbnail.toFilePath(windows: true)
        : null,
  );

  @override
  Future<void> setStatus(SmtcStatus status) => _smtc.setStatus(status.name);

  @override
  Future<void> setTimeline({
    required Duration position,
    required Duration? duration,
  }) => _smtc.setTimeline(position: position, duration: duration);

  @override
  Future<void> clear() => _smtc.clear();

  @override
  Future<void> dispose() => _smtc.dispose();
}
