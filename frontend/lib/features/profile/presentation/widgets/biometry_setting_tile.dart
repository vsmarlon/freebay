import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';

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
    final biometryService = ref.read(biometryServiceProvider);
    final authenticated = await biometryService.authenticate(
      reason: 'Confirme para ativar login biométrico',
    );
    if (!authenticated) return;

    try {
      final enrollment = await ref
          .read(authRepositoryProvider)
          .enrollBiometricToken();
      if (enrollment.isLeft) return _fail();
      final token = enrollment.rightOrNull;
      if (token == null || token.isEmpty) return _fail();
      if (widget.userId == null) return;
      await StorageService.saveBiometricToken(token);
      await StorageService.saveBiometricOwner(widget.userId!);
      await biometryService.setEnabled(true);
      await biometryService.setHasPrompted(true);
      await StorageService.saveRememberMe(true);
      ref.invalidate(biometryEnabledProvider);
    } catch (_) {
      try {
        await biometryService.clearCredentials();
      } catch (_) {}
      _fail();
    }
  }

  Future<void> _disable() async {
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .revokeBiometricToken();
      if (result.isLeft) return _fail();
      await ref.read(biometryServiceProvider).clearState();
      ref.invalidate(biometryEnabledProvider);
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (mounted) {
      AppSnackbar.error(context, 'Não foi possível atualizar a biometria.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = ref.watch(biometryAvailableProvider).value ?? false;
    final isEnabled = ref.watch(biometryEnabledProvider).value ?? false;

    return ListTile(
      leading: Icon(Icons.fingerprint, color: context.textPrimary),
      title: Text('Biometria', style: TextStyle(color: context.textPrimary)),
      subtitle: Text(
        isAvailable
            ? 'Usar biometria para login'
            : 'Não disponível no dispositivo',
        style: TextStyle(color: context.textSecondary),
      ),
      trailing: isAvailable
          ? BrutalistSwitch(value: isEnabled, onChanged: _onChanged)
          : const SizedBox.shrink(),
    );
  }
}
