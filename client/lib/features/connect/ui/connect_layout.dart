// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/wordmark.dart';

/// The layout of the connect screens (doc 09, Connect): a centred column at
/// most [maxWidth] wide with the [Wordmark] on top. On expanded windows the
/// column sits in a card on `ground`.
class ConnectLayout extends StatelessWidget {
  /// Lays out [children] under the wordmark; [screen] titles the window and
  /// [leading], when given, is the app bar's leading control.
  const new({
    required this.screen,
    required this.children,
    this.leading,
    super.key,
  });

  /// The widest the column grows.
  static const double maxWidth = 420;

  /// The localized screen name.
  final String screen;

  /// The column's content, below the wordmark.
  final List<Widget> children;

  /// The app bar's leading control; no app bar when null.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final leading = this.leading;
    return RouteTitle(
      screen: screen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final windowClass = windowClassOf(constraints.biggest);
          final expanded = windowClass == WindowClass.expanded;
          final gutter = switch (windowClass) {
            WindowClass.compact => Gutters.compact,
            WindowClass.medium => Gutters.medium,
            WindowClass.expanded => Gutters.expanded,
          };
          Widget column = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The wordmark scales down rather than overflow at large text
              // scales.
              const Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: Wordmark()),
              ),
              const SizedBox(height: Spacing.x32),
              ...children,
            ],
          );
          if (expanded) {
            column = DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(Radii.large),
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.x32),
                child: column,
              ),
            );
          }
          return Scaffold(
            backgroundColor: expanded ? colors.ground : colors.surface,
            appBar: leading == null
                ? null
                : AppBar(
                    leading: leading,
                    backgroundColor: expanded ? colors.ground : colors.surface,
                  ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(gutter),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth + (expanded ? 2 * Spacing.x32 : 0),
                    ),
                    child: column,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
