// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/key_expiry_monitor.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';

/// The post-first-frame task that follows taps on local notifications: a
/// key-expiry notification opens the re-link flow of its profile (doc 04,
/// API-Key Expiry). Other payloads are ignored.
Future<void> startNotificationTaps(ProviderContainer root) async {
  root.read(localNotificationsProvider).taps.listen((payload) {
    final profileId = profileIdOfRelinkPayload(payload);
    if (profileId == null) return;
    root.read(routerProvider).go(relinkLocation(profileId));
  });
}

/// The key-expiry notification's text in [l10n].
KeyExpiryNotificationText keyExpiryNotificationText(AppLocalizations l10n) =>
    (days) => (
      title: l10n.keyExpiryNotificationTitle,
      body: l10n.keyExpiryNotificationBody(days),
    );
