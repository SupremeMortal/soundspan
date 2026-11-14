// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Writes a copy of the client-surface spec with every
// `additionalProperties: false` removed, so the spike can compare a closed
// object (the construct the backend emits) with an open one.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final input = File(args[0]);
  final output = File(args[1])..parent.createSync(recursive: true);
  final spec = jsonDecode(input.readAsStringSync());
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(_open(spec)),
  );
}

Object? _open(Object? node) => switch (node) {
  final Map<String, Object?> map => {
    for (final entry in map.entries)
      if (!(entry.key == 'additionalProperties' && entry.value == false))
        entry.key: _open(entry.value),
  },
  final List<Object?> list => [for (final item in list) _open(item)],
  _ => node,
};
