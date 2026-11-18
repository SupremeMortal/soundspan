// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/features/vibe/ui/start_radio.dart';
import 'package:soundspan/features/vibe/ui/vibe_view_model.dart';
import 'package:soundspan/features/vibe/vibe_providers.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show ApiException, FeatureDisabled;

/// Vibe (`/vibe`, pushed inside the current branch; doc 09, Shell by
/// Window Class): tracks found by how they sound.
///
/// When the server also searches by description
/// ([vibeSearchAvailableProvider]) a search field leads the page; a query
/// of two characters or more, [vibeSearchDebounce] after the last
/// keystroke, lists the matching tracks under "Play all". With the field
/// empty the page shows "Similar to what's playing": tracks that sound
/// like the queue's current track, which it follows [vibeSeedDebounce]
/// after a change, or an [EmptyState] explaining Vibe while nothing with a
/// library id plays.
///
/// Lists show skeleton rows while loading. Nothing is cached, so the page
/// shows the offline state while the server cannot be reached. Without
/// similar tracks on the server ([vibeAvailableProvider]) the page says
/// "Not available on this server" and asks for nothing; a
/// `FeatureDisabled` answer hides Vibe and asks for a capability refresh.
/// A 502, 503 or 504 from the search says the search is unavailable, with
/// Retry.
class VibeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  /// The key of the search field.
  static const Key searchKey = ValueKey('VibeScreen.search');

  /// The key of the search field's clear button.
  static const Key clearKey = ValueKey('VibeScreen.clear');

  /// The key of the "Play all" button.
  static const Key playAllKey = ValueKey('VibeScreen.playAll');

  /// How many skeleton rows stand for a list while it loads.
  static const int skeletonRows = 6;

  @override
  ConsumerState<VibeScreen> createState() => _VibeScreenState();
}

class _VibeScreenState extends ConsumerState<VibeScreen> {
  final TextEditingController _field = TextEditingController();
  Timer? _queryTimer;
  Timer? _seedTimer;
  String _query = '';
  Track? _seed;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<PlaybackSnapshot>>(playbackStateProvider, (
      _,
      next,
    ) {
      if (next.hasValue) _follow(_seedOf(next.value?.current));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _queryTimer?.cancel();
    _seedTimer?.cancel();
    _field.dispose();
    super.dispose();
  }

  /// The current item when it is a track with a library id.
  static Track? _seedOf(QueueItem? item) => switch (item) {
    TrackQueueItem(:final track) when track.libraryTrackId != null => track,
    _ => null,
  };

  /// Shows the first loaded seed at once and each later change
  /// [vibeSeedDebounce] after it settles.
  void _follow(Track? next) {
    _seedTimer?.cancel();
    if (!_seeded) {
      _seeded = true;
      if (next != null) setState(() => _seed = next);
      return;
    }
    if (next?.libraryTrackId == _seed?.libraryTrackId) return;
    _seedTimer = Timer(vibeSeedDebounce, () {
      if (mounted) setState(() => _seed = next);
    });
  }

  void _onChanged(String text) {
    _queryTimer?.cancel();
    _queryTimer = Timer(vibeSearchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
    setState(() {});
  }

  void _clear() {
    _queryTimer?.cancel();
    _field.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final gutter = pageGutter(windowClass);
    final available = ref.watch(vibeAvailableProvider);
    final searchable = ref.watch(vibeSearchAvailableProvider);
    final reachability =
        ref.watch(reachabilityStateProvider).value ??
        ref.watch(reachabilityProvider).current;
    final online = reachability == Reachability.online;
    final searching = searchable && _query.length >= 2;

    final List<Widget> content;
    if (!available) {
      content = [
        _Fill(
          EmptyState(
            icon: Icons.block_rounded,
            message: l10n.errorViewFeatureDisabled,
          ),
        ),
      ];
    } else if (!online) {
      content = [
        _Fill(
          EmptyState(
            icon: Icons.cloud_off_rounded,
            message: l10n.errorViewOffline,
          ),
        ),
      ];
    } else if (searching) {
      content = _search(l10n);
    } else {
      content = _similar(l10n);
    }

    return RouteTitle(
      screen: l10n.navVibe,
      child: Scaffold(
        appBar: windowClass == WindowClass.compact
            ? AppBar(title: Text(l10n.navVibe), actions: const [AvatarButton()])
            : null,
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                Spacing.x24,
                gutter,
                Spacing.x8,
              ),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.navVibe,
                    style: context.typography.headline.copyWith(
                      color: context.colors.content,
                    ),
                  ),
                ),
              ),
            ),
            if (available && searchable)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Spacing.x8,
                  gutter,
                  Spacing.x8,
                ),
                sliver: SliverToBoxAdapter(child: _searchField(l10n)),
              ),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _searchField(AppLocalizations l10n) => Semantics(
    label: l10n.vibeSearchLabel,
    textField: true,
    child: TextField(
      key: VibeScreen.searchKey,
      controller: _field,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.vibeSearchHint,
        prefixIcon: const Icon(Icons.graphic_eq_rounded),
        suffixIcon: _field.text.isEmpty
            ? null
            : IconButton(
                key: VibeScreen.clearKey,
                tooltip: l10n.vibeSearchClear,
                icon: const Icon(Icons.close_rounded),
                onPressed: _clear,
              ),
      ),
    ),
  );

  List<Widget> _search(AppLocalizations l10n) {
    final query = _query;
    final results = ref.watch(vibeSearchResultsProvider(query));
    void retry() => ref.invalidate(vibeSearchResultsProvider(query));
    return switch (results) {
      AsyncData(:final value) when value.isEmpty => [
        _Fill(
          EmptyState(
            icon: Icons.search_off_rounded,
            message: l10n.vibeNoMatches,
          ),
        ),
      ],
      AsyncData(:final value) => [
        _Header(
          title: null,
          tracks: value,
          context: QueueContext(kind: QueueContextKind.search, title: query),
        ),
        _TrackList(
          tracks: value,
          context: QueueContext(kind: QueueContextKind.search, title: query),
        ),
      ],
      AsyncError(:final error) => [
        _failure(
          error,
          retry,
          unavailable: switch (error) {
            ApiException(:final status?) => status >= 502 && status <= 504,
            _ => false,
          },
        ),
      ],
      _ => [const _Skeleton()],
    };
  }

  List<Widget> _similar(AppLocalizations l10n) {
    final seed = _seed;
    final libraryId = seed?.libraryTrackId;
    if (seed == null || libraryId == null) {
      return [
        _Fill(
          EmptyState(icon: Icons.graphic_eq_rounded, message: l10n.vibeExplain),
        ),
      ];
    }
    final similar = ref.watch(vibeSimilarProvider(libraryId));
    final queueContext = vibeRadioContext(seed);
    final title = l10n.vibeSimilarTitle;
    return switch (similar) {
      AsyncData(:final value) when value.isEmpty => [
        _Header(title: title, caption: seed.meta.title),
        _Fill(
          EmptyState(
            icon: Icons.search_off_rounded,
            message: l10n.vibeNoSimilar,
          ),
        ),
      ],
      AsyncData(:final value) => [
        _Header(
          title: title,
          caption: seed.meta.title,
          tracks: value,
          context: queueContext,
        ),
        _TrackList(tracks: value, context: queueContext),
      ],
      AsyncError(:final error) => [
        _Header(title: title, caption: seed.meta.title),
        _failure(error, () => ref.invalidate(vibeSimilarProvider(libraryId))),
      ],
      _ => [_Header(title: title, caption: seed.meta.title), const _Skeleton()],
    };
  }

  Widget _failure(
    Object error,
    VoidCallback retry, {
    bool unavailable = false,
  }) {
    if (error is FeatureDisabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) reportVibeDisabled(ref);
      });
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (unavailable) {
      final l10n = AppLocalizations.of(context);
      return _Fill(
        EmptyState(
          icon: Icons.dns_rounded,
          message: l10n.vibeSearchUnavailable,
          actionLabel: l10n.errorViewRetry,
          onAction: retry,
        ),
      );
    }
    return _Fill(ErrorView(error: error, onRetry: retry));
  }
}

/// [child] filling the rest of the page.
class _Fill extends StatelessWidget {
  const new(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}

/// A section title with an optional [caption], and "Play all" for the
/// playable [tracks] when there are any.
class _Header extends ConsumerWidget {
  const new({
    required this.title,
    this.caption,
    this.tracks = const [],
    this.context,
  });

  final String? title;
  final String? caption;
  final List<Track> tracks;
  final QueueContext? context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final gutter = pageGutter(WindowClass.of(context));
    final title = this.title;
    final caption = this.caption;
    final queueContext = this.context;
    final first = tracks.indexWhere((track) => track.playbackId != null);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x16, gutter, Spacing.x8),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: Spacing.x16,
          runSpacing: Spacing.x8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (title != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: typography.title.copyWith(color: colors.content),
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption,
                      style: typography.bodySmall.copyWith(
                        color: colors.contentSecondary,
                      ),
                    ),
                ],
              ),
            if (first >= 0 && queueContext != null)
              FilledButton.icon(
                key: VibeScreen.playAllKey,
                onPressed: () => unawaited(
                  ref
                      .read(playActionsProvider)
                      .playTracks(
                        tracks,
                        startIndex: first,
                        context: queueContext,
                      ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.vibePlayAll),
              ),
          ],
        ),
      ),
    );
  }
}

/// The rows of [tracks], played from the tapped one under [context], with
/// the shared track menu.
class _TrackList extends StatelessWidget {
  const new({required this.tracks, required this.context});

  final List<Track> tracks;
  final QueueContext context;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    final queueContext = this.context;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        gutter - Spacing.x8,
        0,
        gutter - Spacing.x8,
        Spacing.x24,
      ),
      sliver: SliverList.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return Consumer(
            builder: (context, ref, _) => TrackRow(
              title: track.meta.title,
              artist: track.meta.artist,
              album: track.meta.album,
              duration: Duration(seconds: track.meta.durationSec),
              leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
              enabled: track.playbackId != null,
              disabledReason: AppLocalizations.of(context).trackNotPlayable,
              liked: track.isLiked,
              onToggleLike: toggleLikeOf(ref, track),
              playbackId: track.playbackId,
              onTap: () => unawaited(
                ref
                    .read(playActionsProvider)
                    .playTracks(
                      tracks,
                      startIndex: index,
                      context: queueContext,
                    ),
              ),
              onAddToQueue: addToQueueOf(ref, track),
              onMenu: (position) => unawaited(
                openTrackMenu(
                  context,
                  ref,
                  TrackActionScope(
                    track: track,
                    tracks: tracks,
                    index: index,
                    context: queueContext,
                  ),
                  position: position,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton rows while a list loads.
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
      sliver: SliverList.list(
        children: [
          for (var i = 0; i < VibeScreen.skeletonRows; i++)
            const TrackRowSkeleton(withThumbnail: true),
        ],
      ),
    );
  }
}
