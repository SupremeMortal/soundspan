// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

/// One incompatibility between the current spec and the minServer snapshot.
class SpecBreak {
  /// Creates a break of [kind] in the operation [operationId].
  const new({
    required this.kind,
    required this.operationId,
    required this.detail,
  });

  /// `operation-removed`, `response-field-required` or `response-type-changed`.
  final String kind;

  /// The `operationId` the break belongs to.
  final String operationId;

  /// Where in the operation the break is and what changed.
  final String detail;

  @override
  String toString() => '$kind: $operationId: $detail';
}

const _methods = [
  'get',
  'put',
  'post',
  'delete',
  'options',
  'head',
  'patch',
  'trace',
];

/// Compares two parsed OpenAPI 3.0 documents.
///
/// A break is an operation of [minServer] that is missing or moved in
/// [current], a 2xx JSON response property that is required in [current] but
/// was optional or absent in [minServer], or a property whose `type` changed
/// or that went from nullable to non-nullable. Operations are matched by
/// `operationId` and schemas are compared structurally after resolving
/// `$ref`, so renaming a component is not a break.
List<SpecBreak> compareSpecs(
  Map<String, Object?> minServer,
  Map<String, Object?> current,
) {
  final minOps = _operations(minServer);
  final curOps = _operations(current);
  final breaks = <SpecBreak>[];
  for (final entry in minOps.entries) {
    final id = entry.key;
    final cur = curOps[id];
    if (cur == null) {
      breaks.add(
        SpecBreak(
          kind: 'operation-removed',
          operationId: id,
          detail: '${entry.value.label} is absent',
        ),
      );
    } else if (cur.label != entry.value.label) {
      breaks.add(
        SpecBreak(
          kind: 'operation-removed',
          operationId: id,
          detail: '${entry.value.label} is now ${cur.label}',
        ),
      );
    } else {
      _compareResponses(id, entry.value, cur, minServer, current, breaks);
    }
  }
  return breaks;
}

class _Operation {
  const new(this.method, this.path, this.body);
  final String method;
  final String path;
  final Map<String, Object?> body;
  String get label => '${method.toUpperCase()} $path';
}

Map<String, _Operation> _operations(Map<String, Object?> doc) {
  final result = <String, _Operation>{};
  final paths = doc['paths'];
  if (paths is! Map) return result;
  for (final MapEntry(key: path, value: item) in paths.entries) {
    if (item is! Map) continue;
    for (final method in _methods) {
      final op = item[method];
      if (op is! Map) continue;
      final id = op['operationId'];
      if (id is String) {
        result[id] = _Operation(method, path as String, op.cast());
      }
    }
  }
  return result;
}

void _compareResponses(
  String id,
  _Operation min,
  _Operation cur,
  Map<String, Object?> minDoc,
  Map<String, Object?> curDoc,
  List<SpecBreak> breaks,
) {
  final minResponses = min.body['responses'];
  final curResponses = cur.body['responses'];
  if (minResponses is! Map || curResponses is! Map) return;
  for (final MapEntry(key: status, value: minResponse)
      in minResponses.entries) {
    if (!'$status'.startsWith('2')) continue;
    final curResponse = curResponses[status];
    final minSchema = _jsonSchema(minResponse);
    final curSchema = _jsonSchema(curResponse);
    if (minSchema == null || curSchema == null) continue;
    _SchemaWalk(
      id,
      '$status',
      minDoc,
      curDoc,
      breaks,
    ).compare(minSchema, curSchema, '');
  }
}

Object? _jsonSchema(Object? response) {
  if (response is! Map) return null;
  final content = response['content'];
  if (content is! Map) return null;
  for (final MapEntry(key: type, value: media) in content.entries) {
    if ('$type'.contains('json') && media is Map) return media['schema'];
  }
  return null;
}

/// A schema with `$ref` resolved and `allOf` members merged.
class _Flat {
  final properties = <String, Object?>{};
  final required = <String>{};
  final alternatives = <Object?>[];
  String? type;
  bool nullable = false;
  Object? items;
  Object? additional;
}

class _SchemaWalk {
  new(this.id, this.status, this.minDoc, this.curDoc, this.breaks);

  final String id;
  final String status;
  final Map<String, Object?> minDoc;
  final Map<String, Object?> curDoc;
  final List<SpecBreak> breaks;
  final _seen = <String>{};

  void compare(Object? min, Object? cur, String at) {
    final key = '${identityHashCode(min)}:${identityHashCode(cur)}';
    if (!_seen.add(key)) return;
    final a = _flatten(min, minDoc);
    final b = _flatten(cur, curDoc);
    final aType = a.type;
    final bType = b.type;
    if (at.isNotEmpty && aType != null && bType != null && aType != bType) {
      _report('response-type-changed', at, 'type $aType became $bType');
      return;
    }
    for (final name in b.required) {
      if (!a.required.contains(name)) {
        final was = a.properties.containsKey(name) ? 'optional' : 'absent';
        _report(
          'response-field-required',
          _join(at, name),
          'required, was $was',
        );
      }
    }
    for (final MapEntry(key: name, value: curProperty)
        in b.properties.entries) {
      if (!a.properties.containsKey(name)) continue;
      final path = _join(at, name);
      final minProperty = a.properties[name];
      final minFlat = _flatten(minProperty, minDoc);
      final curFlat = _flatten(curProperty, curDoc);
      if (minFlat.type != null &&
          curFlat.type != null &&
          minFlat.type != curFlat.type) {
        _report(
          'response-type-changed',
          path,
          'type ${minFlat.type} became ${curFlat.type}',
        );
        continue;
      }
      if (minFlat.nullable && !curFlat.nullable) {
        _report('response-type-changed', path, 'nullable became non-nullable');
      }
      compare(minProperty, curProperty, path);
    }
    if (a.items != null && b.items != null) {
      compare(a.items, b.items, '$at[]');
    }
    if (a.additional != null && b.additional != null) {
      compare(a.additional, b.additional, '$at{}');
    }
    final shared = a.alternatives.length < b.alternatives.length
        ? a.alternatives.length
        : b.alternatives.length;
    for (var i = 0; i < shared; i++) {
      compare(a.alternatives[i], b.alternatives[i], '$at<$i>');
    }
  }

  void _report(String kind, String at, String detail) {
    breaks.add(
      SpecBreak(
        kind: kind,
        operationId: id,
        detail: '$status response ${at.isEmpty ? '(body)' : at}: $detail',
      ),
    );
  }

  static String _join(String at, String name) =>
      at.isEmpty ? name : '$at.$name';

  _Flat _flatten(
    Object? schema,
    Map<String, Object?> doc, [
    _Flat? into,
    int depth = 0,
  ]) {
    final flat = into ?? _Flat();
    if (schema is! Map || depth > 32) return flat;
    final ref = schema[r'$ref'];
    if (ref is String) {
      return _flatten(_resolve(ref, doc), doc, flat, depth + 1);
    }
    final all = schema['allOf'];
    if (all is List) {
      for (final member in all) {
        _flatten(member, doc, flat, depth + 1);
      }
    }
    final type = schema['type'];
    if (type is String) flat.type = type;
    if (schema['nullable'] == true) flat.nullable = true;
    final properties = schema['properties'];
    if (properties is Map) {
      for (final MapEntry(key: name, :value) in properties.entries) {
        flat.properties['$name'] = value;
      }
    }
    final required = schema['required'];
    if (required is List) flat.required.addAll(required.whereType<String>());
    if (schema['items'] != null) flat.items = schema['items'];
    final additional = schema['additionalProperties'];
    if (additional is Map) flat.additional = additional;
    for (final key in const ['oneOf', 'anyOf']) {
      final alternatives = schema[key];
      if (alternatives is List) flat.alternatives.addAll(alternatives);
    }
    return flat;
  }

  Object? _resolve(String ref, Map<String, Object?> doc) {
    if (!ref.startsWith('#/')) return null;
    Object? node = doc;
    for (final part in ref.substring(2).split('/')) {
      final key = part.replaceAll('~1', '/').replaceAll('~0', '~');
      if (node is! Map) return null;
      node = node[key];
    }
    return node;
  }
}

/// Reads the snapshot and the current spec, prints every break and sets the
/// exit code to 1 when there is any.
///
/// `--min` and `--current` override the default file locations.
void main(List<String> args) {
  var minPath = 'tool/specs/min-server.json';
  var currentPath = 'packages/soundspan_api/openapi/soundspan-client.json';
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--min' when i + 1 < args.length:
        minPath = args[++i];
      case '--current' when i + 1 < args.length:
        currentPath = args[++i];
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exitCode = 64;
        return;
    }
  }
  final breaks = compareSpecs(_read(minPath), _read(currentPath));
  if (breaks.isEmpty) {
    stdout.writeln('The current spec is compatible with $minPath.');
    return;
  }
  stdout.writeln(breaks.join('\n'));
  exitCode = 1;
}

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
