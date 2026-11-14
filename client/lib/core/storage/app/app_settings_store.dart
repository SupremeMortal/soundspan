// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/storage/app/app_database.dart';

/// The app-wide theme choice.
enum ThemeModeSetting {
  /// Follow the system's light or dark setting.
  system,

  /// Always dark.
  dark,

  /// Always light.
  light,
}

/// The last position and size of the desktop window, in logical pixels.
@immutable
final class WindowBounds {
  /// Creates bounds at ([left], [top]) of [width] by [height].
  const new({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// The distance of the window's left edge from the screen's.
  final double left;

  /// The distance of the window's top edge from the screen's.
  final double top;

  /// The window's width.
  final double width;

  /// The window's height.
  final double height;

  @override
  bool operator ==(Object other) =>
      other is WindowBounds &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// A typed app setting: its key in the `app_settings` table, how its value
/// maps to and from JSON, and the value read when it is not set.
final class AppSettingKey<T extends Object> {
  const new _(
    this.name, {
    required this._toJson,
    required this._fromJson,
    this.defaultValue,
  });

  /// The key of the row.
  final String name;

  /// The value read when the setting is not stored or cannot be decoded.
  final T? defaultValue;

  final Object? Function(T value) _toJson;
  final T? Function(Object? json) _fromJson;

  String _encode(T value) => jsonEncode(_toJson(value));

  T? _decode(String? stored) {
    if (stored == null) return defaultValue;
    try {
      return _fromJson(jsonDecode(stored)) ?? defaultValue;
    } on Object {
      return defaultValue;
    }
  }
}

/// The app settings keys (doc 05).
abstract final class AppSettingKeys {
  /// The id of the profile the app shows.
  static const activeProfileId = AppSettingKey<String>._(
    'activeProfileId',
    toJson: _identity,
    fromJson: _string,
  );

  /// The theme choice; [ThemeModeSetting.system] when not set.
  static const themeMode = AppSettingKey<ThemeModeSetting>._(
    'themeMode',
    toJson: _enumName,
    fromJson: _themeMode,
    defaultValue: ThemeModeSetting.system,
  );

  /// The language tag the user picked, such as `pt-BR`; null follows the
  /// system.
  static const locale = AppSettingKey<String>._(
    'locale',
    toJson: _identity,
    fromJson: _string,
  );

  /// The desktop window's last bounds.
  static const windowBounds = AppSettingKey<WindowBounds>._(
    'window.bounds',
    toJson: _boundsToJson,
    fromJson: _boundsFromJson,
  );

  /// Whether the desktop window was maximized.
  static const windowMaximized = AppSettingKey<bool>._(
    'window.maximized',
    toJson: _identity,
    fromJson: _bool,
  );

  /// Whether closing the desktop window hides it to the tray.
  static const closeToTray = AppSettingKey<bool>._(
    'closeToTray',
    toJson: _identity,
    fromJson: _bool,
  );

  /// Every key, in the order doc 05 lists them.
  static const List<AppSettingKey<Object>> all = [
    activeProfileId,
    themeMode,
    locale,
    windowBounds,
    windowMaximized,
    closeToTray,
  ];

  static Object? _identity(Object value) => value;
  static String? _string(Object? json) => json is String ? json : null;
  static bool? _bool(Object? json) => json is bool ? json : null;
  static Object? _enumName(Enum value) => value.name;

  static ThemeModeSetting? _themeMode(Object? json) {
    for (final mode in ThemeModeSetting.values) {
      if (mode.name == json) return mode;
    }
    return null;
  }

  static Object? _boundsToJson(WindowBounds b) => {
    'left': b.left,
    'top': b.top,
    'width': b.width,
    'height': b.height,
  };

  static WindowBounds? _boundsFromJson(Object? json) => switch (json) {
    {
      'left': final num left,
      'top': final num top,
      'width': final num width,
      'height': final num height,
    } =>
      WindowBounds(
        left: left.toDouble(),
        top: top.toDouble(),
        width: width.toDouble(),
        height: height.toDouble(),
      ),
    _ => null,
  };
}

/// Reads and writes the app settings in [AppDatabase]; values are stored
/// JSON-encoded.
class AppSettingsStore {
  /// Creates a store over [database].
  const new(this.database);

  /// The database holding the settings.
  final AppDatabase database;

  SimpleSelectStatement<$AppSettingsTable, AppSetting> _row(String name) =>
      database.select(database.appSettings)..where((t) => t.key.equals(name));

  /// The value of [key], or its default when it is not set.
  Future<T?> read<T extends Object>(AppSettingKey<T> key) async =>
      key._decode((await _row(key.name).getSingleOrNull())?.value);

  /// Stores [value] under [key]; null removes the setting.
  Future<void> write<T extends Object>(AppSettingKey<T> key, T? value) async {
    if (value == null) {
      await (database.delete(
        database.appSettings,
      )..where((t) => t.key.equals(key.name))).go();
      return;
    }
    await database
        .into(database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key.name, value: key._encode(value)),
        );
  }

  /// The value of [key] now and after every change.
  Stream<T?> watch<T extends Object>(AppSettingKey<T> key) =>
      _row(key.name)
          .watchSingleOrNull()
          .map((row) => key._decode(row?.value))
          .distinct();
}
