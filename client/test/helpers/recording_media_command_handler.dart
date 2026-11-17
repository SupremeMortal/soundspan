// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';

/// A [MediaCommandHandler] that records the commands it receives, by name
/// (`seek` with its position in milliseconds, `setLiked` with its value,
/// `playRequest` with its start index); it has no browse source.
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

  @override
  MediaBrowseSource? get browseSource => null;

  @override
  Future<void> playRequest(PlayRequest request) async =>
      calls.add('playRequest ${request.startIndex}');
}
