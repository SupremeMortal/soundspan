// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/media_controls/media_controls.dart';

/// A [MediaCommandHandler] that records the commands it receives, by name
/// (`seek` with its position in milliseconds, `setLiked` with its value).
class RecordingMediaCommandHandler implements MediaCommandHandler {
  /// The commands received, in order.
  final List<String> calls = [];

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> previous() async => calls.add('previous');

  @override
  Future<void> seek(Duration position) async =>
      calls.add('seek ${position.inMilliseconds}');

  @override
  Future<void> skipForward() async => calls.add('skipForward');

  @override
  Future<void> skipBackward() async => calls.add('skipBackward');

  @override
  Future<void> setLiked(bool liked) async => calls.add('setLiked $liked');
}
