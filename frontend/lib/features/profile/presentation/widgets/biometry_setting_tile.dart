import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Biometry on/off row. Owns the enroll/revoke orchestration so the
/// settings sheet stays a pure layout widget.
class BiometrySettingTile extends ConsumerStatefulWidget {
  const BiometrySettingTile({super.key, required this.userId});

  final String? userId;

  @override
  ConsumerState<BiometrySettingTile> createState() =>
      _BiometrySettingTileState();
}

class _BiometrySettingTileState extends ConsumerState<BiometrySettingTile> {
  bool _busy = false;

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (value) {
        await _enable();
      } else {
        await _disable();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enable() async {
    if (widget.userId == null) return _fail();
    final userId = widget.userId!;
    final stepUpToken = await StepUpAuthenticator.authorize(
      context,
      ref,
      purpose: 'biometric_enroll',
    );
    if (stepUpToken == null || !mounted) return;

    try {
      final enrolled = await ref
          .read(authControllerProvider.notifier)
          .enrollBiometrics(stepUpToken, expectedUserId: userId);
      if (!enrolled) _fail();
    } catch (_) {
      _fail();
    }
  }

  Future<void> _disable() async {
    var revoked = false;
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .revokeBiometricToken();
      revoked = result.isRight;
    } catch (_) {
      // Local disable must not depend on network availability.
    } finally {
      try {
        await ref.read(biometryServiceProvider).clearState();
      } finally {
        ref.invalidate(biometryEnabledProvider);
      }
    }
    if (!revoked && mounted) {
      AppSnackbar.warning(
        context,
        l10n(context).profileBiometryRevocationPending,
      );
    }
  }

  void _fail() {
    if (mounted) {
      AppSnackbar.error(context, l10n(context).profileBiometryUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = ref.watch(biometryAvailableProvider).value ?? false;
    final isEnabled = ref.watch(biometryEnabledProvider).value ?? false;

    return ListTile(
      leading: Icon(Icons.fingerprint, color: context.textPrimary),
      title: Text(
        l10n(context).profileBiometry,
        style: TextStyle(color: context.textPrimary),
      ),
      subtitle: Text(
        isAvailable
            ? l10n(context).profileBiometryLogin
            : l10n(context).onboardingUnavailableOnDevice,
        style: TextStyle(color: context.textSecondary),
      ),
      trailing: isAvailable
          ? BrutalistSwitch(value: isEnabled, onChanged: _onChanged)
          : const SizedBox.shrink(),
    );
  }
}
