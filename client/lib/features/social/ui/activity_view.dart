// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/realtime/presence_controller.dart';
import 'package:soundspan/core/realtime/presence_models.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show Offline;

/// The Activity panel content for the right-hand panel of expanded
/// windows: an "Activity" title above the [ActivityView].
class ActivityPanel extends StatelessWidget {
  /// Creates the panel content.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.x16,
          Spacing.x16,
          Spacing.x16,
          0,
        ),
        child: Semantics(
          header: true,
          child: Text(
            AppLocalizations.of(context).activityTitle,
            style: context.typography.title.copyWith(
              color: context.colors.content,
            ),
          ),
        ),
      ),
      const Expanded(child: ActivityView()),
    ],
  );
}

/// Opens the Activity sheet over [context], reading the providers of
/// [container], or of [context]'s scope when none is given.
Future<void> showActivitySheet(
  BuildContext context, {
  ProviderContainer? container,
}) {
  final scope = container ?? ProviderScope.containerOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (_) => UncontrolledProviderScope(
      container: scope,
      child: const ActivitySheet(),
    ),
  );
}

/// The content of the Activity sheet: an "Activity" title above the
/// [ActivityView], in a sheet that opens at 70 % of the height.
class ActivitySheet extends StatelessWidget {
  /// Creates the sheet content.
  const new({super.key});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    minChildSize: 0.4,
    builder: (context, scrollController) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x16),
          child: Semantics(
            header: true,
            child: Text(
              AppLocalizations.of(context).activityTitle,
              style: context.typography.title.copyWith(
                color: context.colors.content,
              ),
            ),
          ),
        ),
        Expanded(child: ActivityView(scrollController: scrollController)),
      ],
    ),
  );
}

/// Who is online (doc 08, Social Presence): users of this server and, with
/// federation, of connected servers. Opening it opens the profile's
/// [PresenceController]; leaving it closes it.
class ActivityView extends ConsumerStatefulWidget {
  /// Creates the view; [scrollController] drives its list in a sheet.
  const new({this.scrollController, super.key});

  /// The controller of the list, from a draggable sheet.
  final ScrollController? scrollController;

  /// The edge length of a row's track artwork.
  static const double artworkSize = 40;

  /// The key of the skeleton list shown while the first roster loads.
  static const Key skeletonKey = Key('activity.skeleton');

  @override
  ConsumerState<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends ConsumerState<ActivityView> {
  late final PresenceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(presenceControllerProvider)..open();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reachability =
        ref.watch(reachabilityStateProvider).value ??
        ref.watch(reachabilityProvider).current;
    final federation = ref.watch(
      serverCapabilitiesProvider.select((c) => c.federation),
    );
    if (reachability != Reachability.online) {
      return const ErrorView(error: Offline());
    }
    return StreamBuilder<PresenceState>(
      stream: _controller.states,
      initialData: _controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _controller.state;
        final roster = state.roster;
        if (roster == null) {
          if (state.failed) {
            return ErrorView(
              error: state.error ?? const Offline(),
              onRetry: () => unawaited(_controller.retry()),
            );
          }
          return ListView(
            key: ActivityView.skeletonKey,
            controller: widget.scrollController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 3; i++)
                const TrackRowSkeleton(withThumbnail: true),
            ],
          );
        }
        final peers = federation ? roster.peers : const <OnlinePeerUser>[];
        if (roster.users.isEmpty && peers.isEmpty) {
          return EmptyState(
            icon: Icons.group_outlined,
            message: AppLocalizations.of(context).activityEmpty,
          );
        }
        final l10n = AppLocalizations.of(context);
        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.only(bottom: Spacing.x16),
          children: [
            if (roster.users.isNotEmpty) ...[
              _SectionHeader(l10n.activityOnThisServer),
              for (final user in roster.users)
                _PresenceRow(
                  key: ValueKey('activity.user.${user.id}'),
                  name: user.displayName,
                  status: user.status,
                  nowPlaying: user.nowPlaying,
                ),
            ],
            if (peers.isNotEmpty) ...[
              _SectionHeader(l10n.activityOnConnectedServers),
              for (final peer in peers)
                _PresenceRow(
                  name: peer.displayName,
                  status: peer.status,
                  nowPlaying: peer.nowPlaying,
                  server: peer.peerName,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const new(this.label);

  final String label;

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
        label,
        style: context.typography.overline.copyWith(
          color: context.colors.contentSecondary,
        ),
      ),
    ),
  );
}

/// One online user: initial, name, status and, when shared, the track.
class _PresenceRow extends StatelessWidget {
  const new({
    required this.name,
    required this.status,
    this.nowPlaying,
    this.server,
    super.key,
  });

  final String name;
  final PresenceStatus status;
  final TrackMeta? nowPlaying;
  final String? server;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final statusText = switch (status) {
      PresenceStatus.playing => l10n.activityStatusPlaying,
      PresenceStatus.paused => l10n.activityStatusPaused,
      PresenceStatus.idle => l10n.activityStatusIdle,
    };
    final track = nowPlaying;
    final ownLabel = switch ((status, track)) {
      (PresenceStatus.playing, final TrackMeta t) => l10n.activityRowPlaying(
        name,
        t.title,
        t.artist,
      ),
      (PresenceStatus.paused, final TrackMeta t) => l10n.activityRowPaused(
        name,
        t.title,
        t.artist,
      ),
      _ => l10n.activityRowStatus(name, statusText),
    };
    final server = this.server;
    final label = server == null
        ? ownLabel
        : l10n.activityRowPeer(ownLabel, server);
    final initial = name.trim().isEmpty
        ? ''
        : name.trim().characters.first.toUpperCase();
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x16,
          vertical: Spacing.x8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: Sizes.pointerTarget / 2,
              backgroundColor: colors.surfaceHighlight,
              foregroundColor: colors.content,
              child: Text(
                initial,
                style: typography.body.copyWith(
                  color: colors.content,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: Spacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.copyWith(color: colors.content),
                  ),
                  Text(
                    server == null
                        ? statusText
                        : l10n.activityPeerStatus(statusText, server),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                  if (track != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.x8),
                      child: Row(
                        children: [
                          Artwork(
                            ref: track.artworkRef,
                            size: ActivityView.artworkSize,
                          ),
                          const SizedBox(width: Spacing.x8),
                          Expanded(
                            child: Text(
                              l10n.activityTrack(track.title, track.artist),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodySmall.copyWith(
                                color: colors.contentBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
