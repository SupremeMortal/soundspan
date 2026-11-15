// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Writes the copy of the client-surface spec that the generator reads
/// (doc 03, Generated From the Server Specification).
///
/// The server emits a nullable reference as `{allOf: [{$ref}], nullable:
/// true}`. The generator ignores `nullable` there and declares the field
/// non-null, so a `null` the server is allowed to send fails to decode; it
/// reads nullability only from the referenced component. The copy marks a
/// component `nullable` when every reference to it is such a nullable
/// reference, which changes no other field. A component that is also
/// referenced without `nullable` is left as it is. The committed spec is
/// untouched.
///
/// Run from the package root by `client/tool/gen.sh`:
///
///     dart run tool/normalize_spec.dart <input> <output>
library;

import 'dart:convert';
import 'dart:io';

const _componentPrefix = '#/components/schemas/';

/// [spec] with every component that is referenced only through nullable
/// single-reference `allOf` schemas marked `nullable: true`.
Map<String, Object?> normalizeSpec(Map<String, Object?> spec) {
  final nullableRefs = <String>{};
  final plainRefs = <String>{};
  _collect(spec, nullableRefs, plainRefs);
  final onlyNullable = nullableRefs.difference(plainRefs);
  final components = spec['components'];
  if (components is! Map<String, Object?>) return spec;
  final schemas = components['schemas'];
  if (schemas is! Map<String, Object?>) return spec;
  return {
    ...spec,
    'components': {
      ...components,
      'schemas': {
        for (final MapEntry(:key, :value) in schemas.entries)
          key:
              onlyNullable.contains('$_componentPrefix$key') &&
                  value is Map<String, Object?>
              ? {...value, 'nullable': true}
              : value,
      },
    },
  };
}

void _collect(Object? value, Set<String> nullableRefs, Set<String> plainRefs) {
  if (value is List<Object?>) {
    for (final item in value) {
      _collect(item, nullableRefs, plainRefs);
    }
    return;
  }
  if (value is! Map<String, Object?>) return;
  if (value
      case {
        'nullable': true,
        'allOf': [
          {r'$ref': final String ref} && final Map<String, Object?> part,
        ],
      }
      when part.length == 1) {
    nullableRefs.add(ref);
    for (final MapEntry(:key, :value) in value.entries) {
      if (key != 'allOf') _collect(value, nullableRefs, plainRefs);
    }
    return;
  }
  if (value[r'$ref'] case final String ref) plainRefs.add(ref);
  for (final child in value.values) {
    _collect(child, nullableRefs, plainRefs);
  }
}

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln('usage: dart run tool/normalize_spec.dart <input> <output>');
    exit(64);
  }
  final spec = jsonDecode(File(arguments[0]).readAsStringSync());
  File(arguments[1]).writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert(normalizeSpec(spec as Map<String, Object?>)),
  );
}
