// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:dbus/dbus.dart';

/// The names on the session bus on Linux; null on another platform.
Future<List<String>?> sessionBusNames() async {
  if (!Platform.isLinux) return null;
  final client = DBusClient.session();
  try {
    return await client.listNames();
  } finally {
    await client.close();
  }
}
