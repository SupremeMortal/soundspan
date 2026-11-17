// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/probe/probe_failure.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/features/connect/ui/address_screen.dart';
import 'package:soundspan/features/connect/ui/connect_layout.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';

/// This app's origin, which a server must list in `ALLOWED_ORIGINS` for the
/// web app to reach it; empty where the app has no web origin.
final Provider<String> appOriginProvider = Provider<String>((ref) {
  final base = Uri.base;
  return base.isScheme('http') || base.isScheme('https') ? base.origin : '';
});

/// `/connect/probe`: probes the [ProbeRequest]'s address with the
/// [ProbeController] and says, in plain words, what it found (doc 04, Probe
/// and Failure Classification).
///
/// A server found at the address typed continues to `/connect/sign-in`
/// with the [ProbeResult] as the route `extra`. A changed base or a
/// cleartext private host is shown first, with "Continue". A server whose
/// health version is older than the [VersionGate]'s minimum does not
/// continue: the screen says so, with "Try again" and "Edit address"; an
/// unknown version does not block. Leaving the screen cancels the probe.
class ProbeScreen extends ConsumerStatefulWidget {
  /// Creates the screen probing [request].
  const new({required this.request, super.key});

  /// What to probe.
  final ProbeRequest request;

  /// The key of "Continue" on a found server shown before sign-in.
  static const Key continueKey = Key('connect.probe.continue');

  @override
  ConsumerState<ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends ConsumerState<ProbeScreen> {
  late final ProbeController _probe = ref.read(
    probeControllerProvider.notifier,
  );

  /// Whether this screen's run started; the provider holds the previous
  /// run's state until then.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _probe.start(widget.request.address);
      setState(() => _started = true);
    });
  }

  @override
  void dispose() {
    _probe.cancel();
    super.dispose();
  }

  /// Whether a found server is shown before continuing to sign-in.
  static bool _confirms(ProbeResult result) =>
      result.baseChanged || (result.isCleartext && result.isPrivateHost);

  /// The server's version when it is below the supported minimum; null when
  /// it is supported or unknown.
  Version? _tooOld(ProbeResult result) {
    final version = Version.tryParse(result.healthVersion ?? '');
    return ref.read(versionGateProvider).evaluate(version).blocks
        ? version
        : null;
  }

  void _continue(ProbeResult result) =>
      GoRouter.of(context).go(RoutePaths.signIn, extra: result);

  /// Back to `/connect` with the typed text kept.
  void _editAddress() {
    _probe.cancel();
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.connect, extra: widget.request.input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(probeControllerProvider, (_, next) {
      if (!_started) return;
      if (next.value case ProbeReady(:final result)
          when !_confirms(result) && _tooOld(result) == null) {
        _continue(result);
      }
    });
    final state = _started ? ref.watch(probeControllerProvider).value : null;
    final first = widget.request.address.candidates.first;
    return ConnectLayout(
      screen: l10n.screenConnectProbe,
      children: switch (state) {
        null => _progress(l10n.connectProbeResolving(first.toString())),
        ProbeResolving(:final candidate) => _progress(
          l10n.connectProbeResolving(candidate.toString()),
        ),
        ProbeStarting() => [
          _Message(l10n.connectProbeStarting),
          const SizedBox(height: Spacing.x8),
          _Countdown(key: ObjectKey(state)),
          const SizedBox(height: Spacing.x24),
          _secondary(l10n.connectProbeCancel, _editAddress),
        ],
        ProbeReady(:final result) => _ready(l10n, result),
        ProbeNeedsSetup(:final result) => [
          _Message(l10n.connectProbeNeedsSetup),
          const SizedBox(height: Spacing.x24),
          _primary(
            l10n.connectProbeOpenInBrowser,
            () => unawaited(ref.read(urlOpenerProvider).open(result.baseUrl)),
          ),
          const SizedBox(height: Spacing.x8),
          _secondary(l10n.connectProbeTryAgain, _probe.retry),
          _secondary(l10n.connectProbeEditAddress, _editAddress),
        ],
        ProbeFailed(:final failure) => _failed(l10n, failure),
      },
    );
  }

  List<Widget> _progress(String message) => [
    const Center(child: CircularProgressIndicator()),
    const SizedBox(height: Spacing.x24),
    _Message(message),
    const SizedBox(height: Spacing.x24),
    _secondary(AppLocalizations.of(context).connectProbeCancel, _editAddress),
  ];

  List<Widget> _ready(AppLocalizations l10n, ProbeResult result) {
    final tooOld = _tooOld(result);
    if (tooOld != null) {
      return [
        _Message(
          l10n.connectServerTooOld(
            ref.read(versionGateProvider).min.toString(),
            tooOld.toString(),
          ),
        ),
        const SizedBox(height: Spacing.x24),
        _primary(l10n.connectProbeTryAgain, _probe.retry),
        const SizedBox(height: Spacing.x8),
        _secondary(l10n.connectProbeEditAddress, _editAddress),
      ];
    }
    final base = result.baseUrl.toString();
    final cleartext = result.isCleartext && result.isPrivateHost;
    return [
      _Message(
        result.baseChanged
            ? l10n.connectProbeUsing(base)
            : l10n.connectProbeConnected(base),
      ),
      if (cleartext) ...[
        const SizedBox(height: Spacing.x12),
        Center(child: _NotEncryptedChip(label: l10n.connectProbeNotEncrypted)),
      ],
      const SizedBox(height: Spacing.x24),
      _primary(
        l10n.connectProbeContinue,
        () => _continue(result),
        key: ProbeScreen.continueKey,
      ),
      const SizedBox(height: Spacing.x8),
      _secondary(l10n.connectProbeEditAddress, _editAddress),
    ];
  }

  List<Widget> _failed(AppLocalizations l10n, ProbeFailure failure) {
    final colors = context.colors;
    final cors = failure.failureClass == ProbeFailureClass.corsOrNetwork;
    return [
      Center(
        child: ExcludeSemantics(
          child: Icon(
            Icons.error_outline_rounded,
            size: Spacing.x48,
            color: colors.danger,
          ),
        ),
      ),
      const SizedBox(height: Spacing.x16),
      _Message(failureMessage(l10n, failure.failureClass)),
      const SizedBox(height: Spacing.x8),
      Text(
        l10n.connectProbeTried(failure.candidate.toString()),
        textAlign: TextAlign.center,
        style: context.typography.body.copyWith(color: colors.contentBody),
      ),
      if (cors) ...[
        const SizedBox(height: Spacing.x16),
        _OriginField(origin: ref.watch(appOriginProvider)),
      ],
      const SizedBox(height: Spacing.x24),
      _primary(l10n.connectProbeTryAgain, _probe.retry),
      const SizedBox(height: Spacing.x8),
      _secondary(l10n.connectProbeEditAddress, _editAddress),
    ];
  }

  Widget _primary(String label, VoidCallback onPressed, {Key? key}) =>
      FilledButton(
        key: key,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Sizes.touchTarget),
        ),
        onPressed: onPressed,
        child: Text(label),
      );

  Widget _secondary(String label, VoidCallback onPressed) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size.fromHeight(Sizes.touchTarget),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

/// The message of [failureClass] (doc 04, Failure Classification). No
/// failure text is taken from the server.
String failureMessage(AppLocalizations l10n, ProbeFailureClass failureClass) =>
    switch (failureClass) {
      ProbeFailureClass.dns => l10n.connectProbeDns,
      ProbeFailureClass.refused => l10n.connectProbeRefused,
      ProbeFailureClass.timeout => l10n.connectProbeTimeout,
      ProbeFailureClass.tls => l10n.connectProbeTls,
      ProbeFailureClass.blockedByProxy => l10n.connectProbeBlockedByProxy,
      ProbeFailureClass.notSoundspan => l10n.connectProbeNotSoundspan,
      ProbeFailureClass.serverError => l10n.connectProbeServerError,
      ProbeFailureClass.redirectRefused => l10n.connectProbeRedirectRefused,
      ProbeFailureClass.corsOrNetwork => l10n.connectProbeCorsOrNetwork,
    };

/// The screen's message, announced when it changes.
class _Message extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.typography.subtitle.copyWith(
        color: context.colors.content,
      ),
    ),
  );
}

/// Seconds until the next attempt while the server is starting; a new
/// [ProbeStarting] (a new key) starts it again.
class _Countdown extends StatefulWidget {
  const new({super.key});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  int _seconds = ServerProbe.startingRetry.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).connectProbeStartingRetry(_seconds),
    textAlign: TextAlign.center,
    style: context.typography.body.tabular.copyWith(
      color: context.colors.contentSecondary,
    ),
  );
}

/// The passive warning on a server reached over plain `http` on the local
/// network.
class _NotEncryptedChip extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Chip(
      avatar: ExcludeSemantics(
        child: Icon(Icons.lock_open_rounded, color: colors.warning),
      ),
      label: Text(
        label,
        style: context.typography.caption.copyWith(color: colors.warning),
      ),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.warning),
      shape: Radii.pill,
    );
  }
}

/// This app's origin in a read-only field with a Copy button, for the
/// server's `ALLOWED_ORIGINS`.
class _OriginField extends StatefulWidget {
  const new({required this.origin});

  final String origin;

  @override
  State<_OriginField> createState() => _OriginFieldState();
}

class _OriginFieldState extends State<_OriginField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.origin,
  );

  @override
  void didUpdateWidget(_OriginField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin) _text.text = widget.origin;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            readOnly: true,
            decoration: InputDecoration(labelText: l10n.connectProbeOrigin),
          ),
        ),
        const SizedBox(width: Spacing.x8),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
          ),
          onPressed: () =>
              unawaited(Clipboard.setData(ClipboardData(text: widget.origin))),
          child: Text(l10n.connectProbeCopyOrigin),
        ),
      ],
    );
  }
}
