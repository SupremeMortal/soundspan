// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The player's volume slider over [value], from 0 to 1 (doc 09,
/// Accessibility).
///
/// Screen readers get one slider node, "Volume", whose value is read in
/// percent and whose increase and decrease actions move it by [step],
/// within `[0, 1]`.
class VolumeSlider extends StatelessWidget {
  /// Creates the slider at [value], reporting changes to [onChanged].
  const new({required this.value, required this.onChanged, super.key});

  /// The volume, from 0 to 1.
  final double value;

  /// Called with the new volume.
  final ValueChanged<double> onChanged;

  /// How far one increase or decrease action moves the volume.
  static const double step = 0.05;

  static String _percent(double value) => '${(value * 100).round()}%';

  double _stepped(double by) => (value + by).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      slider: true,
      label: AppLocalizations.of(context).playerVolume,
      value: _percent(value),
      increasedValue: _percent(_stepped(step)),
      decreasedValue: _percent(_stepped(-step)),
      onIncrease: () => onChanged(_stepped(step)),
      onDecrease: () => onChanged(_stepped(-step)),
      excludeSemantics: true,
      child: Slider(
        value: value,
        activeColor: colors.brand,
        inactiveColor: colors.lineStrong,
        onChanged: onChanged,
      ),
    );
  }
}
