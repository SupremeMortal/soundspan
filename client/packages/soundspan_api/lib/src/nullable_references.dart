// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// JSON codecs for the nullable uses of components that are also used
/// non-null (doc 03, Generated From the Server Specification).
///
/// `tool/normalize_spec.dart` points each such nullable use at a
/// `Nullable<Component>` alias, and `swagger_parser.yaml` maps the alias
/// back to the component's generated Dart type through these functions, so
/// the field is `Component?` and decodes `null`. The models are exported
/// for the freezed part files of the generated models that use an alias
/// (`tool/import_nullable_references.dart`).
library;

import 'package:soundspan_api/src/generated/discovery/models/vibe_audio_features.dart';
import 'package:soundspan_api/src/generated/library/models/library_track.dart';

export 'package:soundspan_api/src/generated/discovery/models/vibe_audio_features.dart';
export 'package:soundspan_api/src/generated/library/models/library_track.dart';

/// A nullable use of `LibraryTrack`: the same type under the name the
/// generator configuration maps `NullableLibraryTrack` to.
typedef NullableLibraryTrack = LibraryTrack;

/// A nullable use of `VibeAudioFeatures`: the same type under the name the
/// generator configuration maps `NullableVibeAudioFeatures` to.
typedef NullableVibeAudioFeatures = VibeAudioFeatures;

/// Decodes the non-null JSON of a nullable `LibraryTrack` use.
LibraryTrack libraryTrackFromJson(Object? json) =>
    LibraryTrack.fromJson(json! as Map<String, Object?>);

/// Encodes a nullable `LibraryTrack` use that holds a value.
Map<String, Object?> libraryTrackToJson(LibraryTrack value) => value.toJson();

/// Decodes the non-null JSON of a nullable `VibeAudioFeatures` use.
VibeAudioFeatures vibeAudioFeaturesFromJson(Object? json) =>
    VibeAudioFeatures.fromJson(json! as Map<String, Object?>);

/// Encodes a nullable `VibeAudioFeatures` use that holds a value.
Map<String, Object?> vibeAudioFeaturesToJson(VibeAudioFeatures value) =>
    value.toJson();
