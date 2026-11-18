// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/explore/domain/radio_station.dart';
import 'package:soundspan/features/explore/ui/radio_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/util/uuid.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';

final AppLogger _log = AppLogger.scope('Radio');

/// "Radio by genre" and "Radio by decade", the last sections of Explore
/// (doc 09, Home): a wrapping grid of station tiles each, hidden while
/// its list is empty, loading or failed. Genres are ordered by track count
/// with the first [collapsedGenres] shown before "Show all"; decades are
/// newest first.
///
/// Tapping a tile asks the server for a fresh selection of the station's
/// tracks and replaces the queue with the playable ones under a
/// [QueueContextKind.radio] context. The tile shows progress meanwhile and
/// further taps are ignored; an empty selection or a failure shows a
/// snackbar, the failure with Retry. While the server is not reachable the
/// tiles are disabled.
class RadioSections extends ConsumerStatefulWidget {
  /// Creates the sections, a sliver.
  const new({super.key});

  /// The key of the genre section.
  static const Key genresKey = ValueKey('RadioSections.genres');

  /// The key of the decade section.
  static const Key decadesKey = ValueKey('RadioSections.decades');

  /// How many genres show before "Show all".
  static const int collapsedGenres = 12;

  /// The key of the tile of [station].
  static Key tileKey(RadioStation station) => ValueKey(switch (station) {
    GenreStation(:final name) => 'RadioSections.genre.$name',
    DecadeStation(:final decade) => 'RadioSections.decade.$decade',
  });

  @override
  ConsumerState<RadioSections> createState() => _RadioSectionsState();
}

class _RadioSectionsState extends ConsumerState<RadioSections> {
  bool _allGenres = false;
  RadioStation? _starting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final gutter = pageGutter(windowClass);
    final compact = windowClass == WindowClass.compact;
    final reachability =
        ref.watch(reachabilityStateProvider).value ??
        ref.watch(reachabilityProvider).current;
    final online = reachability == Reachability.online;
    final genres = ref.watch(radioGenresProvider).value ?? const [];
    final decades = ref.watch(radioDecadesProvider).value ?? const [];
    final visibleGenres =
        _allGenres || genres.length <= RadioSections.collapsedGenres
        ? genres
        : genres.sublist(0, RadioSections.collapsedGenres);

    Widget tile(RadioStation station, String label, int trackCount) {
      final caption = l10n.exploreRadioTrackCount(trackCount);
      return RadioStationTile(
        key: RadioSections.tileKey(station),
        label: label,
        caption: caption,
        semanticsLabel: l10n.exploreRadioStationSemantics(label, caption),
        compact: compact,
        loading: _starting == station,
        enabled: online,
        disabledReason: l10n.exploreRadioOffline,
        onTap: () => unawaited(_start(station, label)),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      sliver: SliverList.list(
        children: [
          if (genres.isNotEmpty)
            _Section(
              key: RadioSections.genresKey,
              title: l10n.exploreRadioByGenre,
              compact: compact,
              tiles: [
                for (final genre in visibleGenres)
                  tile(
                    GenreStation(genre.name),
                    _genreLabel(genre.name),
                    genre.trackCount,
                  ),
              ],
              footer: visibleGenres.length < genres.length
                  ? TextButton(
                      onPressed: () => setState(() => _allGenres = true),
                      child: Text(l10n.exploreRadioShowAll),
                    )
                  : null,
            ),
          if (decades.isNotEmpty)
            _Section(
              key: RadioSections.decadesKey,
              title: l10n.exploreRadioByDecade,
              compact: compact,
              tiles: [
                for (final decade in decades)
                  tile(
                    DecadeStation(decade.decade),
                    l10n.exploreRadioDecade('${decade.decade}'),
                    decade.trackCount,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Plays [station], whose tile reads [label].
  Future<void> _start(RadioStation station, String label) async {
    if (_starting != null) return;
    setState(() => _starting = station);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final tracks = await startStation(ref, station);
      final playable = [
        for (final track in tracks)
          if (track.playbackId != null) track,
      ];
      if (playable.isEmpty) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.exploreRadioNoTracks)),
        );
        return;
      }
      final queueContext = QueueContext(
        kind: QueueContextKind.radio,
        id: switch (station) {
          GenreStation(:final name) => 'genre:$name',
          DecadeStation(:final decade) => 'decade:$decade',
        },
        title: label,
      );
      await ref.read(playbackControllerProvider).playItems([
        for (final track in playable)
          QueueItem.track(
            queueItemId: Uuid.v4(),
            track: track,
            context: queueContext,
          ),
      ], context: queueContext);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Starting a radio station failed',
        const {},
        error,
        stackTrace,
      );
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.exploreRadioFailed),
          action: SnackBarAction(
            label: l10n.exploreRadioRetry,
            onPressed: () => unawaited(_start(station, label)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = null);
    }
  }
}

/// The server's genre [name], usually lower case, with each word
/// capitalised.
String _genreLabel(String name) => name
    .split(' ')
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');

/// A titled wrap of station tiles with an optional [footer].
class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.compact,
    required this.tiles,
    this.footer,
    super.key,
  });

  final String title;
  final bool compact;
  final List<Widget> tiles;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Spacing.x24, bottom: Spacing.x8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.typography.title.copyWith(
                color: context.colors.content,
              ),
            ),
          ),
        ),
        Wrap(
          spacing: compact ? Spacing.x8 : Spacing.x16,
          runSpacing: compact ? Spacing.x8 : Spacing.x16,
          children: tiles,
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.x8),
            child: footer,
          ),
      ],
    );
  }
}

/// One radio station: a pill on compact windows, a [width] card on wider
/// ones, with the station's [label] and a [caption]. A spinner replaces
/// the icon while [loading]. A disabled tile is drawn at 40 % opacity,
/// ignores taps and gives [disabledReason] as its tooltip. Screen readers
/// get one button, [semanticsLabel] followed by the reason when disabled.
class RadioStationTile extends StatelessWidget {
  /// Creates a tile.
  const new({
    required this.label,
    required this.caption,
    required this.semanticsLabel,
    required this.compact,
    this.loading = false,
    this.enabled = true,
    this.disabledReason,
    this.onTap,
    super.key,
  });

  /// The width of a tile on medium and expanded windows.
  static const double width = 160;

  /// The station's name, such as "Rock" or "1990s".
  final String label;

  /// The second line, such as "42 tracks".
  final String caption;

  /// What screen readers read for the tile.
  final String semanticsLabel;

  /// Whether to draw the compact pill in place of the card.
  final bool compact;

  /// Whether the station is starting.
  final bool loading;

  /// Whether the tile can be tapped.
  final bool enabled;

  /// Why the tile is disabled; its tooltip and read last.
  final String? disabledReason;

  /// Called when the enabled tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final reason = enabled ? null : disabledReason;
    final onTap = enabled ? this.onTap : null;
    final iconSize = compact ? 18.0 : 24.0;
    final leading = SizedBox.square(
      dimension: iconSize,
      child: loading
          ? Padding(
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.brand,
              ),
            )
          : Icon(Icons.radio_rounded, size: iconSize, color: colors.content),
    );
    final text = [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (compact ? typography.body : typography.subtitle).copyWith(
          color: colors.content,
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.caption.copyWith(color: colors.contentSecondary),
      ),
    ];

    final Widget body;
    if (compact) {
      body = Material(
        color: colors.surfaceRaised,
        shape: Radii.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Spacing.x16,
                Spacing.x4,
                Spacing.x24,
                Spacing.x4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: Spacing.x8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      body = SizedBox(
        width: width,
        child: Material(
          color: colors.surfaceRaised,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.x16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(height: Spacing.x12),
                  ...text,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: [semanticsLabel, ?reason].join(', '),
      onTap: onTap,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: reason == null ? body : Tooltip(message: reason, child: body),
      ),
    );
  }
}
