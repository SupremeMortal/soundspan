// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/licenses/license_catalog.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

/// The widest the licence list and texts grow on large windows.
const double _maxContentWidth = 840;

/// Settings → About → Open-source licences (design doc, Licensing).
///
/// Built on the [LicenseRegistry] through [licenseCatalogProvider]: the
/// client's own licence first, then the bundled fonts and native libraries,
/// then every other package alphabetically, each with its licence count.
/// Tapping an item opens its texts in a [LicenseDetailScreen].
class LicensesScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return RouteTitle(
      screen: l10n.screenLicenses,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.screenLicenses)),
        body: switch (ref.watch(licenseCatalogProvider)) {
          AsyncData(:final value) => _CatalogList(value),
          AsyncError() => _LoadError(
            onRetry: () => ref.invalidate(licenseCatalogProvider),
          ),
          _ => Center(
            child: CircularProgressIndicator(
              semanticsLabel: l10n.licensesLoading,
            ),
          ),
        },
      ),
    );
  }
}

class _CatalogList extends StatelessWidget {
  const new(this.catalog);

  final LicenseCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = catalog.app;
    final items = <Object>[
      ?app,
      if (catalog.bundled.isNotEmpty) ...[
        l10n.licensesSectionBundled,
        ...catalog.bundled,
      ],
      if (catalog.packages.isNotEmpty) ...[
        l10n.licensesSectionPackages,
        ...catalog.packages,
      ],
    ];
    return _Centered(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          final LicensedPackage package => _PackageTile(package),
          final Object heading => _Heading(heading as String),
        },
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const new(this.package);

  final LicensedPackage package;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(package.name),
    subtitle: Text(
      AppLocalizations.of(context).licensesCount(package.licenses.length),
    ),
    minTileHeight: Sizes.touchTarget,
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LicenseDetailScreen(package)),
    ),
  );
}

class _Heading extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.x16,
      Spacing.x16,
      Spacing.x16,
      Spacing.x8,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.typography.subtitle.copyWith(
          color: context.colors.content,
        ),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.x24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: context.colors.danger),
            const SizedBox(height: Spacing.x12),
            Text(
              l10n.licensesLoadFailed,
              textAlign: TextAlign.center,
              style: context.typography.body.copyWith(
                color: context.colors.content,
              ),
            ),
            const SizedBox(height: Spacing.x16),
            FilledButton(onPressed: onRetry, child: Text(l10n.licensesRetry)),
          ],
        ),
      ),
    );
  }
}

/// The licence texts of one [package], selectable, one list item per
/// paragraph so long texts build only what is visible.
class LicenseDetailScreen extends StatefulWidget {
  /// Creates the screen for [package].
  const new(this.package, {super.key});

  /// The package whose licences are shown.
  final LicensedPackage package;

  @override
  State<LicenseDetailScreen> createState() => _LicenseDetailScreenState();
}

class _LicenseDetailScreenState extends State<LicenseDetailScreen> {
  /// Paragraphs of every licence, with a `null` between two licences.
  late final List<LicenseParagraph?> _items = [
    for (final (index, licence) in widget.package.licenses.indexed) ...[
      if (index > 0) null,
      ...licence.paragraphs,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final name = widget.package.name;
    return RouteTitle(
      screen: name,
      child: Scaffold(
        appBar: AppBar(title: Text(name)),
        body: _Centered(
          child: SelectionArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(Spacing.x16),
              itemCount: _items.length,
              itemBuilder: (context, index) => switch (_items[index]) {
                null => const Divider(height: Spacing.x32),
                final paragraph => _Paragraph(paragraph),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const new(this.paragraph);

  final LicenseParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final centered = paragraph.indent == LicenseParagraph.centeredIndent;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: centered ? 0 : Spacing.x16 * paragraph.indent,
        bottom: Spacing.x8,
      ),
      child: Text(
        paragraph.text,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: context.typography.bodySmall.copyWith(
          color: context.colors.contentBody,
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxContentWidth),
      child: child,
    ),
  );
}
