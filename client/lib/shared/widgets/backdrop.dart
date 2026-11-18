// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/contrast.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/providers/tint.dart';

export 'package:soundspan/shared/providers/tint.dart'
    show TintExtractor, tintExtractorProvider, tintProvider;

/// How much of the tint is mixed into `ground` in the dark theme.
const double darkTintMix = 0.35;

/// How much of the tint is mixed into `surface` in the light theme.
const double lightTintMix = 0.12;

/// The contrast `content` text keeps on every colour of a backdrop.
const double backdropTitleContrast = 4.5;

/// The backdrop of a detail header tinted with [tint] (doc 09, Colour
/// Tokens: Dynamic backdrops).
///
/// In dark the tint is mixed [darkTintMix] into `ground`, fading to
/// `surface`; in light it is mixed [lightTintMix] into `surface`. The tinted
/// colour is then moved towards `surface`, the scrim, until `content` text
/// on it reaches [backdropTitleContrast].
LinearGradient backdropGradient(
  Color tint,
  Brightness brightness,
  SoundspanColors colors,
) {
  final opaque = tint.withAlpha(0xFF);
  var top = switch (brightness) {
    Brightness.dark => Color.lerp(colors.ground, opaque, darkTintMix)!,
    Brightness.light => Color.lerp(colors.surface, opaque, lightTintMix)!,
  };
  for (var step = 0; step < 10; step++) {
    if (contrastRatio(colors.content, top) >= backdropTitleContrast) break;
    top = Color.lerp(top, colors.surface, (step + 1) / 10)!;
  }
  return _vertical(top, colors.surface);
}

/// The backdrop without a tint: plain `surface`.
LinearGradient plainBackdrop(SoundspanColors colors) =>
    _vertical(colors.surface, colors.surface);

LinearGradient _vertical(Color top, Color bottom) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [top, bottom],
);

/// The backdrop of the cover [artworkRef] in the ambient theme: its
/// [backdropGradient] once [tintProvider] has a tint, [plainBackdrop]
/// before that and when there is no cover or no tint.
LinearGradient watchBackdrop(
  BuildContext context,
  WidgetRef ref,
  String? artworkRef,
) {
  final colors = context.colors;
  final tint = artworkRef == null
      ? null
      : ref.watch(tintProvider(artworkRef)).value;
  if (tint == null) return plainBackdrop(colors);
  return backdropGradient(tint, Theme.of(context).brightness, colors);
}

/// Paints [child] over the tinted backdrop of the cover [artworkRef]
/// (doc 09, Colour Tokens: Dynamic backdrops).
///
/// Plain `surface` until the tint is known, and when there is no cover or
/// no tint; the tint then fades in over 250 ms, at once under reduced
/// motion.
class Backdrop extends ConsumerWidget {
  /// Paints [child] over the backdrop of [artworkRef].
  const new({required this.artworkRef, required this.child, super.key});

  /// The cover the tint comes from; null gives plain `surface`.
  final String? artworkRef;

  /// What is painted over the backdrop.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AnimatedContainer(
    duration: Motion.of(context, Motion.emphasized),
    curve: Motion.curve,
    decoration: BoxDecoration(
      gradient: watchBackdrop(context, ref, artworkRef),
    ),
    child: child,
  );
}
