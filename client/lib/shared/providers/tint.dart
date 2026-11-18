// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Backdrop tints for the detail headers (doc 09, Colour Tokens: Dynamic
/// backdrops). They live outside `data/` because `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/data/tint_extractor.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/images.dart';

export 'package:soundspan/shared/data/tint_extractor.dart' show TintExtractor;

/// The profile's [TintExtractor]: tints cached in its `cache.db`, computed
/// from a [tintSampleSize]-pixel copy of the cover. Tests override it.
final FutureProvider<TintExtractor> tintExtractorProvider =
    FutureProvider<TintExtractor>((ref) async {
      final images = ref.watch(artworkImageProvider);
      return CachedTintExtractor(
        await ref.watch(cacheStoreProvider.future),
        (artworkRef) => computeTint(
          images(
            ArtworkRequest(
              artworkRef,
              logicalPx: tintSampleSize.toDouble(),
              devicePixelRatio: 1,
            ),
          ),
        ),
      );
    }, dependencies: [cacheStoreProvider, artworkImageProvider]);

/// The tint of the cover named by the argument, or null when it has none.
final FutureProviderFamily<Color?, String> tintProvider =
    FutureProvider.family<Color?, String>((ref, artworkRef) async {
      final extractor = await ref.watch(tintExtractorProvider.future);
      return await extractor.tintOf(artworkRef);
    }, dependencies: [tintExtractorProvider]);
