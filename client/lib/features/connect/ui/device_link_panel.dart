// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/device_namer.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/relink.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/widgets/code_cells.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Links this device to the server at [baseUrl] with a code from the web
/// UI's device page (doc 04, Device Link; doc 09, Connect).
///
/// Shows the three steps to get a code, the [CodeCells], a device name
/// prefilled with [DeviceNamer.defaultName] and a Link button enabled once
/// the six cells are filled. A valid [initialCode] (from a link or a QR
/// code) is submitted once, after the panel is first shown. Failures are
/// shown under the cells; a 429 disables Link and counts down on the
/// [Clock]. The linked profile goes to [onLinked]. With [relinkProfile]
/// the code links that profile again ([RelinkUseCase]): its key is
/// replaced and the old one revoked.
class DeviceLinkPanel extends ConsumerStatefulWidget {
  /// Creates the panel for the server at [baseUrl].
  const new({
    required this.baseUrl,
    required this.onLinked,
    this.initialCode,
    this.relinkProfile,
    super.key,
  });

  /// The device-linked profile to link again, or null for a new link.
  final Profile? relinkProfile;

  /// The server to link to.
  final Uri baseUrl;

  /// A code the panel starts with and submits once when it is valid.
  final String? initialCode;

  /// Called with the stored profile once the device is linked.
  final Future<void> Function(Profile profile) onLinked;

  @override
  ConsumerState<DeviceLinkPanel> createState() => _DeviceLinkPanelState();
}

class _DeviceLinkPanelState extends ConsumerState<DeviceLinkPanel> {
  static final AppLogger _log = AppLogger.scope('DeviceLink');

  late final DeviceNamer _namer;
  late final TextEditingController _name;
  DeviceLinkCode? _code;
  bool _busy = false;
  Object? _failure;
  DateTime? _retryAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _namer = DeviceNamer(ref.read(deviceInfoProvider));
    _name = TextEditingController(text: _namer.defaultName());
    final initial = widget.initialCode;
    _code = initial == null ? null : DeviceLinkCode.tryParse(initial);
    if (_code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_submit());
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _name.dispose();
    super.dispose();
  }

  int get _retryInSeconds {
    final retryAt = _retryAt;
    if (retryAt == null) return 0;
    final left = retryAt.difference(ref.read(clockProvider).now());
    return left <= Duration.zero ? 0 : (left.inMilliseconds + 999) ~/ 1000;
  }

  bool get _canSubmit => !_busy && _code != null && _retryInSeconds == 0;

  void _onCodeChanged(String text) {
    final code = DeviceLinkCode.tryParse(text);
    if (code == _code) return;
    setState(() => _code = code);
  }

  Future<void> _submit() async {
    final code = _code;
    if (!_canSubmit || code == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final deviceName = _namer.normalize(_name.text);
      final relink = widget.relinkProfile;
      final profile = relink == null
          ? await ref
                .read(deviceLinkSignInProvider)
                .submit(
                  baseUrl: widget.baseUrl,
                  code: code,
                  deviceName: deviceName,
                )
          : await ref.read(relinkUseCaseProvider).run(relink, code, deviceName);
      if (!mounted) return;
      await widget.onLinked(profile);
    } on DeviceLinkRateLimited catch (error) {
      _retryAt = ref.read(clockProvider).now().add(error.retryAfter);
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } on DeviceLinkFailure catch (error) {
      _failure = error;
    } on ServerTooOld catch (error) {
      _failure = error;
    } on SecretStoreUnavailable catch (error) {
      _log.warning('No secure storage for the device link', const {}, error);
      _failure = error;
    } on ApiException catch (error) {
      _failure = error;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_retryInSeconds == 0) {
      _ticker?.cancel();
      _ticker = null;
      _retryAt = null;
    }
    setState(() {});
  }

  String? _message(AppLocalizations l10n) {
    final wait = _retryInSeconds;
    if (wait > 0) return l10n.connectSignInRateLimited(wait);
    return switch (_failure) {
      DeviceLinkInvalidCode() => l10n.connectDeviceLinkInvalidCode,
      DeviceLinkCodeUsed() => l10n.connectDeviceLinkCodeUsed,
      DeviceLinkCodeExpired() => l10n.connectDeviceLinkCodeExpired,
      DeviceLinkRejected(:final message) =>
        message == null || message.trim().isEmpty
            ? l10n.connectDeviceLinkRejected
            : message,
      ServerTooOld(:final minServer, :final serverVersion) =>
        l10n.connectServerTooOld(minServer, serverVersion),
      SecretStoreUnavailable() => l10n.connectSignInSecureStorage,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = _failure;
    final steps = [
      l10n.connectDeviceLinkStep1,
      l10n.connectDeviceLinkStep2,
      l10n.connectDeviceLinkStep3,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, step) in steps.indexed) ...[
          if (index > 0) const SizedBox(height: Spacing.x8),
          _Step(number: index + 1, text: step),
        ],
        const SizedBox(height: Spacing.x24),
        CodeCells(
          initialValue: widget.initialCode,
          enabled: !_busy,
          errorText: _message(l10n),
          onChanged: _onCodeChanged,
          onCompleted: (_) {},
        ),
        if (failure is ApiException) ...[
          const SizedBox(height: Spacing.x12),
          ErrorView(error: failure, onRetry: () => unawaited(_submit())),
        ],
        const SizedBox(height: Spacing.x24),
        TextField(
          controller: _name,
          enabled: !_busy,
          autocorrect: false,
          maxLength: DeviceNamer.maxLength,
          textInputAction: TextInputAction.go,
          style: context.typography.body.copyWith(
            color: context.colors.content,
          ),
          onSubmitted: (_) => unawaited(_submit()),
          decoration: InputDecoration(
            labelText: l10n.connectDeviceLinkDeviceName,
            counterText: '',
          ),
        ),
        const SizedBox(height: Spacing.x24),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(Sizes.touchTarget),
          ),
          onPressed: _canSubmit ? () => unawaited(_submit()) : null,
          child: Text(l10n.connectDeviceLinkSubmit),
        ),
      ],
    );
  }
}

/// One numbered step of getting a code from the web UI.
class _Step extends StatelessWidget {
  const new({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.body.copyWith(
      color: context.colors.contentBody,
    );
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Spacing.x24,
            child: Text('$number.', style: style),
          ),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
