// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// An [ImageProvider] that resolves synchronously, without a network call,
/// to a flat image of a colour chosen by [ref].
///
/// The colour is [palette] at the sum of the ref's code units modulo 8, so
/// it is stable across runs and platforms. Equality is by [ref].
@immutable
class PlaceholderImageProvider extends ImageProvider<PlaceholderImageProvider> {
  /// Creates the placeholder for the image named by [ref].
  const new(this.ref);

  /// The reference of the image this stands in for.
  final String ref;

  /// The eight colours a placeholder can have.
  static const List<Color> palette = [
    Color(0xFF1E40AF),
    Color(0xFFB91C1C),
    Color(0xFF047857),
    Color(0xFFB45309),
    Color(0xFF6D28D9),
    Color(0xFF0E7490),
    Color(0xFFBE185D),
    Color(0xFF4D7C0F),
  ];

  /// The colour of this placeholder.
  Color get color {
    var sum = 0;
    for (final unit in ref.codeUnits) {
      sum += unit;
    }
    return palette[sum % palette.length];
  }

  @override
  Future<PlaceholderImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    PlaceholderImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
        .drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = key.color);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    picture.dispose();
    return OneFrameImageStreamCompleter(
      SynchronousFuture(ImageInfo(image: image, debugLabel: key.ref)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlaceholderImageProvider && other.ref == ref;

  @override
  int get hashCode => ref.hashCode;

  @override
  String toString() => 'PlaceholderImageProvider($ref)';
}
