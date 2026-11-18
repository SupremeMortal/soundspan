// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/features/artist/artist.dart';
import 'package:soundspan/shared/providers/tint.dart';

import '../../features/detail_fixtures.dart';
import '../../helpers/fake_tint_extractor.dart';
import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'artist',
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: const ArtistScreen(artistId: 'ar-1'),
    ),
    overrides: [
      ...artistRepositories(fullArtistDetail()).overrides,
      tintExtractorProvider.overrideWithValue(
        AsyncData(FakeTintExtractor({'face-ar-1': const Color(0xFF0E7490)})),
      ),
    ],
  );
}
