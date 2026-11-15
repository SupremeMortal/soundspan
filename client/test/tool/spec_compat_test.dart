// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:soundspan/app/build_config.dart';

import '../../tool/spec_compat.dart';

Map<String, Object?> _spec({
  Map<String, Object?>? schema,
  Map<String, Object?> schemas = const {},
  String path = '/items',
  String method = 'get',
  String id = 'listItems',
  Map<String, Object?>? requestSchema,
  Map<String, Object?> extraPaths = const {},
}) {
  return {
    'openapi': '3.0.0',
    'paths': {
      path: {
        method: {
          'operationId': id,
          'requestBody': ?requestSchema == null
              ? null
              : {
                  'content': {
                    'application/json': {'schema': requestSchema},
                  },
                },
          'responses': {
            '200': {
              'content': {
                'application/json': {
                  'schema': schema ?? _object({'a': _string}, required: ['a']),
                },
              },
            },
            '401': {
              'content': {
                'application/json': {
                  'schema': _object({'e': _string}, required: ['e']),
                },
              },
            },
          },
        },
      },
      ...extraPaths,
    },
    'components': {'schemas': schemas},
  };
}

const _string = {'type': 'string'};
const _integer = {'type': 'integer'};

Map<String, Object?> _object(
  Map<String, Object?> properties, {
  List<String> required = const [],
}) => {'type': 'object', 'properties': properties, 'required': required};

List<String> _kinds(Map<String, Object?> min, Map<String, Object?> cur) =>
    compareSpecs(min, cur).map((b) => b.kind).toList();

void main() {
  test('identical specs have no breaks', () {
    expect(compareSpecs(_spec(), _spec()), isEmpty);
  });

  test('an operation missing from current is operation-removed', () {
    final breaks = compareSpecs(_spec(), _spec(id: 'other'));
    expect(breaks.single.kind, 'operation-removed');
    expect(breaks.single.operationId, 'listItems');
  });

  test('an operation whose path or method changed is operation-removed', () {
    expect(_kinds(_spec(), _spec(path: '/things')), ['operation-removed']);
    expect(_kinds(_spec(), _spec(method: 'post')), ['operation-removed']);
  });

  test('a new operation is not a break', () {
    final cur = _spec(
      extraPaths: {
        '/new': {
          'get': {
            'operationId': 'newOp',
            'responses': {
              '200': {
                'content': {
                  'application/json': {
                    'schema': _object({'x': _string}, required: ['x']),
                  },
                },
              },
            },
          },
        },
      },
    );
    expect(compareSpecs(_spec(), cur), isEmpty);
  });

  test('a response property that became required is reported', () {
    final min = _spec(schema: _object({'a': _string}));
    final cur = _spec(schema: _object({'a': _string}, required: ['a']));
    final breaks = compareSpecs(min, cur);
    expect(breaks.single.kind, 'response-field-required');
    expect(breaks.single.detail, contains('a'));
  });

  test('a new required response property is reported', () {
    final min = _spec(schema: _object({'a': _string}, required: ['a']));
    final cur = _spec(
      schema: _object({'a': _string, 'b': _string}, required: ['a', 'b']),
    );
    expect(_kinds(min, cur), ['response-field-required']);
  });

  test('a new optional response property is not a break', () {
    final min = _spec(schema: _object({'a': _string}, required: ['a']));
    final cur = _spec(
      schema: _object({'a': _string, 'b': _string}, required: ['a']),
    );
    expect(compareSpecs(min, cur), isEmpty);
  });

  test('required properties behind a ref are reported', () {
    Map<String, Object?> spec({required bool required}) => _spec(
      schema: {r'$ref': '#/components/schemas/Item'},
      schemas: {
        'Item': _object({'a': _string}, required: required ? ['a'] : []),
      },
    );
    expect(_kinds(spec(required: false), spec(required: true)), [
      'response-field-required',
    ]);
  });

  test('required properties in a nested object are reported', () {
    Map<String, Object?> spec({required bool required}) => _spec(
      schema: _object({
        'inner': _object({'a': _string}, required: required ? ['a'] : []),
      }),
    );
    final breaks = compareSpecs(spec(required: false), spec(required: true));
    expect(breaks.single.kind, 'response-field-required');
    expect(breaks.single.detail, contains('inner.a'));
  });

  test('required properties inside array items are reported', () {
    Map<String, Object?> spec({required bool required}) => _spec(
      schema: {
        'type': 'array',
        'items': _object({'a': _string}, required: required ? ['a'] : []),
      },
    );
    expect(_kinds(spec(required: false), spec(required: true)), [
      'response-field-required',
    ]);
  });

  test('required properties in the second oneOf branch are reported', () {
    Map<String, Object?> spec({required bool required}) => _spec(
      schema: {
        'oneOf': [
          _object({'a': _string}, required: ['a']),
          _object({'b': _string}, required: required ? ['b'] : []),
        ],
      },
    );
    expect(_kinds(spec(required: false), spec(required: true)), [
      'response-field-required',
    ]);
  });

  test('a property whose type changed is reported', () {
    final min = _spec(schema: _object({'a': _string}, required: ['a']));
    final cur = _spec(schema: _object({'a': _integer}, required: ['a']));
    expect(_kinds(min, cur), ['response-type-changed']);
  });

  test('a nullable property that became non-nullable is reported', () {
    final min = _spec(
      schema: _object({
        'a': {'type': 'string', 'nullable': true},
      }),
    );
    final cur = _spec(schema: _object({'a': _string}));
    expect(_kinds(min, cur), ['response-type-changed']);
  });

  test('a new enum value is not a break', () {
    Map<String, Object?> spec(List<String> values) => _spec(
      schema: _object({
        'a': {'type': 'string', 'enum': values},
      }),
    );
    expect(compareSpecs(spec(['x']), spec(['x', 'y'])), isEmpty);
  });

  test('a renamed component with the same structure is not a break', () {
    final min = _spec(
      schema: {r'$ref': '#/components/schemas/Old'},
      schemas: {
        'Old': _object({'a': _string}, required: ['a']),
      },
    );
    final cur = _spec(
      schema: {r'$ref': '#/components/schemas/New'},
      schemas: {
        'New': _object({'a': _string}, required: ['a']),
      },
    );
    expect(compareSpecs(min, cur), isEmpty);
  });

  test('a request body property that became required is not a break', () {
    final min = _spec(requestSchema: _object({'a': _string}));
    final cur = _spec(requestSchema: _object({'a': _string}, required: ['a']));
    expect(compareSpecs(min, cur), isEmpty);
  });

  test('self-referencing schemas terminate', () {
    final schemas = {
      'Node': _object({
        'child': {r'$ref': '#/components/schemas/Node'},
      }),
    };
    final spec = _spec(
      schema: {r'$ref': '#/components/schemas/Node'},
      schemas: schemas,
    );
    expect(compareSpecs(spec, spec), isEmpty);
  });

  test('the real snapshot is compatible with the real current spec', () {
    Map<String, Object?> read(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    final breaks = compareSpecs(
      read('tool/specs/min-server.json'),
      read('packages/soundspan_api/openapi/soundspan-client.json'),
    );
    expect(breaks, isEmpty);
  });

  test('the snapshot is the spec of BuildConfig.minServer', () {
    final snapshot = jsonDecode(
      File('tool/specs/min-server.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final info = snapshot['info']! as Map<String, Object?>;
    expect(info['version'], BuildConfig.minServer);
  });
}
