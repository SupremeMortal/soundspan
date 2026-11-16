// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/deep_link_router.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/features/connect/ui/address_screen.dart';
import 'package:soundspan/features/connect/ui/connect_layout.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/qr_scanner/qr_scanner.dart';

/// `/connect/scan`: scans the QR code of the web UI's device page (doc 04,
/// Device Link).
///
/// The scanner starts when the screen opens and stops when it closes or the
/// app leaves the foreground. A `soundspan://link` code goes to the
/// [DeepLinkRouter], which probes the server and carries the code to the
/// device-link panel; a plain `http(s)` address goes to `/connect/probe`.
/// Anything else shows a rejection for [rejectionDuration] and scanning
/// goes on. Without a camera or its permission the preview is replaced by
/// an explanation and "Enter the code instead".
class ScanScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  /// How long "That is not a soundspan code" stays up.
  static const Duration rejectionDuration = Duration(seconds: 3);

  /// The route redirect: `/connect` where the platform cannot scan.
  static String? redirect(BuildContext context, GoRouterState state) =>
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(platformCapabilitiesProvider).canScanQr
      ? null
      : RoutePaths.connect;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  late final QrScanner _scanner;
  late final StreamSubscription<String> _results;
  late final StreamSubscription<QrScannerError> _errors;
  QrScannerError? _error;
  bool _done = false;
  bool _rejecting = false;
  String? _lastRejected;
  Timer? _rejection;

  @override
  void initState() {
    super.initState();
    _scanner = ref.read(qrScannerFactoryProvider)();
    _results = _scanner.results.listen(_onResult);
    _errors = _scanner.errors.listen(_onError);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_scanner.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rejection?.cancel();
    unawaited(_results.cancel());
    unawaited(_errors.cancel());
    unawaited(_scanner.stop().whenComplete(_scanner.dispose));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_done || _error != null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_scanner.start());
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        unawaited(_scanner.stop());
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _onError(QrScannerError error) {
    if (!mounted || _done) return;
    setState(() => _error = error);
  }

  void _onResult(String raw) {
    if (!mounted || _done) return;
    final uri = Uri.tryParse(raw.trim());
    if (uri != null && DeepLinkRouter.parse(uri) is LinkDevice) {
      _finish();
      unawaited(ref.read(deepLinkRouterProvider).handle(uri));
      return;
    }
    final address = _webAddress(uri);
    if (address != null) {
      _finish();
      GoRouter.of(context).go(
        RoutePaths.probe,
        extra: ProbeRequest(input: raw.trim(), address: address),
      );
      return;
    }
    _reject(raw);
  }

  /// The server address of an absolute `http` or `https` [uri], or null.
  static ServerAddress? _webAddress(Uri? uri) {
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    try {
      final address = ServerAddress.parse(uri.toString());
      return address.candidates.isEmpty ? null : address;
    } on ServerAddressException {
      return null;
    }
  }

  void _finish() {
    _done = true;
    _rejection?.cancel();
    unawaited(_scanner.stop());
  }

  void _reject(String raw) {
    // The same code keeps arriving while it stays in view.
    if (raw == _lastRejected) return;
    _lastRejected = raw;
    _rejection?.cancel();
    _rejection = Timer(ScanScreen.rejectionDuration, () {
      if (mounted) setState(() => _rejecting = false);
    });
    setState(() => _rejecting = true);
  }

  void _enterCode() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.connect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return ConnectLayout(
      screen: l10n.screenConnectScan,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.connectAddressBack,
        onPressed: _enterCode,
      ),
      children: error == null
          ? [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.large),
                  child: _scanner.buildPreview(context),
                ),
              ),
              const SizedBox(height: Spacing.x16),
              _Line(
                _rejecting ? l10n.connectScanRejected : l10n.connectScanHint,
                color: _rejecting
                    ? context.colors.danger
                    : context.colors.contentBody,
                liveRegion: _rejecting,
              ),
            ]
          : [
              _Line(
                error == QrScannerError.permissionDenied
                    ? l10n.connectScanPermissionDenied
                    : l10n.connectScanNoCamera,
                color: context.colors.content,
              ),
              if (error == QrScannerError.permissionDenied) ...[
                const SizedBox(height: Spacing.x8),
                _Line(
                  l10n.connectScanAllowCamera,
                  color: context.colors.contentBody,
                ),
              ],
              const SizedBox(height: Spacing.x24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(Sizes.touchTarget),
                ),
                onPressed: _enterCode,
                child: Text(l10n.connectScanEnterCode),
              ),
            ],
    );
  }
}

/// A centred line of body text.
class _Line extends StatelessWidget {
  const new(this.text, {required this.color, this.liveRegion = false});

  final String text;
  final Color color;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: liveRegion,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.typography.body.copyWith(color: color),
    ),
  );
}
