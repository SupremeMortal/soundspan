// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the search shortcut asked Search to focus its field; the search
/// screen takes the request when it shows (doc 09, Desktop Interaction).
class SearchFocusRequest extends Notifier<bool> {
  @override
  bool build() => false;

  /// Asks Search to focus its field.
  void request() => state = true;

  /// Takes the request: true when there was one, which is then cleared.
  bool take() {
    if (!state) return false;
    state = false;
    return true;
  }
}

/// The pending search focus request; a root provider.
final NotifierProvider<SearchFocusRequest, bool> searchFocusRequestProvider =
    NotifierProvider<SearchFocusRequest, bool>(SearchFocusRequest.new);
