// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The downloads feature's public surface: the Downloads tab, the action
/// bar's Download button, the shared download actions and sheets, and the
/// providers and glyph mapping the rest of the UI reads (doc 07, doc 09).
library;

export 'package:soundspan/core/downloads/download_controller.dart'
    show CollectionSnapshot;
export 'package:soundspan/core/downloads/offline_models.dart'
    show CollectionKind;

export 'ui/collection_download_button.dart';
export 'ui/download_actions.dart';
export 'ui/download_glyph_mapper.dart';
export 'ui/download_providers.dart';
export 'ui/download_sheets.dart';
export 'ui/downloaded_only.dart';
export 'ui/downloads_tab.dart';
