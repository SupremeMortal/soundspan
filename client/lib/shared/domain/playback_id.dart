// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:json_annotation/json_annotation.dart';

/// Opaque server identifier of a playable track (doc 02, Domain Model).
///
/// Never parsed: compared only for equality, and passed back to the server
/// as it was received.
extension type const PlaybackId(String value);

/// Serializes a [PlaybackId] as its string value.
final class PlaybackIdConverter implements JsonConverter<PlaybackId, String> {
  /// Creates the converter.
  const new();

  @override
  PlaybackId fromJson(String json) => PlaybackId(json);

  @override
  String toJson(PlaybackId object) => object.value;
}
