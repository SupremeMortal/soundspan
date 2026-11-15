// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Writes the copy of the client-surface spec that the generator reads
/// (doc 03, Generated From the Server Specification).
///
/// The server emits a nullable reference as `{allOf: [{$ref}], nullable:
/// true}`. The generator ignores `nullable` there and declares the field
/// non-null, so a `null` the server is allowed to send fails to decode; it
/// reads nullability only from the referenced component. The copy marks a
/// component `nullable` when every reference to it is such a nullable
/// reference or the value of an optional property (already nullable in
/// Dart), which changes no Dart type. A component that is also referenced
/// from a required property, an array or elsewhere is left as it is. The
/// committed spec is untouched.
///
/// Run from the package root by `client/tool/gen.sh`:
///
///     dart run tool/normalize_spec.dart <input> <output>
library;

import 'dart:convert';
import 'dart:io';

const _componentPrefix = '#/components/schemas/';

/// [spec] with every component that is referenced only through nullable
/// single-reference `allOf` schemas or from optional properties, at least
/// once the former, marked `nullable: true`.
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

void _collect(
  Object? value,
  Set<String> nullableRefs,
  Set<String> plainRefs, {
  bool optionalProperty = false,
}) {
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
    _collectRest(value, nullableRefs, plainRefs);
    return;
  }
  // The value of an optional property is already nullable in Dart, so a
  // reference from it neither blocks nor needs the nullable mark.
  if (optionalProperty) {
    if (value[r'$ref'] is String) return;
    if (value
        case {'allOf': [{r'$ref': String()} && final Map<String, Object?> part]}
        when part.length == 1 && value['nullable'] == null) {
      _collectRest(value, nullableRefs, plainRefs);
      return;
    }
  }
  if (value[r'$ref'] case final String ref) plainRefs.add(ref);
  final required = switch (value['required']) {
    final List<Object?> names => names.toSet(),
    _ => const <Object?>{},
  };
  for (final MapEntry(:key, value: child) in value.entries) {
    if (key == 'properties' && child is Map<String, Object?>) {
      for (final MapEntry(key: name, value: property) in child.entries) {
        _collect(
          property,
          nullableRefs,
          plainRefs,
          optionalProperty: !required.contains(name),
        );
      }
    } else {
      _collect(child, nullableRefs, plainRefs);
    }
  }
}

/// Collects the references of [value]'s keys other than `allOf`.
void _collectRest(
  Map<String, Object?> value,
  Set<String> nullableRefs,
  Set<String> plainRefs,
) {
  for (final MapEntry(:key, :value) in value.entries) {
    if (key != 'allOf') _collect(value, nullableRefs, plainRefs);
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
