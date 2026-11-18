// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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
import 'package:soundspan/core/realtime/socket_client.dart'
    show SocketConnectionState;
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/listen_together_controller.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_view_model.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';
import 'package:soundspan/shared/widgets/detail_header.dart' show pageGutter;
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show ApiException, Conflict, NotFound, Offline;

/// The longest group name the server accepts.
const int maxGroupNameLength = 80;

/// The longest join code the server accepts.
const int maxJoinCodeLength = 64;

/// Listen Together (`/listen-together`, inside the selected branch; doc 08,
/// Listen Together; doc 09, Shell by Window Class).
///
/// In no group it is the lobby: the user's group and the public groups,
/// "Create group" and "Join with a code". While joining, in a group and
/// while leaving it is the group view: its name, visibility, host and
/// connection, the join code, the members, the current track and the
/// Leave and (for the host) End actions. After a group ends the lobby
/// shows why.
class ListenTogetherScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  /// The key of "Create group".
  static const Key createKey = ValueKey('ListenTogether.create');

  /// The key of "Join with a code".
  static const Key joinWithCodeKey = ValueKey('ListenTogether.joinWithCode');

  /// The key of the name field of the create form.
  static const Key nameFieldKey = ValueKey('ListenTogether.name');

  /// The key of the queue switch of the create form.
  static const Key queueSwitchKey = ValueKey('ListenTogether.queueSwitch');

  /// The key of the code field of the join form.
  static const Key codeFieldKey = ValueKey('ListenTogether.code');

  /// The key of "Copy code".
  static const Key copyCodeKey = ValueKey('ListenTogether.copyCode');

  /// The key of "Leave group".
  static const Key leaveKey = ValueKey('ListenTogether.leave');

  /// The key of "End group for everyone".
  static const Key endKey = ValueKey('ListenTogether.end');

  /// The key of "Open queue".
  static const Key openQueueKey = ValueKey('ListenTogether.openQueue');

  /// The key of the row of member [userId].
  static Key memberKey(String userId) =>
      ValueKey('ListenTogether.member.$userId');

  /// The key of the Join button of group [groupId] in the lobby.
  static Key joinGroupKey(String groupId) =>
      ValueKey('ListenTogether.join.$groupId');

  @override
  ConsumerState<ListenTogetherScreen> createState() =>
      _ListenTogetherScreenState();
}

class _ListenTogetherScreenState extends ConsumerState<ListenTogetherScreen> {
  /// The group last shown, kept so leaving still shows it.
  Group? _lastGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state =
        ref.watch(listenTogetherStateProvider).value ??
        const ListenTogetherIdle();
    if (state is ListenTogetherActive) _lastGroup = state.group;
    if (state is ListenTogetherIdle || state is ListenTogetherEnded) {
      _lastGroup = null;
    }
    final lastGroup = _lastGroup;
    final Widget body = switch (state) {
      ListenTogetherActive(:final group) => _GroupView(group: group),
      ListenTogetherLeaving() when lastGroup != null => _GroupView(
        group: lastGroup,
        busy: true,
      ),
      ListenTogetherEnded(:final reason) => _Lobby(ended: reason),
      ListenTogetherJoining() ||
      ListenTogetherLeaving() => const _Lobby(busy: true),
      ListenTogetherIdle() => const _Lobby(),
    };
    return RouteTitle(
      screen: l10n.listenTogetherTitle,
      child: Scaffold(
        appBar: WindowClass.of(context) == WindowClass.compact
            ? AppBar(
                title: Text(l10n.listenTogetherTitle),
                actions: const [AvatarButton()],
              )
            : null,
        body: body,
      ),
    );
  }
}

/// Runs [action] and shows why it failed in a snackbar (doc 02, Error
/// Model): `NotFound` as "No group with that code" when [notFound] says
/// so, `Conflict` with the server's message, `Offline` as the standard
/// offline message, and anything else as [ErrorView] words it.
Future<void> _run(
  BuildContext context,
  Future<void> Function() action, {
  String? notFound,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action();
  } on Object catch (error) {
    final message = switch (error) {
      NotFound() when notFound != null => notFound,
      Conflict(:final serverMessage?) => serverMessage,
      Offline() => l10n.errorViewOffline,
      ApiException() => errorMessageOf(l10n, error),
      _ => l10n.errorViewGeneric,
    };
    if (message.isEmpty) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Asks for the lobby's groups again.
class _RefreshIntent extends Intent {
  const new();
}

/// The lobby: the user's group and the public groups with Join buttons,
/// "Create group" and "Join with a code". While [busy] (joining) every
/// action is disabled; [ended] says why the last group stopped.
class _Lobby extends ConsumerWidget {
  const new({this.busy = false, this.ended});

  final bool busy;
  final GroupEndReason? ended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gutter = pageGutter(WindowClass.of(context));
    final reachability =
        ref.watch(reachabilityStateProvider).value ??
        ref.watch(reachabilityProvider).current;
    final offline = reachability != Reachability.online;
    final lobby = ref.watch(listenTogetherLobbyProvider);
    final enabled = !busy && !offline;
    Future<void> refresh() => ref.refresh(listenTogetherLobbyProvider.future);
    final controller = ref.read(listenTogetherControllerProvider);

    Future<void> join(String code) =>
        _run(context, () => controller.joinByCode(code));

    final List<Widget> content;
    if (offline) {
      content = [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(error: Offline()),
        ),
      ];
    } else if (lobby.value case final value?) {
      final mine = value.mine;
      final discovered = [
        for (final summary in value.discover)
          if (summary.id != mine?.id) summary,
      ];
      content = [
        if (mine != null) ...[
          _SectionTitle(l10n.listenTogetherYourGroups),
          SliverToBoxAdapter(
            child: _GroupRow(
              id: mine.id,
              name: mine.name,
              host: _hostName(mine),
              memberCount: mine.members.length,
              onJoin: enabled ? () => unawaited(join(mine.joinCode)) : null,
            ),
          ),
        ],
        if (discovered.isNotEmpty) ...[
          _SectionTitle(l10n.listenTogetherPublicGroups),
          SliverList.builder(
            itemCount: discovered.length,
            itemBuilder: (context, index) {
              final summary = discovered[index];
              return _GroupRow(
                id: summary.id,
                name: summary.name,
                host: summary.hostUsername,
                memberCount: summary.memberCount,
                onJoin: enabled
                    ? () => unawaited(join(summary.joinCode))
                    : null,
              );
            },
          ),
        ],
        if (mine == null && discovered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.groups_rounded,
              message: l10n.listenTogetherEmpty,
            ),
          ),
      ];
    } else if (lobby.error case final error?) {
      content = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(error: error, onRetry: () => unawaited(refresh())),
        ),
      ];
    } else {
      content = const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.f5): _RefreshIntent(),
      },
      child: Actions(
        actions: {
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (_) => offline ? null : refresh(),
          ),
        },
        child: Focus(
          autofocus: true,
          // Holds focus for the screen's keys; never a Tab stop or ringed.
          skipTraversal: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (busy) const LinearProgressIndicator(),
              if (ended case final reason?)
                AppBanner(
                  kind: AppBannerKind.serverNotice,
                  message: switch (reason) {
                    GroupEndReason.ended => l10n.listenTogetherEndedByHost,
                    GroupEndReason.membershipRevoked =>
                      l10n.listenTogetherRemoved,
                  },
                ),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: offline ? () async {} : refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          Spacing.x24,
                          gutter,
                          Spacing.x8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  l10n.listenTogetherTitle,
                                  style: context.typography.headline.copyWith(
                                    color: context.colors.content,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacing.x16),
                              Wrap(
                                spacing: Spacing.x8,
                                runSpacing: Spacing.x8,
                                children: [
                                  FilledButton.icon(
                                    key: ListenTogetherScreen.createKey,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(
                                        0,
                                        Sizes.touchTarget,
                                      ),
                                    ),
                                    onPressed: enabled
                                        ? () => unawaited(_create(context, ref))
                                        : null,
                                    icon: const Icon(Icons.add_rounded),
                                    label: Text(l10n.listenTogetherCreate),
                                  ),
                                  OutlinedButton.icon(
                                    key: ListenTogetherScreen.joinWithCodeKey,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(
                                        0,
                                        Sizes.touchTarget,
                                      ),
                                    ),
                                    onPressed: enabled
                                        ? () => unawaited(
                                            _joinWithCode(context, ref),
                                          )
                                        : null,
                                    icon: const Icon(Icons.login_rounded),
                                    label: Text(
                                      l10n.listenTogetherJoinWithCode,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...content,
                      const SliverToBoxAdapter(
                        child: SizedBox(height: Spacing.x32),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final hasQueue =
        ref.read(playbackControllerProvider).snapshot.current != null;
    final request = await showCreateGroupForm(context, hasQueue: hasQueue);
    if (request == null || !context.mounted) return;
    final controller = ref.read(listenTogetherControllerProvider);
    await _run(
      context,
      () => controller.createGroup(
        name: request.name,
        visibility: request.visibility,
        fromCurrentQueue: request.fromCurrentQueue,
      ),
    );
  }

  Future<void> _joinWithCode(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final code = await showJoinGroupForm(context);
    if (code == null || !context.mounted) return;
    final controller = ref.read(listenTogetherControllerProvider);
    await _run(
      context,
      () => controller.joinByCode(code),
      notFound: l10n.listenTogetherNoGroupWithCode,
    );
  }
}

/// The username of [group]'s host, or an empty string when the host is not
/// among its members.
String _hostName(Group group) =>
    group.members
        .firstWhereOrNull((member) => member.userId == group.hostUserId)
        ?.username ??
    '';

/// A section title in the page's gutter.
class _SectionTitle extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(WindowClass.of(context));
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x24, gutter, Spacing.x8),
      sliver: SliverToBoxAdapter(
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
    );
  }
}

/// One group in the lobby: name, host and member count, and Join.
class _GroupRow extends StatelessWidget {
  const new({
    required this.id,
    required this.name,
    required this.host,
    required this.memberCount,
    required this.onJoin,
  });

  final String id;
  final String name;
  final String host;
  final int memberCount;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final gutter = pageGutter(WindowClass.of(context));
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: gutter),
      minTileHeight: Sizes.touchTarget,
      leading: Icon(Icons.groups_rounded, color: colors.contentSecondary),
      title: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.typography.body.copyWith(color: colors.content),
      ),
      subtitle: Text(
        l10n.listenTogetherGroupRowDetails(host, memberCount),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.typography.bodySmall.copyWith(
          color: colors.contentSecondary,
        ),
      ),
      trailing: OutlinedButton(
        key: ListenTogetherScreen.joinGroupKey(id),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, Sizes.touchTarget),
        ),
        onPressed: onJoin,
        child: Text(l10n.listenTogetherJoin),
      ),
    );
  }
}

/// What the create form asks the controller for.
typedef CreateGroupRequest = ({
  String? name,
  GroupVisibility visibility,
  bool fromCurrentQueue,
});

/// Shows the create group form: a bottom sheet on compact windows, a
/// dialog otherwise. Completes with the request, or null when cancelled.
/// The queue switch shows only when [hasQueue], on by default.
Future<CreateGroupRequest?> showCreateGroupForm(
  BuildContext context, {
  required bool hasQueue,
}) {
  final form = _CreateGroupForm(hasQueue: hasQueue);
  if (WindowClass.of(context) == WindowClass.compact) {
    return showModalBottomSheet<CreateGroupRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: SafeArea(child: form),
      ),
    );
  }
  return showDialog<CreateGroupRequest>(
    context: context,
    builder: (dialog) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: form,
      ),
    ),
  );
}

class _CreateGroupForm extends StatefulWidget {
  const new({required this.hasQueue});

  final bool hasQueue;

  @override
  State<_CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<_CreateGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  GroupVisibility _visibility = GroupVisibility.private;
  late bool _fromQueue = widget.hasQueue;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    Navigator.of(context).pop<CreateGroupRequest>((
      name: name.isEmpty ? null : name,
      visibility: _visibility,
      fromCurrentQueue: widget.hasQueue && _fromQueue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.x24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.listenTogetherCreate,
              style: context.typography.title.copyWith(color: colors.content),
            ),
            const SizedBox(height: Spacing.x16),
            TextFormField(
              key: ListenTogetherScreen.nameFieldKey,
              controller: _name,
              autofocus: true,
              maxLength: maxGroupNameLength,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              decoration: InputDecoration(
                labelText: l10n.listenTogetherNameLabel,
              ),
              validator: (value) =>
                  (value ?? '').trim().characters.length > maxGroupNameLength
                  ? l10n.listenTogetherNameTooLong
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Spacing.x8),
            SegmentedButton<GroupVisibility>(
              segments: [
                ButtonSegment(
                  value: GroupVisibility.private,
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: Text(l10n.listenTogetherPrivate),
                ),
                ButtonSegment(
                  value: GroupVisibility.public,
                  icon: const Icon(Icons.public_rounded),
                  label: Text(l10n.listenTogetherPublic),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (selection) =>
                  setState(() => _visibility = selection.single),
            ),
            if (widget.hasQueue) ...[
              const SizedBox(height: Spacing.x8),
              SwitchListTile(
                key: ListenTogetherScreen.queueSwitchKey,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.listenTogetherStartWithQueue),
                value: _fromQueue,
                onChanged: (value) => setState(() => _fromQueue = value),
              ),
            ],
            const SizedBox(height: Spacing.x16),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: Spacing.x8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.listenTogetherCancel),
                ),
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.listenTogetherCreateSubmit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the join form: a code field, trimmed and upper-cased as typed, at
/// most [maxJoinCodeLength] characters. Completes with the code, or null
/// when cancelled.
Future<String?> showJoinGroupForm(BuildContext context) => showDialog<String>(
  context: context,
  builder: (dialog) => const _JoinGroupForm(),
);

class _JoinGroupForm extends StatefulWidget {
  const new();

  @override
  State<_JoinGroupForm> createState() => _JoinGroupFormState();
}

class _JoinGroupFormState extends State<_JoinGroupForm> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _trimmed => _code.text.trim();

  void _submit() {
    if (_trimmed.isEmpty) return;
    Navigator.of(context).pop(_trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.listenTogetherJoinWithCode),
      content: TextField(
        key: ListenTogetherScreen.codeFieldKey,
        controller: _code,
        autofocus: true,
        maxLength: maxJoinCodeLength,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: const [UpperCaseTextFormatter()],
        decoration: InputDecoration(labelText: l10n.listenTogetherCodeLabel),
        style: context.typography.mono,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.listenTogetherCancel),
        ),
        FilledButton(
          onPressed: _trimmed.isEmpty ? null : _submit,
          child: Text(l10n.listenTogetherJoin),
        ),
      ],
    );
  }
}

/// Upper-cases text as it is typed.
class UpperCaseTextFormatter extends TextInputFormatter {
  /// Creates the formatter.
  const new();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// A joined group: header, join code, members, the current track and the
/// actions, in that traversal order. While [busy] (leaving) every action
/// is disabled.
class _GroupView extends ConsumerWidget {
  const new({required this.group, this.busy = false});

  final Group group;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final gutter = pageGutter(WindowClass.of(context));
    final controller = ref.read(listenTogetherControllerProvider);
    final isHost = controller.userId == group.hostUserId;
    final connected =
        (ref.watch(listenTogetherConnectionProvider).value ??
            SocketConnectionState.connected) ==
        SocketConnectionState.connected;
    final playback = group.playback;
    final current =
        playback.currentIndex >= 0 &&
            playback.currentIndex < playback.queue.length
        ? playback.queue[playback.currentIndex]
        : null;
    final hostName = _hostName(group);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Spacing.x24, bottom: Spacing.x8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: typography.title.copyWith(color: colors.content),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              Spacing.x24,
              gutter,
              Spacing.x32,
            ),
            children: [
              FocusTraversalGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        group.name,
                        style: typography.headline.copyWith(
                          color: colors.content,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.x4),
                    Text(
                      switch (group.visibility) {
                        GroupVisibility.public =>
                          l10n.listenTogetherPublicGroup,
                        GroupVisibility.private =>
                          l10n.listenTogetherPrivateGroup,
                      },
                      style: typography.body.copyWith(
                        color: colors.contentSecondary,
                      ),
                    ),
                    if (hostName.isNotEmpty)
                      Text(
                        l10n.listenTogetherHostedBy(hostName),
                        style: typography.body.copyWith(
                          color: colors.contentSecondary,
                        ),
                      ),
                    if (!connected)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.listenTogetherReconnecting,
                          style: typography.bodySmall.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.x16),
              FocusTraversalGroup(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Spacing.x16,
                  runSpacing: Spacing.x8,
                  children: [
                    SelectableText(
                      group.joinCode,
                      style: typography.mono.copyWith(color: colors.content),
                    ),
                    TextButton.icon(
                      key: ListenTogetherScreen.copyCodeKey,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, Sizes.touchTarget),
                      ),
                      onPressed: () => unawaited(_copyCode(context)),
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(l10n.listenTogetherCopyCode),
                    ),
                  ],
                ),
              ),
              FocusTraversalGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    section(l10n.listenTogetherMembers),
                    for (final member in group.members)
                      _MemberRow(
                        key: ListenTogetherScreen.memberKey(member.userId),
                        member: member,
                        isHost: member.userId == group.hostUserId,
                      ),
                  ],
                ),
              ),
              FocusTraversalGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (current != null) ...[
                      section(l10n.listenTogetherNowPlaying),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        minTileHeight: Sizes.touchTarget,
                        leading: Icon(
                          Icons.music_note_rounded,
                          color: colors.contentSecondary,
                        ),
                        title: Text(
                          current.meta.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.body.copyWith(
                            color: colors.content,
                          ),
                        ),
                        subtitle: Text(
                          current.meta.artist,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: colors.contentSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.x16),
                    Wrap(
                      spacing: Spacing.x8,
                      runSpacing: Spacing.x8,
                      children: [
                        OutlinedButton.icon(
                          key: ListenTogetherScreen.openQueueKey,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, Sizes.touchTarget),
                          ),
                          onPressed: busy
                              ? null
                              : () => _openQueue(context, ref),
                          icon: const Icon(Icons.queue_music_rounded),
                          label: Text(l10n.listenTogetherOpenQueue),
                        ),
                        FilledButton.icon(
                          key: ListenTogetherScreen.leaveKey,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, Sizes.touchTarget),
                          ),
                          onPressed: busy
                              ? null
                              : () =>
                                    unawaited(_run(context, controller.leave)),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.listenTogetherLeave),
                        ),
                        if (isHost)
                          TextButton.icon(
                            key: ListenTogetherScreen.endKey,
                            style: TextButton.styleFrom(
                              foregroundColor: colors.danger,
                              minimumSize: const Size(0, Sizes.touchTarget),
                            ),
                            onPressed: busy
                                ? null
                                : () => unawaited(_end(context, ref)),
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: Text(l10n.listenTogetherEnd),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final view = View.of(context);
    final direction = Directionality.of(context);
    await Clipboard.setData(ClipboardData(text: group.joinCode));
    await SemanticsService.sendAnnouncement(
      view,
      l10n.listenTogetherCopied,
      direction,
    );
  }

  void _openQueue(BuildContext context, WidgetRef ref) {
    if (WindowClass.of(context) == WindowClass.expanded) {
      if (ref.read(rightPanelProvider) != RightPanel.queue) {
        ref.read(rightPanelProvider.notifier).toggle(RightPanel.queue);
      }
      return;
    }
    unawaited(showQueueSheet(context));
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.listenTogetherEndTitle),
        content: Text(l10n.listenTogetherEndBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.listenTogetherCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: colors.onAccent,
            ),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.listenTogetherEndConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final controller = ref.read(listenTogetherControllerProvider);
    await _run(context, controller.endGroup);
  }
}

/// One member: avatar initial, name and "Host"; muted while the member is
/// not connected.
class _MemberRow extends StatelessWidget {
  const new({required this.member, required this.isHost, super.key});

  final GroupMember member;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final name = member.username.trim();
    final textColor = member.isConnected
        ? colors.content
        : colors.contentSecondary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: Sizes.touchTarget,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: member.isConnected ? colors.accent : colors.line,
        foregroundColor: member.isConnected
            ? colors.onAccent
            : colors.contentSecondary,
        child: ExcludeSemantics(
          child: Text(
            name.isEmpty ? '' : name.characters.first.toUpperCase(),
            style: typography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: member.isConnected
                  ? colors.onAccent
                  : colors.contentSecondary,
            ),
          ),
        ),
      ),
      title: Text(
        member.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.body.copyWith(color: textColor),
      ),
      trailing: isHost
          ? Text(
              l10n.listenTogetherHost,
              style: typography.bodySmall.copyWith(
                color: colors.contentSecondary,
              ),
            )
          : null,
    );
  }
}
