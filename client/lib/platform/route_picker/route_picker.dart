// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The system audio output picker seam (doc 10, iOS: Route picker).
///
/// On iOS [buildRoutePicker] embeds the native `AVRoutePickerView` (AirPlay
/// and the other outputs iOS offers) as a platform view registered by
/// `AppDelegate.swift` under [routePickerViewType]. Every other platform
/// has no picker and gets an empty box; the now-playing screen shows the
/// slot only where `PlatformCapabilities.hasSystemRoutePicker` is true.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform view type `AppDelegate.swift` registers the
/// `AVRoutePickerView` factory under.
const String routePickerViewType = 'io.soundspan.app/route_picker';

/// Builds the system output picker with the icon in [tint], and in
/// [activeTint] while audio plays on another output.
typedef RoutePickerBuilder = Widget Function({
  required Color tint,
  required Color activeTint,
});

/// The native output picker on iOS; an empty box on every other platform.
///
/// The creation parameters carry the tints as 32-bit ARGB integers under
/// `tint` and `activeTint`.
Widget buildRoutePicker({required Color tint, required Color activeTint}) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return const SizedBox.shrink();
  }
  return UiKitView(
    viewType: routePickerViewType,
    creationParams: <String, int>{
      'tint': tint.toARGB32(),
      'activeTint': activeTint.toARGB32(),
    },
    creationParamsCodec: const StandardMessageCodec(),
  );
}

/// The builder of the output picker; tests override it with a placeholder.
final Provider<RoutePickerBuilder> routePickerBuilderProvider =
    Provider<RoutePickerBuilder>((ref) => buildRoutePicker);
