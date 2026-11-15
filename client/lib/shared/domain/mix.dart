// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mix.freezed.dart';
part 'mix.g.dart';

/// A generated mix as the Home screen shows it.
@freezed
abstract class MixSummary with _$MixSummary {
  /// Creates a mix summary.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory MixSummary({
    /// The server's mix id.
    required String id,

    /// The mix name.
    required String name,

    /// The mix description.
    required String description,

    /// Values to pass to the cover-art endpoint, for the mosaic.
    @Default(<String>[]) List<String> coverRefs,
  }) = _MixSummary;

  /// Decodes a summary written by [MixSummary.toJson].
  factory fromJson(Map<String, Object?> json) => _$MixSummaryFromJson(json);
}
