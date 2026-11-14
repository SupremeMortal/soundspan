// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';

/// Attaches [child] to the active profile's container of the
/// [ProfileRuntime], so the UI and background code share one instance of
/// every profile-scoped service (doc 02, Background Entry Points).
///
/// A new profile fades in over 150 ms, without animation when the platform
/// asks for reduced motion. The old profile's subtree is removed as soon as
/// a switch starts; while no profile is active nothing is built.
class ProfileScope extends ConsumerWidget {
  /// Creates the scope around [child].
  const new({required this.child, super.key});

  /// The subtree that reads profile-scoped providers.
  final Widget child;

  /// How long a new profile fades in.
  static const Duration fadeDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(profileRuntimeProvider);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ValueListenableBuilder<ProfileRuntimeState>(
      valueListenable: runtime.state,
      builder: (context, state, _) {
        final container = runtime.container;
        final current = switch (state) {
          ProfileRuntimeActive(:final profileId) when container != null =>
            UncontrolledProviderScope(
              key: ValueKey<String>(profileId),
              container: container,
              child: child,
            ),
          _ => const SizedBox.shrink(),
        };
        return AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : fadeDuration,
          // Only the current child: the old profile's subtree never builds
          // again once a switch starts.
          layoutBuilder: (current, previous) =>
              current ?? const SizedBox.shrink(),
          child: current,
        );
      },
    );
  }
}
