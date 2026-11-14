// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Why [ServerAddress.parse] rejected an input.
enum ServerAddressError {
  /// The input is empty or only whitespace.
  empty,

  /// The input names a scheme other than `http` or `https`, or a
  /// `soundspan://` link other than `soundspan://link`.
  unsupportedScheme,

  /// The input is not a usable server address: user info, an empty host,
  /// whitespace or a reserved character in the host, or a bad port.
  invalid,

  /// A `soundspan://link` without a `server` parameter, or with an empty one.
  linkMissingServer,
}

/// Thrown by [ServerAddress.parse] for an input it cannot use.
class ServerAddressException implements Exception {
  /// Creates an exception for [error].
  const new(this.error);

  /// Why the input was rejected.
  final ServerAddressError error;

  @override
  String toString() => 'ServerAddressException(${error.name})';
}

/// A server address as typed, scanned or received in a deep link, turned
/// into the ordered base URLs to probe.
///
/// Pure Dart: it knows nothing of the network or the platform. Whether
/// [isPublicCleartext] is allowed is the caller's decision.
class ServerAddress {
  const new _({
    required this.candidates,
    required this.linkCode,
    required this.explicitScheme,
    required this.hasPrivateHost,
  });

  /// Normalizes [input] into candidate base URLs.
  ///
  /// Throws a [ServerAddressException] for input that cannot be used.
  factory parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const ServerAddressException(ServerAddressError.empty);
    }
    if (trimmed.toLowerCase().startsWith('soundspan:')) {
      final (server, code) = _parseLink(trimmed);
      return ServerAddress._address(server, linkCode: code);
    }
    return ServerAddress._address(trimmed, linkCode: null);
  }

  factory _address(String input, {required String? linkCode}) {
    var rest = input;
    String? scheme;
    final separator = rest.indexOf('://');
    if (separator >= 0) {
      scheme = rest.substring(0, separator).toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        throw const ServerAddressException(
          ServerAddressError.unsupportedScheme,
        );
      }
      rest = rest.substring(separator + 3);
    }

    final end = rest.indexOf(RegExp('[/?#]'));
    final authority = end < 0 ? rest : rest.substring(0, end);
    var path = end < 0 ? '' : rest.substring(end);
    final queryStart = path.indexOf(RegExp('[?#]'));
    if (queryStart >= 0) path = path.substring(0, queryStart);

    final (host, port, ipv6) = _splitAuthority(authority);
    final private = isPrivateHost(host);

    final schemes = scheme != null
        ? [scheme]
        : private
        ? const ['http', 'https']
        : const ['https'];
    final normalizedPath = _normalizePath(path);
    final hostPart = ipv6 ? '[$host]' : host;
    final candidates = [
      for (final s in schemes)
        Uri.parse(
          '$s://$hostPart'
          '${port == null || port == _defaultPorts[s] ? '' : ':$port'}'
          '$normalizedPath',
        ),
    ];
    return ServerAddress._(
      candidates: List.unmodifiable(candidates),
      linkCode: linkCode,
      explicitScheme: scheme != null,
      hasPrivateHost: private,
    );
  }

  /// The base URLs to try, in order. Never empty; none ends with `/`.
  final List<Uri> candidates;

  /// The `code` of a `soundspan://link`, verbatim; null for other input.
  final String? linkCode;

  /// Whether the address named `http://` or `https://` itself.
  final bool explicitScheme;

  /// Whether the host is private, as decided by [isPrivateHost].
  final bool hasPrivateHost;

  /// Whether the address explicitly asks for plain `http` to a public host.
  bool get isPublicCleartext =>
      explicitScheme && candidates.single.scheme == 'http' && !hasPrivateHost;

  /// Whether [host] is a LAN host: an IP literal in a private, loopback,
  /// link-local or carrier-grade NAT range, a name ending in `.local`,
  /// `.lan`, `.home.arpa` or `.internal`, or a single-label name.
  ///
  /// An IPv6 literal may be given with or without brackets.
  static bool isPrivateHost(String host) {
    var name = host.toLowerCase();
    if (name.startsWith('[') && name.endsWith(']')) {
      name = name.substring(1, name.length - 1);
    }
    if (name.contains(':')) {
      final bytes = _ipv6Bytes(name);
      return bytes != null && _isPrivateIpv6(bytes);
    }
    final ipv4 = _ipv4Bytes(name);
    if (ipv4 != null) return _isPrivateIpv4(ipv4);
    return !name.contains('.') ||
        _privateSuffixes.any((suffix) => name.endsWith(suffix));
  }

  /// The `server` and `code` parameters of a `soundspan://link`.
  static (String, String?) _parseLink(String input) {
    final Uri uri;
    try {
      uri = Uri.parse(input);
    } on FormatException {
      throw const ServerAddressException(ServerAddressError.invalid);
    }
    if (uri.host != 'link' || (uri.path.isNotEmpty && uri.path != '/')) {
      throw const ServerAddressException(ServerAddressError.unsupportedScheme);
    }
    final server = uri.queryParameters['server']?.trim() ?? '';
    if (server.isEmpty) {
      throw const ServerAddressException(ServerAddressError.linkMissingServer);
    }
    if (server.toLowerCase().startsWith('soundspan:')) {
      throw const ServerAddressException(ServerAddressError.unsupportedScheme);
    }
    return (server, uri.queryParameters['code']);
  }

  /// Splits [authority] into a lower-cased host (IPv6 without brackets), a
  /// port and whether the host is an IPv6 literal.
  static (String, int?, bool) _splitAuthority(String authority) {
    if (authority.contains('@') || authority.contains(RegExp(r'\s'))) {
      throw const ServerAddressException(ServerAddressError.invalid);
    }
    String host;
    String? port;
    var ipv6 = false;
    if (authority.startsWith('[')) {
      final close = authority.indexOf(']');
      if (close < 0) {
        throw const ServerAddressException(ServerAddressError.invalid);
      }
      host = authority.substring(1, close);
      final after = authority.substring(close + 1);
      if (after.isNotEmpty) {
        if (!after.startsWith(':')) {
          throw const ServerAddressException(ServerAddressError.invalid);
        }
        port = after.substring(1);
      }
      ipv6 = true;
    } else if (':'.allMatches(authority).length > 1) {
      host = authority;
      ipv6 = true;
    } else {
      final colon = authority.indexOf(':');
      host = colon < 0 ? authority : authority.substring(0, colon);
      port = colon < 0 ? null : authority.substring(colon + 1);
    }
    host = host.toLowerCase();
    if (host.isEmpty ||
        (ipv6 && _ipv6Bytes(host) == null) ||
        (!ipv6 && !_hostName.hasMatch(host))) {
      throw const ServerAddressException(ServerAddressError.invalid);
    }
    return (host, port == null ? null : _parsePort(port), ipv6);
  }

  static int _parsePort(String text) {
    final port = RegExp(r'^\d{1,5}$').hasMatch(text) ? int.parse(text) : 0;
    if (port < 1 || port > 65535) {
      throw const ServerAddressException(ServerAddressError.invalid);
    }
    return port;
  }

  /// Removes trailing slashes and one trailing lower-case `/api`.
  static String _normalizePath(String path) {
    var result = _trimSlashes(path);
    if (result.endsWith('/api')) {
      result = _trimSlashes(result.substring(0, result.length - 4));
    }
    return result;
  }

  static String _trimSlashes(String path) {
    var end = path.length;
    while (end > 0 && path[end - 1] == '/') {
      end--;
    }
    return path.substring(0, end);
  }

  static List<int>? _ipv4Bytes(String host) {
    final match = _ipv4.firstMatch(host);
    if (match == null) return null;
    final bytes = [for (var i = 1; i <= 4; i++) int.parse(match.group(i)!)];
    return bytes.every((b) => b <= 255) ? bytes : null;
  }

  static List<int>? _ipv6Bytes(String host) {
    try {
      return Uri.parseIPv6Address(host);
    } on FormatException {
      return null;
    }
  }

  static bool _isPrivateIpv4(List<int> b) =>
      b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168) ||
      b[0] == 127 ||
      (b[0] == 169 && b[1] == 254) ||
      (b[0] == 100 && b[1] >= 64 && b[1] <= 127);

  static bool _isPrivateIpv6(List<int> b) {
    final loopback = b.take(15).every((x) => x == 0) && b[15] == 1;
    final uniqueLocal = b[0] & 0xfe == 0xfc;
    final linkLocal = b[0] == 0xfe && b[1] & 0xc0 == 0x80;
    return loopback || uniqueLocal || linkLocal;
  }

  static final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
  static final _hostName = RegExp(r'^[^\s/\\?#@\[\]:%]+$');
  static const _privateSuffixes = ['.local', '.lan', '.home.arpa', '.internal'];
  static const _defaultPorts = {'http': 80, 'https': 443};
}
