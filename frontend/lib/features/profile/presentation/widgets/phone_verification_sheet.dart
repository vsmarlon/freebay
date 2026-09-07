import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

void showPhoneVerificationSheet(BuildContext context) {
  showBrutalistSheet(
    context: context,
    title: 'Verificação do Perfil',
    useSafeArea: false,
    padding: const EdgeInsets.all(24),
    builder: (sheetContext) {
      return const _PhoneVerificationView();
    },
  );
}

class _PhoneVerificationView extends HookConsumerWidget {
  const _PhoneVerificationView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState<int>(
      1,
    ); // 1 = Phone Input, 2 = Code Input, 3 = Success
    final phoneController = useTextEditingController();
    final codeController = useTextEditingController();
    final isLoading = useState<bool>(false);

    // Format phone dynamically as the user types
    useEffect(() {
      void listener() {
        final text = phoneController.text;
        final formatted = ValueUtils.formatPhone(text);
        if (formatted != text) {
          phoneController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }

      phoneController.addListener(listener);
      return () => phoneController.removeListener(listener);
    }, [phoneController]);

    Future<void> requestVerificationCode() async {
      final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.length < 10 || phone.length > 11) {
        AppSnackbar.error(
          context,
          'Informe um número de telefone com DDD válido.',
        );
        return;
      }

      isLoading.value = true;
      final repository = ref.read(profileRepositoryProvider);
      final result = await repository.registerPhone(phone);
      isLoading.value = false;

      result.fold((failure) => AppSnackbar.error(context, failure.message), (
        _,
      ) {
        step.value = 2;
        AppSnackbar.success(context, 'Código de verificação enviado por SMS.');
      });
    }

    Future<void> verifyCode() async {
      final code = codeController.text.trim();
      if (code.length != 6) {
        AppSnackbar.error(
          context,
          'O código de verificação deve ter 6 dígitos.',
        );
        return;
      }

      isLoading.value = true;
      final repository = ref.read(profileRepositoryProvider);
      final result = await repository.verifyPhone(code);
      isLoading.value = false;

      result.fold((failure) => AppSnackbar.error(context, failure.message), (
        updatedUser,
      ) {
        // Update local user state
        ref.read(authControllerProvider.notifier).setUser(updatedUser);
        ref.invalidate(profileFutureProvider('me'));
        step.value = 3;
      });
    }

    if (step.value == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verifique sua conta para obter o selo de verificação e passar mais segurança na plataforma.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mediumGray,
              height: 1.4,
            ),
          ),
          Spacing.vLg,
          AppTextField(
            controller: phoneController,
            label: 'Número de celular',
            hint: '(11) 99999-9999',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android,
          ),
          Spacing.vLg,
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Enviar código via SMS',
              isLoading: isLoading.value,
              onPressed: requestVerificationCode,
            ),
          ),
          Spacing.vMd,
        ],
      );
    }

    if (step.value == 2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insira o código de 6 dígitos que enviamos para o número ${phoneController.text}.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mediumGray,
              height: 1.4,
            ),
          ),
          Spacing.vLg,
          AppTextField(
            controller: codeController,
            label: 'Código de verificação',
            hint: '000000',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.lock_open,
          ),
          Spacing.vLg,
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => step.value = 1,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.onSurface, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'Voltar',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Verificar',
                  isLoading: isLoading.value,
                  onPressed: verifyCode,
                ),
              ),
            ],
          ),
          Spacing.vMd,
        ],
      );
    }

    // Success Screen
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified, color: AppColors.primaryContainer, size: 72),
        Spacing.vMd,
        Text(
          'Perfil verificado!',
          style: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        Spacing.vSm,
        const Text(
          'Parabéns! Sua conta agora possui o selo de verificação oficial e você já pode negociar com maior segurança.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mediumGray,
            height: 1.4,
          ),
        ),
        Spacing.vXl,
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Concluir',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Spacing.vMd,
      ],
    );
  }
}
