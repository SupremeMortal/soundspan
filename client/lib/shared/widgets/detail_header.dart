// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/backdrop.dart';

/// Builds the artwork of a [DetailHeader] at an edge length.
typedef DetailArtworkBuilder = Widget Function(double size);

/// The header of an album, artist or playlist page (doc 09, Album, Artist,
/// Playlist), as a sliver.
///
/// Artwork (140 compact, 192 medium, 232 expanded), the [overline] type
/// label, the [title] (at most two lines; `headline` 24/30 on compact,
/// `headline` on medium, `display` on expanded), one [metadata] line and the
/// [actions] slot, over the [Backdrop] of [artworkRef]. A pinned app bar
/// sits above it; once the title has scrolled under the bar, the bar shows
/// the title, so the header collapses into it. The page content follows as
/// [slivers], so the bar stays pinned over it. The bar has Back except on
/// expanded windows, whose top bar has its own.
class DetailHeader extends ConsumerStatefulWidget {
  /// Creates the header titled [title].
  const new({
    required this.artworkRef,
    required this.overline,
    required this.title,
    required this.metadata,
    this.artworkShape = ArtworkShape.square,
    this.artworkBuilder,
    this.actions,
    this.slivers = const [],
    super.key,
  });

  /// The page content under the header. They are part of the header's
  /// sliver group so the app bar stays pinned above them.
  final List<Widget> slivers;

  /// The cover shown and tinted from; null shows the placeholder and plain
  /// `surface`.
  final String? artworkRef;

  /// Square, or circle for artists.
  final ArtworkShape artworkShape;

  /// Builds a different artwork, such as a playlist's mosaic; the backdrop
  /// is still tinted from [artworkRef].
  final DetailArtworkBuilder? artworkBuilder;

  /// The type label, such as "Album"; drawn in upper case.
  final String overline;

  /// The page title.
  final String title;

  /// The metadata line, usually a [DetailMetadataLine].
  final Widget metadata;

  /// The actions under the metadata; nothing when null.
  final Widget? actions;

  /// The key of the box holding the header artwork.
  static const Key artworkKey = ValueKey('DetailHeader.artwork');

  /// The key of the header title.
  static const Key titleKey = ValueKey('DetailHeader.title');

  /// The key of the actions slot, present only with [actions].
  static const Key actionsKey = ValueKey('DetailHeader.actions');

  /// The header artwork's edge on a [windowClass] window.
  static double artworkSizeFor(WindowClass windowClass) =>
      switch (windowClass) {
        WindowClass.compact => 140,
        WindowClass.medium => 192,
        WindowClass.expanded => 232,
      };

  /// The title style on a [windowClass] window.
  static TextStyle titleStyleFor(
    SoundspanTypography typography,
    WindowClass windowClass,
  ) => switch (windowClass) {
    WindowClass.compact => typography.headlineCompact,
    WindowClass.medium => typography.headline,
    WindowClass.expanded => typography.display,
  };

  @override
  ConsumerState<DetailHeader> createState() => _DetailHeaderState();
}

class _DetailHeaderState extends ConsumerState<DetailHeader> {
  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  ScrollPosition? _position;
  bool _collapsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_syncCollapsed);
      _position = position?..addListener(_syncCollapsed);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_syncCollapsed);
    super.dispose();
  }

  void _syncCollapsed() {
    final position = _position;
    final content = _contentKey.currentContext?.findRenderObject();
    final title = _titleKey.currentContext?.findRenderObject();
    if (position == null || content is! RenderBox || title is! RenderBox) {
      return;
    }
    final titleBottom = title
        .localToGlobal(Offset(0, title.size.height), ancestor: content)
        .dy;
    final collapsed = position.pixels >= titleBottom;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final windowClass = WindowClass.of(context);
    final compact = windowClass == WindowClass.compact;
    final size = DetailHeader.artworkSizeFor(windowClass);
    final gutter = pageGutter(windowClass);
    final backdrop = watchBackdrop(context, ref, widget.artworkRef);
    final builder = widget.artworkBuilder;
    final actions = widget.actions;

    final artwork = SizedBox.square(
      key: DetailHeader.artworkKey,
      dimension: size,
      child:
          builder?.call(size) ??
          Artwork(
            ref: widget.artworkRef,
            size: size,
            shape: widget.artworkShape,
          ),
    );
    final align = compact ? TextAlign.center : TextAlign.start;
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          widget.overline.toUpperCase(),
          textAlign: align,
          style: typography.overline.copyWith(color: colors.contentSecondary),
        ),
        const SizedBox(height: Spacing.x4),
        Semantics(
          header: true,
          child: Text(
            widget.title,
            key: _titleKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: DetailHeader.titleStyleFor(
              typography,
              windowClass,
            ).copyWith(color: colors.content),
          ),
        ),
        const SizedBox(height: Spacing.x4),
        widget.metadata,
        if (actions != null) ...[
          const SizedBox(height: Spacing.x16),
          KeyedSubtree(key: DetailHeader.actionsKey, child: actions),
        ],
      ],
    );

    final content = Padding(
      key: _contentKey,
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x8, gutter, Spacing.x24),
      child: compact
          ? Column(
              children: [
                artwork,
                const SizedBox(height: Spacing.x16),
                text,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                artwork,
                const SizedBox(width: Spacing.x24),
                Expanded(child: text),
              ],
            ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: windowClass != WindowClass.expanded,
          backgroundColor: backdrop.colors.first,
          surfaceTintColor: colors.surface.withAlpha(0),
          scrolledUnderElevation: 0,
          title: _collapsed
              ? Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.title.copyWith(color: colors.content),
                )
              : null,
        ),
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.emphasized),
            curve: Motion.curve,
            decoration: BoxDecoration(gradient: backdrop),
            child: content,
          ),
        ),
        ...widget.slivers,
      ],
    );
  }
}

/// The page gutter of a [windowClass] window.
double pageGutter(WindowClass windowClass) => switch (windowClass) {
  WindowClass.compact => Gutters.compact,
  WindowClass.medium => Gutters.medium,
  WindowClass.expanded => Gutters.expanded,
};

/// The metadata line of a [DetailHeader]: an optional link, such as the
/// album artist, followed by [parts], all separated by " · ".
///
/// The link is a 48-pixel-high button; the line wraps on narrow windows
/// and is centred on compact ones.
class DetailMetadataLine extends StatelessWidget {
  /// Creates the line of [parts], led by [link] when given.
  const new({required this.parts, this.link, this.onLink, super.key});

  /// The leading linked text; none when null.
  final String? link;

  /// Opens what [link] names.
  final VoidCallback? onLink;

  /// The plain parts, in order.
  final List<String> parts;

  /// The key of the link button.
  static const Key linkKey = ValueKey('DetailMetadataLine.link');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final compact = WindowClass.of(context) == WindowClass.compact;
    final style = typography.body.copyWith(color: colors.contentSecondary);
    final link = this.link;
    final rest = parts.where((part) => part.isNotEmpty).join(' · ');
    return Wrap(
      alignment: compact ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (link != null)
          InkWell(
            key: linkKey,
            onTap: onLink,
            borderRadius: BorderRadius.circular(Radii.small),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: Sizes.touchTarget,
                minWidth: Sizes.touchTarget,
              ),
              child: Align(
                widthFactor: 1,
                child: Text(
                  link,
                  style: typography.body.copyWith(
                    color: colors.content,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (rest.isNotEmpty)
          Text(link != null ? ' · $rest' : rest, style: style.tabular),
      ],
    );
  }
}

/// A total running time as a header shows it: "45 min", "1 hr 5 min".
String formatTotalDuration(AppLocalizations l10n, Duration duration) {
  final minutes = (duration.isNegative ? 0 : duration.inSeconds) ~/ 60;
  if (minutes < 60) return l10n.detailDurationMinutes(minutes);
  return l10n.detailDurationHours(minutes ~/ 60, minutes % 60);
}

/// The placeholder of a [DetailHeader] while its first value loads:
/// `surfaceHighlight` blocks where the artwork and the text go.
class DetailHeaderSkeleton extends StatelessWidget {
  /// Creates the skeleton.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final windowClass = WindowClass.of(context);
    final size = DetailHeader.artworkSizeFor(windowClass);
    Widget block(double width, double height, {double? radius}) => SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceHighlight,
          borderRadius: BorderRadius.circular(radius ?? Spacing.x4),
        ),
      ),
    );
    final compact = windowClass == WindowClass.compact;
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        block(64, 12),
        const SizedBox(height: Spacing.x8),
        block(200, 28),
        const SizedBox(height: Spacing.x8),
        block(160, 14),
      ],
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: windowClass != WindowClass.expanded,
          backgroundColor: colors.surface,
          scrolledUnderElevation: 0,
        ),
        SliverToBoxAdapter(
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.x16),
              child: compact
                  ? Column(
                      children: [
                        block(size, size, radius: Radii.small),
                        const SizedBox(height: Spacing.x16),
                        text,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        block(size, size, radius: Radii.small),
                        const SizedBox(width: Spacing.x24),
                        text,
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
