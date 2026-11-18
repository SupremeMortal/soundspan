// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Gives every generated model that uses a `Nullable<Component>` alias an
/// unprefixed import of `lib/src/nullable_references.dart` (doc 03,
/// Generated From the Server Specification).
///
/// The generator imports a mapped type's library with a prefix. The alias
/// is a typedef of a freezed model, so freezed writes that model's
/// unprefixed `$<Component>CopyWith` into the part file; the codec library
/// exports the models, and this import makes the name resolve.
///
/// Run from the package root by `client/tool/gen.sh`, after the generator.
library;

import 'dart:io';

const _library = 'package:soundspan_api/src/nullable_references.dart';
const _import = "import '$_library';";
final _prefixed = RegExp(
  "^import '${RegExp.escape(_library)}' as (mapped[0-9]+);\$",
  multiLine: true,
);

/// [source] with the unprefixed codec-library import added before its
/// prefixed one, or `null` when [source] does not use a nullable alias or
/// already has the import.
String? withNullableReferencesImport(String source) {
  final match = _prefixed.firstMatch(source);
  if (match == null) return null;
  if (!source.contains('${match[1]}.Nullable')) return null;
  if (source.split('\n').contains(_import)) return null;
  return source.replaceRange(match.start, match.start, '$_import\n');
}

void main() {
  for (final file in Directory('lib/src/generated').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    final updated = withNullableReferencesImport(file.readAsStringSync());
    if (updated != null) file.writeAsStringSync(updated);
  }
}
