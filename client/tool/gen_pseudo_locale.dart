// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Generates the en_XA pseudo-locale from the English template ARB (doc 09,
// Localization).
//
// Usage, from client/: dart run tool/gen_pseudo_locale.dart
// Reads lib/app/l10n/app_en.arb and writes lib/app/l10n/app_en_XA.arb. Every
// message's literal text is accented, padded to at least 40 % longer and the
// whole message is wrapped in `[` `]`; ICU syntax (placeholders, plural and
// select blocks, `#`, quote escapes) is copied unchanged. `tool/gen.sh` runs
// it before `flutter gen-l10n`.

import 'dart:convert';
import 'dart:io';

/// The template ARB, relative to the client root.
const String englishArbPath = 'lib/app/l10n/app_en.arb';

/// The generated pseudo-locale ARB, relative to the client root.
const String pseudoArbPath = 'lib/app/l10n/app_en_XA.arb';

/// The `@@locale` of the generated ARB.
const String pseudoLocaleTag = 'en_XA';

/// Latin letters and their accented forms. Only Latin-1 and Latin
/// Extended-A forms are used so the bundled font renders every one; letters
/// without such a form stay as they are.
const Map<String, String> accents = {
  'a': 'å', 'c': 'ç', 'd': 'ð', 'e': 'é', 'g': 'ĝ', 'h': 'ĥ', 'i': 'î', //
  'j': 'ĵ', 'k': 'ķ', 'l': 'ļ', 'n': 'ñ', 'o': 'ö', 'p': 'þ', 'r': 'ŕ', //
  's': 'š', 't': 'ţ', 'u': 'û', 'w': 'ŵ', 'y': 'ý', 'z': 'ž', //
  'A': 'Å', 'C': 'Ç', 'D': 'Ð', 'E': 'É', 'G': 'Ĝ', 'H': 'Ĥ', 'I': 'Î', //
  'J': 'Ĵ', 'K': 'Ķ', 'L': 'Ļ', 'N': 'Ñ', 'O': 'Ö', 'P': 'Þ', 'R': 'Ŕ', //
  'S': 'Š', 'T': 'Ţ', 'U': 'Û', 'W': 'Ŵ', 'Y': 'Ý', 'Z': 'Ž', //
};

/// The words padding is cut from, so padded text still wraps at spaces.
const String _padding = ' one two three four five six seven eight nine ten';

/// The ICU argument types whose body is a list of `selector{message}`.
const Set<String> _branchingTypes = {'plural', 'select', 'selectordinal'};

/// The pseudo-localized form of the ICU [message].
///
/// Literal text is accented with [accents]; each message, the top level and
/// every plural or select branch, is padded with words so its literal text
/// is at least 40 % longer; the result is wrapped in `[` `]`. Placeholders,
/// argument types, selectors, `#` and quoted (escaped) text are copied byte
/// for byte.
String pseudoLocalize(String message) =>
    '[${_IcuPseudoWriter(message).message()}]';

/// The pseudo-locale ARB for the English ARB [english]: messages through
/// [pseudoLocalize], `@` metadata copied unchanged, `@@locale` set to
/// [pseudoLocaleTag], keys in the source order.
Map<String, Object?> pseudoArb(Map<String, Object?> english) => {
  for (final MapEntry(:key, :value) in english.entries)
    key: switch (key) {
      '@@locale' => pseudoLocaleTag,
      _ when key.startsWith('@') => value,
      _ => pseudoLocalize(value! as String),
    },
};

/// The text of the pseudo-locale ARB for the English ARB text [source]:
/// two-space indented JSON with a trailing newline.
String generatePseudoArb(String source) {
  final english = jsonDecode(source) as Map<String, Object?>;
  return '${const JsonEncoder.withIndent('  ').convert(pseudoArb(english))}\n';
}

/// Writes [pseudoArbPath] from [englishArbPath], both under the current
/// directory (the client root).
void main() {
  final source = File(englishArbPath).readAsStringSync();
  File(pseudoArbPath).writeAsStringSync(generatePseudoArb(source));
}

/// A single pass over an ICU message that writes its pseudo-localized form.
class _IcuPseudoWriter {
  new(this._source);

  final String _source;
  int _index = 0;

  bool get _done => _index >= _source.length;

  String get _char => _source[_index];

  /// Transforms a message up to the end of the source or an unmatched `}`,
  /// which is left unconsumed.
  String message() {
    final out = StringBuffer();
    var literal = 0;
    while (!_done && _char != '}') {
      switch (_char) {
        case "'":
          literal += _quoted(out);
        case '{':
          _argument(out);
        case '#':
          out.write('#');
          _index++;
        default:
          out.write(accents[_char] ?? _char);
          literal++;
          _index++;
      }
    }
    if (literal > 0) out.write(_paddingFor(literal));
    return out.toString();
  }

  /// Copies `''` or a quoted run (`'{literal}'`) unchanged and returns how
  /// many visible characters it stands for.
  int _quoted(StringBuffer out) {
    if (_index + 1 < _source.length && _source[_index + 1] == "'") {
      out.write("''");
      _index += 2;
      return 1;
    }
    final close = _source.indexOf("'", _index + 1);
    final end = close == -1 ? _source.length : close + 1;
    out.write(_source.substring(_index, end));
    final visible = end - _index - (close == -1 ? 1 : 2);
    _index = end;
    return visible;
  }

  /// Copies the argument starting at `{`, transforming only the messages of
  /// plural and select branches.
  void _argument(StringBuffer out) {
    final headerEnd = _nextOf(const {',', '}'});
    final name = _source.substring(_index, headerEnd);
    _index = headerEnd;
    out.write(name);
    if (_done || _char == '}') {
      if (!_done) out.write('}');
      _index++;
      return;
    }
    // At the comma after the name: read the type.
    final typeEnd = _nextOf(const {',', '}'}, from: _index + 1);
    final type = _source.substring(_index + 1, typeEnd);
    if (!_branchingTypes.contains(type.trim()) ||
        typeEnd >= _source.length ||
        _source[typeEnd] == '}') {
      _copyBalanced(out);
      return;
    }
    out.write(_source.substring(_index, typeEnd + 1));
    _index = typeEnd + 1;
    while (!_done && _char != '}') {
      if (_char == '{') {
        out.write('{');
        _index++;
        out.write(message());
        if (!_done) {
          out.write('}');
          _index++;
        }
      } else {
        out.write(_char);
        _index++;
      }
    }
    if (!_done) {
      out.write('}');
      _index++;
    }
  }

  /// Copies from the current position up to and including the `}` that
  /// closes the argument already opened.
  void _copyBalanced(StringBuffer out) {
    var depth = 1;
    final start = _index;
    while (!_done && depth > 0) {
      if (_char == '{') depth++;
      if (_char == '}') depth--;
      _index++;
    }
    out.write(_source.substring(start, _index));
  }

  /// The index of the first of [chars] at or after [from] (default: the
  /// current position), or the source length.
  int _nextOf(Set<String> chars, {int? from}) {
    var i = from ?? _index;
    while (i < _source.length && !chars.contains(_source[i])) {
      i++;
    }
    return i;
  }
}

/// Padding words for a message with [literal] visible characters: at least
/// 40 % of them, rounded up.
String _paddingFor(int literal) {
  final needed = (literal * 4 + 9) ~/ 10;
  final buffer = StringBuffer();
  while (buffer.length < needed) {
    buffer.write(_padding);
  }
  final words = buffer.toString();
  // Cut at the first word end at or after the needed length.
  final end = words.indexOf(' ', needed);
  return end == -1 ? words : words.substring(0, end);
}
