// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Matching of requests against the spec's operations.
library;

/// Returns the key in [keys] (`METHOD /path/{param}`) that a request with
/// [method] to [path] belongs to, or null when none does.
///
/// A `{param}` segment of a template matches any one non-empty segment.
/// When several templates match, the one with the most literal segments
/// wins, so `/library/tracks/shuffle` beats `/library/tracks/{id}`.
String? matchOperation(Iterable<String> keys, String method, String path) {
  final verb = method.toUpperCase();
  final segments = path.split('/');
  String? best;
  var bestLiterals = -1;
  for (final key in keys) {
    final space = key.indexOf(' ');
    if (space < 0 || key.substring(0, space) != verb) continue;
    final template = key.substring(space + 1).split('/');
    if (template.length != segments.length) continue;
    var literals = 0;
    var matches = true;
    for (var i = 0; i < template.length; i++) {
      final part = template[i];
      if (part.startsWith('{') && part.endsWith('}')) {
        if (segments[i].isEmpty) matches = false;
      } else if (part == segments[i]) {
        literals++;
      } else {
        matches = false;
      }
      if (!matches) break;
    }
    if (matches && literals > bestLiterals) {
      best = key;
      bestLiterals = literals;
    }
  }
  return best;
}
