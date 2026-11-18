// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'mix_detail.freezed.dart';
part 'mix_detail.g.dart';

/// A generated mix with its tracks, as its detail page shows it.
@freezed
abstract class MixDetail with _$MixDetail {
  /// Creates a mix detail.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory MixDetail({
    /// The server's mix id.
    required String id,

    /// The mix name.
    required String name,

    /// The mix description; null when the server sends none.
    String? description,

    /// Values to pass to the cover-art endpoint; the first four make the
    /// mosaic.
    @Default(<String>[]) List<String> artworkRefs,

    /// The tracks in server order; a track without a `playbackId` is not
    /// playable.
    @Default(<Track>[]) List<Track> tracks,
  }) = _MixDetail;

  /// Decodes a mix written by [MixDetail.toJson].
  factory fromJson(Map<String, Object?> json) => _$MixDetailFromJson(json);
}
