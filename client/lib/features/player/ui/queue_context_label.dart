// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// What the queue header and the now-playing overline say the queue plays
/// from: "Radio · Rock" for a radio station; null for any other context,
/// which keeps their default text.
String? queueContextLabel(AppLocalizations l10n, QueueContext? context) =>
    switch (context) {
      QueueContext(kind: QueueContextKind.radio, :final title?) =>
        l10n.queueContextRadio(title),
      _ => null,
    };
