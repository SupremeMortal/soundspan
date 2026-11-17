// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

Map<String, bool> flags(PlatformCapabilities c) => {
  'canDownload': c.canDownload,
  'canScanQr': c.canScanQr,
  'hasTray': c.hasTray,
  'hasBackgroundPlayback': c.hasBackgroundPlayback,
  'supportsApiKeyStreaming': c.supportsApiKeyStreaming,
  'isDesktop': c.isDesktop,
  'allowsPublicCleartextHttp': c.allowsPublicCleartextHttp,
  'hasMobileData': c.hasMobileData,
  'hasSystemRoutePicker': c.hasSystemRoutePicker,
};

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Map<String, bool> on(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return flags(container.read(platformCapabilitiesProvider));
  }

  test('Android downloads, scans and plays in the background', () {
    expect(on(TargetPlatform.android), {
      'canDownload': true,
      'canScanQr': true,
      'hasTray': false,
      'hasBackgroundPlayback': true,
      'supportsApiKeyStreaming': true,
      'isDesktop': false,
      'allowsPublicCleartextHttp': true,
      'hasMobileData': true,
      'hasSystemRoutePicker': false,
    });
  });

  test('iOS blocks public cleartext HTTP and has the route picker', () {
    expect(on(TargetPlatform.iOS), {
      'canDownload': true,
      'canScanQr': true,
      'hasTray': false,
      'hasBackgroundPlayback': true,
      'supportsApiKeyStreaming': true,
      'isDesktop': false,
      'allowsPublicCleartextHttp': false,
      'hasMobileData': true,
      'hasSystemRoutePicker': true,
    });
  });

  test('macOS is a desktop without a tray and blocks public cleartext', () {
    expect(on(TargetPlatform.macOS), {
      'canDownload': true,
      'canScanQr': true,
      'hasTray': false,
      'hasBackgroundPlayback': true,
      'supportsApiKeyStreaming': true,
      'isDesktop': true,
      'allowsPublicCleartextHttp': false,
      'hasMobileData': false,
      'hasSystemRoutePicker': false,
    });
  });

  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    test('${platform.name} has a tray and no QR scanner', () {
      expect(on(platform), {
        'canDownload': true,
        'canScanQr': false,
        'hasTray': true,
        'hasBackgroundPlayback': true,
        'supportsApiKeyStreaming': true,
        'isDesktop': true,
        'allowsPublicCleartextHttp': true,
        'hasMobileData': false,
        'hasSystemRoutePicker': false,
      });
    });
  }

  test('web cannot download or stream with an API key', () {
    expect(flags(PlatformCapabilities.web), {
      'canDownload': false,
      'canScanQr': true,
      'hasTray': false,
      'hasBackgroundPlayback': false,
      'supportsApiKeyStreaming': false,
      'isDesktop': false,
      'allowsPublicCleartextHttp': true,
      'hasMobileData': false,
      'hasSystemRoutePicker': false,
    });
  });
}
