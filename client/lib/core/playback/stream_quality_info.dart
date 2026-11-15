// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_quality_info.freezed.dart';

/// What the server streams for one track at one quality
/// (`GET /playback/stream-info/:playbackId`, doc 03).
@freezed
abstract class StreamQualityInfo with _$StreamQualityInfo {
  /// Creates stream information.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory StreamQualityInfo({
    /// The quality the server chose: `original`, `high`, `medium`, `low`,
    /// or a value a newer server added.
    required String quality,

    /// The MIME type of the stream, if known.
    String? contentType,

    /// The codec, if known.
    String? codec,

    /// The bit rate in kbit/s, if known.
    num? bitrate,

    /// The sample rate in Hz, if known.
    num? sampleRate,

    /// The bit depth, if known.
    num? bitDepth,

    /// The duration in milliseconds, if known.
    int? durationMs,

    /// The size of the stream in bytes, if known.
    int? contentLength,
  }) = _StreamQualityInfo;
}
