// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The colour a detail backdrop is tinted with, derived once per cover
/// (doc 09, Colour Tokens: Dynamic backdrops).
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:soundspan/app/theme/computed_color.dart';
import 'package:soundspan/shared/data/cache_store.dart';

/// Derives the backdrop tint of a cover.
abstract interface class TintExtractor {
  /// The tint of the cover [artworkRef], or null when it has none (the
  /// cover failed to load or has no pixels).
  Future<Color?> tintOf(String artworkRef);
}

/// Computes the tint of one cover; the uncached step of a
/// [CachedTintExtractor].
typedef TintComputer = Future<Color?> Function(String artworkRef);

/// The cache `blobs` key of the tint of [artworkRef].
String tintBlobKey(String artworkRef) => 'tint:$artworkRef';

/// A [TintExtractor] that keeps every tint it computes in the cache `blobs`
/// table under [tintBlobKey], so each cover is computed once.
///
/// A cover without a tint is not stored, so it is tried again next time.
class CachedTintExtractor implements TintExtractor {
  /// Reads and writes tints in [_store] and computes missing ones with
  /// [_compute].
  new(this._store, this._compute);

  final CacheStore _store;
  final TintComputer _compute;
  final Map<String, Future<Color?>> _inflight = {};

  @override
  Future<Color?> tintOf(String artworkRef) =>
      _inflight[artworkRef] ??= _read(artworkRef).whenComplete(() {
        unawaited(_inflight.remove(artworkRef));
      });

  Future<Color?> _read(String artworkRef) async {
    final key = tintBlobKey(artworkRef);
    final cached = await _store.readBlob<int>(key, (json) => json! as int);
    if (cached != null) return computedColor(cached.value);
    final tint = await _compute(artworkRef);
    if (tint != null) await _store.putBlob(key, tint.toARGB32());
    return tint;
  }
}

/// The edge, in pixels, of the copy of a cover a tint is computed from.
const int tintSampleSize = 64;

/// Computes the tint of the image [provider] gives: decodes a
/// [tintSampleSize]-pixel copy and quantises its pixels with
/// [dominantColor] in a background isolate.
///
/// Null when the image fails to load.
Future<Color?> computeTint(ImageProvider provider) async {
  final image = await _decode(
    ResizeImage(provider, width: tintSampleSize, height: tintSampleSize),
  );
  if (image == null) return null;
  try {
    final data = await image.toByteData();
    if (data == null) return null;
    final argb = await compute(dominantColor, data.buffer.asUint8List());
    return argb == null ? null : computedColor(argb);
  } finally {
    image.dispose();
  }
}

Future<ui.Image?> _decode(ImageProvider provider) {
  final completer = Completer<ui.Image?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image.clone());
      info.dispose();
      stream.removeListener(listener);
    },
    onError: (_, _) {
      if (!completer.isCompleted) completer.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

/// The dominant colour of [rgba] (straight RGBA bytes), as an opaque ARGB
/// value, or null when no pixel is opaque enough to count.
///
/// Pixels are grouped by the top four bits of each channel. Each group
/// scores its pixel count weighted by its chroma, so a colourful area wins
/// over a larger grey one; the result is the mean colour of the best group.
int? dominantColor(Uint8List rgba) {
  final counts = Int32List(4096);
  final sums = Int64List(4096 * 3);
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    final r = rgba[i];
    final g = rgba[i + 1];
    final b = rgba[i + 2];
    final bucket = (r >> 4) << 8 | (g >> 4) << 4 | b >> 4;
    counts[bucket]++;
    sums[bucket * 3] += r;
    sums[bucket * 3 + 1] += g;
    sums[bucket * 3 + 2] += b;
  }
  var best = -1;
  var bestScore = 0.0;
  for (var bucket = 0; bucket < counts.length; bucket++) {
    final count = counts[bucket];
    if (count == 0) continue;
    final r = bucket >> 8;
    final g = bucket >> 4 & 0xF;
    final b = bucket & 0xF;
    final max = [r, g, b].reduce((x, y) => x > y ? x : y);
    final min = [r, g, b].reduce((x, y) => x < y ? x : y);
    final score = count * (1 + (max - min) / 3);
    if (score > bestScore) {
      bestScore = score;
      best = bucket;
    }
  }
  if (best < 0) return null;
  final count = counts[best];
  final r = sums[best * 3] ~/ count;
  final g = sums[best * 3 + 1] ~/ count;
  final b = sums[best * 3 + 2] ~/ count;
  return 0xFF000000 | r << 16 | g << 8 | b;
}
