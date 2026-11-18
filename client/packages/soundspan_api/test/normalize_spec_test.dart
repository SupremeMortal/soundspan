// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:test/test.dart';

import '../tool/normalize_spec.dart';

Map<String, Object?> _nullableRef(String name) => {
  'allOf': [
    {r'$ref': '#/components/schemas/$name'},
  ],
  'nullable': true,
};

Map<String, Object?> _ref(String name) => {
  r'$ref': '#/components/schemas/$name',
};

Map<String, Object?> _object() => {
  'type': 'object',
  'properties': {
    'id': {'type': 'string'},
  },
};

Map<String, Object?> _schemas(Map<String, Object?> spec) =>
    (spec['components']! as Map)['schemas']! as Map<String, Object?>;

void main() {
  test('a component referenced only through nullable allOf references is '
      'marked nullable', () {
    final spec = normalizeSpec({
      'paths': {
        '/a': {
          'get': {
            'responses': {
              '200': {
                'content': {
                  'application/json': {
                    'schema': {'type': 'array', 'items': _ref('Response')},
                  },
                },
              },
            },
          },
        },
      },
      'components': {
        'schemas': {
          'Response': {
            'type': 'object',
            'properties': {
              'cursor': _nullableRef('Cursor'),
              'other': _nullableRef('Cursor'),
            },
          },
          'Cursor': _object(),
        },
      },
    });

    expect(_schemas(spec)['Cursor'], {..._object(), 'nullable': true});
    expect(_schemas(spec)['Response'], isNot(contains('nullable')));
  });

  test('a component also referenced without nullable keeps its schema; '
      'its nullable uses move to an alias', () {
    final input = {
      'components': {
        'schemas': {
          'Item': {
            'type': 'object',
            'required': ['always'],
            'properties': {
              'maybe': _nullableRef('Track'),
              'always': _ref('Track'),
              'inArray': {'type': 'array', 'items': _ref('Peer')},
              'peer': _nullableRef('Peer'),
            },
          },
          'Track': _object(),
          'Peer': _object(),
        },
      },
    };

    final schemas = _schemas(normalizeSpec(input));
    expect(schemas['Track'], _object());
    expect(schemas['Peer'], _object());
    final item = schemas['Item']! as Map<String, Object?>;
    expect(item['properties'], {
      'maybe': _nullableRef('NullableTrack'),
      'always': _ref('Track'),
      'inArray': {'type': 'array', 'items': _ref('Peer')},
      'peer': _nullableRef('NullablePeer'),
    });
  });

  test('references from optional properties do not keep a component '
      'non-null', () {
    final spec = normalizeSpec({
      'components': {
        'schemas': {
          'Album': {
            'type': 'object',
            'required': ['id'],
            'properties': {
              'id': {'type': 'string'},
              'peer': {
                'allOf': [_ref('Peer')],
              },
              'origin': _ref('Peer'),
            },
          },
          'Hit': {
            'type': 'object',
            'properties': {'peer': _nullableRef('Peer')},
          },
          'Peer': _object(),
        },
      },
    });

    expect(_schemas(spec)['Peer'], {..._object(), 'nullable': true});
  });

  test('a required or array reference keeps a component non-null and '
      'gives it a nullable alias', () {
    final input = {
      'components': {
        'schemas': {
          'Album': {
            'type': 'object',
            'required': ['peer'],
            'properties': {
              'peer': {
                'allOf': [_ref('Peer')],
              },
              'others': {'type': 'array', 'items': _ref('Other')},
            },
          },
          'Hit': {
            'type': 'object',
            'properties': {
              'peer': _nullableRef('Peer'),
              'other': _nullableRef('Other'),
            },
          },
          'Peer': _object(),
          'Other': _object(),
        },
      },
    };

    final schemas = _schemas(normalizeSpec(input));
    expect(schemas['Peer'], _object());
    expect(schemas['Other'], _object());
    expect(schemas['NullablePeer'], {..._object(), 'nullable': true});
    expect(schemas['NullableOther'], {..._object(), 'nullable': true});
  });

  test('allOf with more than a reference, or several parts, is not a '
      'nullable reference', () {
    final input = {
      'components': {
        'schemas': {
          'Item': {
            'type': 'object',
            'properties': {
              'two': {
                'allOf': [_ref('A'), _ref('B')],
                'nullable': true,
              },
              'notNullable': {
                'allOf': [_ref('C')],
              },
            },
          },
          'A': _object(),
          'B': _object(),
          'C': _object(),
        },
      },
    };

    expect(normalizeSpec(input), input);
  });

  test('a nullable response body marks its component nullable; another '
      "operation's plain response body does not keep it non-null", () {
    Map<String, Object?> body(Map<String, Object?> schema) => {
      'responses': {
        '200': {
          'content': {
            'application/json': {'schema': schema},
          },
        },
      },
    };
    final spec = normalizeSpec({
      'paths': {
        '/state': {
          'get': body(_nullableRef('State')),
          'post': body(_ref('State')),
        },
      },
      'components': {
        'schemas': {'State': _object()},
      },
    });

    expect(_schemas(spec)['State'], {..._object(), 'nullable': true});
  });

  test('a component referenced only from plain response bodies is '
      'unchanged', () {
    final input = {
      'paths': {
        '/info': {
          'get': {
            'responses': {
              '200': {
                'content': {
                  'application/json': {'schema': _ref('Info')},
                },
              },
            },
          },
        },
      },
      'components': {
        'schemas': {'Info': _object()},
      },
    };

    expect(normalizeSpec(input), input);
  });

  test('a spec without components is returned as it is', () {
    final input = {
      'paths': {
        '/a': {'get': _nullableRef('X')},
      },
    };

    expect(normalizeSpec(input), input);
  });

  test('a component used both nullable and non-null gets a nullable alias '
      'that its nullable uses point at', () {
    final spec = normalizeSpec({
      'paths': {
        '/similar': {
          'get': {
            'responses': {
              '200': {
                'content': {
                  'application/json': {'schema': _nullableRef('Track')},
                },
              },
            },
          },
        },
      },
      'components': {
        'schemas': {
          'Item': {
            'type': 'object',
            'required': ['maybe', 'always'],
            'properties': {
              'maybe': {..._nullableRef('Track'), 'description': 'Gone?'},
              'always': _ref('Track'),
            },
          },
          'Track': _object(),
        },
      },
    });

    final schemas = _schemas(spec);
    expect(nullableAliasName('Track'), 'NullableTrack');
    expect(schemas['Track'], _object());
    expect(schemas['NullableTrack'], {..._object(), 'nullable': true});
    final item = schemas['Item']! as Map<String, Object?>;
    final properties = item['properties']! as Map<String, Object?>;
    expect(properties['maybe'], {
      ..._nullableRef('NullableTrack'),
      'description': 'Gone?',
    });
    expect(properties['always'], _ref('Track'));
    expect(
      ((((spec['paths']! as Map)['/similar'] as Map)['get'] as Map)['responses']
          as Map)['200'],
      {
        'content': {
          'application/json': {'schema': _nullableRef('NullableTrack')},
        },
      },
    );
  });

  test('an alias name already taken by a component fails', () {
    expect(
      () => normalizeSpec({
        'components': {
          'schemas': {
            'Item': {
              'type': 'object',
              'required': ['always'],
              'properties': {
                'maybe': _nullableRef('Track'),
                'always': _ref('Track'),
              },
            },
            'Track': _object(),
            'NullableTrack': _object(),
          },
        },
      }),
      throwsStateError,
    );
  });
}
