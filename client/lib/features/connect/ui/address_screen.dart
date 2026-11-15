// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/features/connect/ui/connect_layout.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

/// Whether a server profile exists, so the address screen can go back.
final Provider<bool> connectHasProfileProvider = Provider<bool>(
  (ref) => (ref.watch(profilesProvider).value ?? const []).isNotEmpty,
);

/// What `/connect/probe` probes: the address as typed and as parsed.
class ProbeRequest {
  /// Creates a request for [address], typed as [input].
  const new({required this.input, required this.address});

  /// The text the user typed, restored by "Edit address".
  final String input;

  /// The parsed address.
  final ServerAddress address;
}

/// `/connect`: the user types a server address (doc 04, Address
/// Normalization).
///
/// Submitting parses the address, asks before plain `http` to a public host,
/// and pushes `/connect/probe` with a [ProbeRequest].
class AddressScreen extends ConsumerStatefulWidget {
  /// Creates the screen with [initialText] in the field.
  const new({this.initialText, super.key});

  /// The screen for the route `extra` [extra]: a [String] or a
  /// [ProbeRequest] puts its text back in the field.
  factory fromExtra(Object? extra) => AddressScreen(
    initialText: switch (extra) {
      final String text => text,
      ProbeRequest(:final input) => input,
      _ => null,
    },
  );

  /// The text the field starts with.
  final String? initialText;

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  );
  ServerAddressError? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _text.text;
    final ServerAddress address;
    try {
      address = ServerAddress.parse(input);
    } on ServerAddressException catch (error) {
      setState(() => _error = error.error);
      return;
    }
    setState(() => _error = null);
    if (address.isPublicCleartext) {
      final allowed = ref
          .read(platformCapabilitiesProvider)
          .allowsPublicCleartextHttp;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _CleartextDialog(
          address: address.candidates.single.toString(),
          allowed: allowed,
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    unawaited(
      GoRouter.of(context).push<void>(
        RoutePaths.probe,
        extra: ProbeRequest(input: input, address: address),
      ),
    );
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.home);
    }
  }

  String? _message(AppLocalizations l10n) => switch (_error) {
    null => null,
    ServerAddressError.empty => l10n.connectAddressEmpty,
    ServerAddressError.unsupportedScheme =>
      l10n.connectAddressUnsupportedScheme,
    ServerAddressError.invalid ||
    ServerAddressError.linkMissingServer => l10n.connectAddressInvalid,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasProfile = ref.watch(connectHasProfileProvider);
    return ConnectLayout(
      screen: l10n.screenConnect,
      leading: hasProfile
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.connectAddressBack,
              onPressed: _back,
            )
          : null,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => unawaited(_submit()),
          decoration: InputDecoration(
            labelText: l10n.connectAddressLabel,
            hintText: l10n.connectAddressHint,
            errorText: _message(l10n),
            errorMaxLines: 3,
            errorStyle: context.typography.subtitle.copyWith(
              color: context.colors.danger,
            ),
          ),
        ),
        const SizedBox(height: Spacing.x24),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(Sizes.touchTarget),
          ),
          onPressed: () => unawaited(_submit()),
          child: Text(l10n.connectAddressSubmit),
        ),
      ],
    );
  }
}

/// Warns before plain `http` to a public host; offers "Connect anyway" only
/// where the platform [allowed] it.
class _CleartextDialog extends StatelessWidget {
  const new({required this.address, required this.allowed});

  final String address;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.connectCleartextTitle),
      content: Text(
        allowed
            ? l10n.connectCleartextBody(address)
            : l10n.connectCleartextBlockedBody(address),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.connectCleartextCancel),
        ),
        if (allowed)
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.connectCleartextConnectAnyway),
          ),
      ],
    );
  }
}
