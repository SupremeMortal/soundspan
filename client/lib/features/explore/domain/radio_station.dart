// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';

part 'radio_station.freezed.dart';
part 'radio_station.g.dart';

/// A genre of the user's library that a radio station can play.
@freezed
abstract class RadioGenre with _$RadioGenre {
  /// Creates a genre.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RadioGenre({
    /// The genre as the server names it, which also selects the station.
    required String name,

    /// How many library tracks carry the genre.
    required int trackCount,
  }) = _RadioGenre;

  /// Decodes a genre written by [RadioGenre.toJson].
  factory fromJson(Map<String, Object?> json) => _$RadioGenreFromJson(json);
}

/// A decade of the user's library that a radio station can play.
@freezed
abstract class RadioDecade with _$RadioDecade {
  /// Creates a decade.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RadioDecade({
    /// The first year of the decade, such as 1990.
    required int decade,

    /// How many library tracks were released in the decade.
    required int trackCount,
  }) = _RadioDecade;

  /// Decodes a decade written by [RadioDecade.toJson].
  factory fromJson(Map<String, Object?> json) => _$RadioDecadeFromJson(json);
}

/// A radio station of Explore: a fresh selection of library tracks of one
/// genre ([GenreStation]) or one decade ([DecadeStation]).
@freezed
sealed class RadioStation with _$RadioStation {
  /// The station of the genre `name`, as [RadioGenre.name].
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RadioStation.genre(String name) = GenreStation;

  /// The station of the decade starting in `decade`, as
  /// [RadioDecade.decade].
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory RadioStation.decade(int decade) = DecadeStation;
}
