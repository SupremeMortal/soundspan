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
/// Dart), which changes no Dart type. A plain reference that is a whole
/// response body does not block the mark either: an operation that answers
/// `null` for a component another operation returns then decodes `null`,
/// and the other operation's return type becomes nullable. A component that
/// is also referenced from a required property, an array or elsewhere is
/// left as it is. The committed spec is untouched.
///
/// Run from the package root by `client/tool/gen.sh`:
///
///     dart run tool/normalize_spec.dart <input> <output>
library;

import 'dart:convert';
import 'dart:io';

const _componentPrefix = '#/components/schemas/';

/// [spec] with every component that is referenced only through nullable
/// single-reference `allOf` schemas, from optional properties or as a whole
/// response body, at least once the first, marked `nullable: true`.
Map<String, Object?> normalizeSpec(Map<String, Object?> spec) {
  final nullableRefs = <String>{};
  final plainRefs = <String>{};
  _collect(spec, nullableRefs, plainRefs);
  final onlyNullable = nullableRefs.difference(plainRefs);
  final mixed = nullableRefs.intersection(plainRefs);
  final components = spec['components'];
  if (components is! Map<String, Object?>) return spec;
  final schemas = components['schemas'];
  if (schemas is! Map<String, Object?>) return spec;
  final aliases = <String, String>{
    for (final ref in mixed)
      if (ref.startsWith(_componentPrefix) &&
          schemas[ref.substring(_componentPrefix.length)] is Map)
        ref:
            '$_componentPrefix${nullableAliasName(ref.substring(_componentPrefix.length))}',
  };
  for (final alias in aliases.values) {
    if (schemas.containsKey(alias.substring(_componentPrefix.length))) {
      throw StateError('The spec already has a component named $alias.');
    }
  }
  return {
    for (final MapEntry(:key, :value) in spec.entries)
      if (key != 'components') key: _rewrite(value, aliases),
    'components': {
      for (final MapEntry(:key, :value) in components.entries)
        if (key != 'schemas') key: value,
      'schemas': {
        for (final MapEntry(:key, :value) in schemas.entries)
          key:
              onlyNullable.contains('$_componentPrefix$key') &&
                  value is Map<String, Object?>
              ? {..._rewriteMap(value, aliases), 'nullable': true}
              : _rewrite(value, aliases),
        for (final MapEntry(key: ref, value: alias) in aliases.entries)
          alias.substring(_componentPrefix.length): {
            ...schemas[ref.substring(_componentPrefix.length)]!
                as Map<String, Object?>,
            'nullable': true,
          },
      },
    },
  };
}

/// The name of the component that stands for a nullable use of
/// [component] when [component] is also used non-null (doc 03). The
/// generator configuration maps it back to [component]'s Dart type.
String nullableAliasName(String component) => 'Nullable$component';

/// [value] with every nullable single-reference `allOf` schema whose target
/// is a key of [aliases] pointed at the alias instead.
Object? _rewrite(Object? value, Map<String, String> aliases) {
  if (aliases.isEmpty) return value;
  return switch (value) {
    final List<Object?> items => [
      for (final item in items) _rewrite(item, aliases),
    ],
    final Map<String, Object?> map => _rewriteMap(map, aliases),
    _ => value,
  };
}

Map<String, Object?> _rewriteMap(
  Map<String, Object?> value,
  Map<String, String> aliases,
) {
  if (aliases.isEmpty) return value;
  if (value
      case {
        'nullable': true,
        'allOf': [
          {r'$ref': final String ref} && final Map<String, Object?> part,
        ],
      }
      when part.length == 1 && aliases.containsKey(ref)) {
    return {
      for (final MapEntry(:key, value: child) in value.entries)
        key: key == 'allOf'
            ? [
                {r'$ref': aliases[ref]},
              ]
            : _rewrite(child, aliases),
    };
  }
  return {
    for (final MapEntry(:key, value: child) in value.entries)
      key: _rewrite(child, aliases),
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
    if (key == 'responses' && child is Map<String, Object?>) {
      for (final response in child.values) {
        _collectResponse(response, nullableRefs, plainRefs);
      }
    } else if (key == 'properties' && child is Map<String, Object?>) {
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

/// Collects the references of one response object of an operation. A body
/// schema that is a plain reference neither blocks nor needs the nullable
/// mark.
void _collectResponse(
  Object? response,
  Set<String> nullableRefs,
  Set<String> plainRefs,
) {
  if (response is! Map<String, Object?>) {
    _collect(response, nullableRefs, plainRefs);
    return;
  }
  for (final MapEntry(:key, value: child) in response.entries) {
    if (key == 'content' && child is Map<String, Object?>) {
      for (final media in child.values) {
        if (media case {'schema': {r'$ref': String()} && final schema}
            when schema.length == 1) {
          continue;
        }
        _collect(media, nullableRefs, plainRefs);
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
