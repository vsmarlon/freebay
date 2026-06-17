import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/components/spacing.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final errorMessage = useState<String?>(null);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) context.go('/feed');
        },
        error: (err, _) {
          errorMessage.value =
              err is String ? err : 'Erro ao criar conta. Tente novamente.';
        },
      );
    });

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crie sua conta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Spacing.vSm,
                Text(
                  'Junte-se à comunidade FreeBay',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumGray,
                  ),
                ),
                Spacing.vXl,
                AppTextField(
                  controller: nameController,
                  label: 'Nome de exibição',
                  hint: 'Seu apelido na plataforma',
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe seu nome';
                    }
                    if (v.trim().length < 2) return 'Nome muito curto';
                    return null;
                  },
                ),
                Spacing.vMd,
                AppTextField(
                  controller: emailController,
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe seu e-mail';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                Spacing.vMd,
                AppTextField(
                  controller: passwordController,
                  label: 'Senha',
                  hint: 'Mínimo 8 caracteres',
                  obscureText: true,
                  showPasswordToggle: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe sua senha';
                    if (v.length < 8) {
                      return 'Senha deve ter pelo menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                Spacing.vMd,
                AppTextField(
                  controller: confirmPasswordController,
                  label: 'Confirmar senha',
                  hint: 'Repita sua senha',
                  obscureText: true,
                  showPasswordToggle: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme sua senha';
                    if (v != passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                Spacing.vLg,
                if (errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorMessage.value!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                AppButton(
                  label: 'Cadastrar',
                  isLoading: authState.isLoading,
                  onPressed: () {
                    errorMessage.value = null;
                    if (formKey.currentState?.validate() ?? false) {
                      ref.read(authControllerProvider.notifier).register(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                            nameController.text.trim(),
                          );
                    }
                  },
                ),
                Spacing.vMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem conta? ',
                      style: TextStyle(
                        color: context.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          'Entrar',
                          style: TextStyle(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
