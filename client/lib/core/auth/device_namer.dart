// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/device_info/device_info.dart';

/// Builds the name a device-link key is created with:
/// `"<label> (soundspan <os>)"` (doc 04, Device Link).
class DeviceNamer {
  /// Creates the namer of the device [_info] describes.
  const new(this._info);

  /// The longest name, in UTF-16 code units.
  static const maxLength = 64;

  final DeviceInfo _info;

  /// The name proposed before the user edits it. The label is the host name
  /// on desktop (the OS when there is none), `Android phone` on Android and
  /// `iPhone` on iOS. A label too long for [maxLength] is cut; the suffix is
  /// kept.
  String defaultName() {
    final suffix = ' (soundspan ${_info.osLabel})';
    final label = _cut(_label(), maxLength - suffix.length).trimRight();
    return '$label$suffix';
  }

  /// [userInput] trimmed, with whitespace runs collapsed to one space and
  /// cut to [maxLength]; [defaultName] when nothing is left.
  String normalize(String userInput) {
    final collapsed = userInput.trim().replaceAll(RegExp(r'\s+'), ' ');
    final name = _cut(collapsed, maxLength).trimRight();
    return name.isEmpty ? defaultName() : name;
  }

  String _label() {
    if (_info.isMobile) {
      return _info.osLabel == 'iOS' ? 'iPhone' : 'Android phone';
    }
    return _info.hostName ?? _info.osLabel;
  }
}

/// [text] cut to at most [max] UTF-16 code units without splitting a
/// character outside the basic plane.
String _cut(String text, int max) {
  if (text.length <= max) return text;
  final out = StringBuffer();
  var used = 0;
  for (final rune in text.runes) {
    final size = rune > 0xFFFF ? 2 : 1;
    if (used + size > max) break;
    out.writeCharCode(rune);
    used += size;
  }
  return out.toString();
}
