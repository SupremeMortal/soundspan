// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/platform/deep_links/deep_links.dart';
import 'package:soundspan/shared/clock.dart';

final AppLogger _log = AppLogger.scope('DeepLink');

/// What a valid `soundspan://` link asks for.
@immutable
sealed class DeepLinkTarget {
  const new();
}

/// `soundspan://link?server=<url>[&code=<code>]`: add or open the server,
/// and link this device with [code] when there is one.
final class LinkDevice extends DeepLinkTarget {
  /// Creates the target.
  const new(this.server, this.code);

  /// The `server` parameter, as given.
  final String server;

  /// The device-link code, when the link has one.
  final DeviceLinkCode? code;

  @override
  bool operator ==(Object other) =>
      other is LinkDevice && other.server == server && other.code == code;

  @override
  int get hashCode => Object.hash(server, code);

  @override
  String toString() => 'LinkDevice($server, $code)';
}

/// `soundspan://album/<id>`.
final class OpenAlbum extends DeepLinkTarget {
  /// Creates the target.
  const new(this.id);

  /// The album id.
  final String id;

  @override
  bool operator ==(Object other) => other is OpenAlbum && other.id == id;

  @override
  int get hashCode => Object.hash(OpenAlbum, id);

  @override
  String toString() => 'OpenAlbum($id)';
}

/// `soundspan://artist/<id>`.
final class OpenArtist extends DeepLinkTarget {
  /// Creates the target.
  const new(this.id);

  /// The artist id.
  final String id;

  @override
  bool operator ==(Object other) => other is OpenArtist && other.id == id;

  @override
  int get hashCode => Object.hash(OpenArtist, id);

  @override
  String toString() => 'OpenArtist($id)';
}

/// `soundspan://playlist/<id>`.
final class OpenPlaylist extends DeepLinkTarget {
  /// Creates the target.
  const new(this.id);

  /// The playlist id.
  final String id;

  @override
  bool operator ==(Object other) => other is OpenPlaylist && other.id == id;

  @override
  int get hashCode => Object.hash(OpenPlaylist, id);

  @override
  String toString() => 'OpenPlaylist($id)';
}

/// The profiles a [DeepLinkRouter] looks at and switches between.
abstract interface class DeepLinkProfiles {
  /// Whether a profile is active.
  bool get hasActive;

  /// The id of the profile whose base URL is one of [candidates], or null.
  Future<String?> idForBaseUrl(List<Uri> candidates);

  /// Makes profile [profileId] the active one.
  Future<void> switchTo(String profileId);
}

/// [DeepLinkProfiles] over the [ProfileRuntime] and the stored profiles.
class RuntimeDeepLinkProfiles implements DeepLinkProfiles {
  /// Creates the profiles of [_runtime]; [_profiles] reads every profile.
  new(this._runtime, this._profiles);

  final ProfileRuntime _runtime;
  final Future<List<({String id, Uri baseUrl})>> Function() _profiles;

  @override
  bool get hasActive => _runtime.state.value is ProfileRuntimeActive;

  @override
  Future<String?> idForBaseUrl(List<Uri> candidates) async {
    for (final profile in await _profiles()) {
      if (candidates.contains(profile.baseUrl)) return profile.id;
    }
    return null;
  }

  @override
  Future<void> switchTo(String profileId) => _runtime.switchTo(profileId);
}

/// Validates every `soundspan://` link before it touches navigation (doc 10,
/// Deep Links Summary; doc 02, Routing).
class DeepLinkRouter {
  /// Creates the router that navigates [_router] in [_profiles].
  new({required this._router, required this._profiles, required this._clock});

  /// Links identical to the previous one within this window are handled
  /// once: some platforms deliver the launch link twice.
  static const Duration duplicateWindow = Duration(seconds: 2);

  /// The log message of an ignored link; its fields are the scheme and the
  /// host only.
  static const String ignoredMessage = 'Ignored an invalid deep link';

  static final RegExp _id = RegExp(r'^[A-Za-z0-9_.-]{1,128}$');

  final GoRouter _router;
  final DeepLinkProfiles _profiles;
  final Clock _clock;
  Uri? _last;
  DateTime? _lastAt;
  StreamSubscription<Uri>? _subscription;

  /// What [uri] asks for, or null when it is not a valid link.
  static DeepLinkTarget? parse(Uri uri) {
    if (uri.scheme.toLowerCase() != deepLinkScheme) return null;
    return switch (uri.host.toLowerCase()) {
      'link' => _parseLink(uri),
      'album' => _parseId(uri, OpenAlbum.new),
      'artist' => _parseId(uri, OpenArtist.new),
      'playlist' => _parseId(uri, OpenPlaylist.new),
      _ => null,
    };
  }

  static LinkDevice? _parseLink(Uri uri) {
    if (uri.path.isNotEmpty) return null;
    final Map<String, String> query;
    try {
      query = uri.queryParameters;
    } on FormatException {
      return null;
    }
    final server = query['server'];
    if (server == null) return null;
    try {
      if (ServerAddress.parse(server).candidates.isEmpty) return null;
    } on ServerAddressException {
      return null;
    }
    final rawCode = query['code'];
    if (rawCode == null) return LinkDevice(server, null);
    final code = DeviceLinkCode.tryParse(rawCode);
    return code == null ? null : LinkDevice(server, code);
  }

  static DeepLinkTarget? _parseId(
    Uri uri,
    DeepLinkTarget Function(String id) target,
  ) {
    if (uri.hasQuery) return null;
    // The raw path: a percent-encoded `/` must not become a separator, and
    // `%` is not an id character, so encoded ids are rejected outright.
    final path = uri.path;
    if (!path.startsWith('/')) return null;
    final id = path.substring(1);
    return _id.hasMatch(id) ? target(id) : null;
  }

  /// Handles [uri]: opens the probe, switches profile or opens a detail.
  /// An invalid link is ignored and logged without its query.
  Future<void> handle(Uri uri) async {
    final now = _clock.now();
    final last = _lastAt;
    if (uri == _last &&
        last != null &&
        now.difference(last) < duplicateWindow) {
      return;
    }
    _last = uri;
    _lastAt = now;

    final target = parse(uri);
    switch (target) {
      case null:
        _log.warning(ignoredMessage, {'scheme': uri.scheme, 'host': uri.host});
      case LinkDevice(:final server, :final code?):
        _probe(server, code);
      case LinkDevice(:final server, code: null):
        final address = ServerAddress.parse(server);
        final id = await _profiles.idForBaseUrl(address.candidates);
        if (id == null) {
          _probe(server, null);
        } else {
          await _profiles.switchTo(id);
        }
      case OpenAlbum(:final id):
        _open(DetailKind.album, id);
      case OpenArtist(:final id):
        _open(DetailKind.artist, id);
      case OpenPlaylist(:final id):
        _open(DetailKind.playlist, id);
    }
  }

  void _probe(String server, DeviceLinkCode? code) {
    // The probe carries the code to the device-link panel through
    // ServerAddress.linkCode.
    final input = code == null
        ? server
        : Uri(
            scheme: deepLinkScheme,
            host: 'link',
            queryParameters: {'code': code.value, 'server': server},
          ).toString();
    _router.go(
      RoutePaths.probe,
      extra: ProbeRequest(input: server, address: ServerAddress.parse(input)),
    );
  }

  void _open(DetailKind kind, String id) {
    // Without an active profile the guard already shows /connect.
    if (!_profiles.hasActive) return;
    DetailNavigation.openLocation(_router, '/${kind.name}/$id');
  }

  /// Handles [links]' initial link, then every later one, until [dispose].
  Future<void> listen(DeepLinks links) async {
    final initial = await links.initialLink();
    if (initial != null) await handle(initial);
    await _subscription?.cancel();
    _subscription = links.links.listen((uri) => unawaited(handle(uri)));
  }

  /// Stops listening.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

/// The app's [DeepLinkRouter] over the [routerProvider].
final Provider<DeepLinkRouter> deepLinkRouterProvider =
    Provider<DeepLinkRouter>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      final router = DeepLinkRouter(
        router: ref.watch(routerProvider),
        profiles: RuntimeDeepLinkProfiles(
          ref.watch(profileRuntimeProvider),
          () async => [
            for (final profile in await repository.watchAll().first)
              (id: profile.id, baseUrl: profile.baseUrl),
          ],
        ),
        clock: ref.watch(clockProvider),
      );
      ref.onDispose(() => unawaited(router.dispose()));
      return router;
    });

/// Start-up task (doc 02, Bootstrap Sequence, step 8): handles the link that
/// launched the app, then every later one.
Future<void> startDeepLinks(ProviderContainer root) =>
    root.read(deepLinkRouterProvider).listen(root.read(deepLinksProvider));
