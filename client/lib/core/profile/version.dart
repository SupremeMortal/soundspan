// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable, listEquals;

/// A semantic version, `major.minor.patch` with an optional pre-release
/// (doc 04, Capability Discovery and Version Gate).
///
/// A leading `v` and build metadata are accepted and ignored. A
/// pre-release compares lower than its release, and pre-release identifiers
/// compare as semver specifies: numeric ones numerically and lower than
/// alphanumeric ones, which compare in ASCII order; a longer list wins when
/// all shared identifiers are equal.
@immutable
final class Version implements Comparable<Version> {
  const new _(this.major, this.minor, this.patch, this.preRelease);

  static final RegExp _pattern = RegExp(
    r'^[vV]?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-((?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
  );

  /// The version [text] names, or null when it is not a semantic version.
  static Version? tryParse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final major = int.tryParse(match[1]!);
    final minor = int.tryParse(match[2]!);
    final patch = int.tryParse(match[3]!);
    if (major == null || minor == null || patch == null) return null;
    final pre = match[4];
    return Version._(
      major,
      minor,
      patch,
      List.unmodifiable(pre == null ? const <String>[] : pre.split('.')),
    );
  }

  /// The major version.
  final int major;

  /// The minor version.
  final int minor;

  /// The patch version.
  final int patch;

  /// The pre-release identifiers; empty for a release.
  final List<String> preRelease;

  /// Whether this is a pre-release.
  bool get isPreRelease => preRelease.isNotEmpty;

  @override
  int compareTo(Version other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (a != b) return a.compareTo(b);
    }
    if (preRelease.isEmpty || other.preRelease.isEmpty) {
      return other.preRelease.length.sign - preRelease.length.sign;
    }
    final shared = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < shared; i++) {
      final order = _compareIdentifier(preRelease[i], other.preRelease[i]);
      if (order != 0) return order;
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  static int _compareIdentifier(String a, String b) {
    final x = int.tryParse(a);
    final y = int.tryParse(b);
    if (x != null && y != null) return x.compareTo(y);
    if (x != null) return -1;
    if (y != null) return 1;
    return a.compareTo(b);
  }

  /// Whether this version is lower than [other].
  bool operator <(Version other) => compareTo(other) < 0;

  /// Whether this version is higher than [other].
  bool operator >(Version other) => compareTo(other) > 0;

  /// Whether this version is lower than or equal to [other].
  bool operator <=(Version other) => compareTo(other) <= 0;

  /// Whether this version is higher than or equal to [other].
  bool operator >=(Version other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Version &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      listEquals(other.preRelease, preRelease);

  @override
  int get hashCode =>
      Object.hash(major, minor, patch, Object.hashAll(preRelease));

  /// The canonical form: `major.minor.patch[-pre.release]`.
  @override
  String toString() =>
      '$major.$minor.$patch${isPreRelease ? '-${preRelease.join('.')}' : ''}';
}
