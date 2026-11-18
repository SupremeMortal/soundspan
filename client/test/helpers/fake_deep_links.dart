// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/platform/deep_links/deep_links.dart';

/// [DeepLinks] a test drives: an optional [initial] link, then whatever it
/// [send]s.
class FakeDeepLinks implements DeepLinks {
  /// Creates the fake; [initial] is the launch link.
  new({this.initial});

  /// The link [initialLink] returns.
  final Uri? initial;

  final StreamController<Uri> _links = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => _links.stream;

  /// Delivers [uri] as a link received while the app runs.
  void send(Uri uri) => _links.add(uri);

  /// Closes the stream.
  Future<void> close() => _links.close();
}
