// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/domain.dart';

part 'podcast_detail.freezed.dart';

/// A subscribed podcast with its episodes, newest first as the server
/// orders them.
@freezed
abstract class PodcastDetail with _$PodcastDetail {
  /// Creates a podcast detail.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PodcastDetail({
    /// The podcast.
    required Podcast podcast,

    /// Its episodes, in server order.
    required List<Episode> episodes,
  }) = _PodcastDetail;
}
