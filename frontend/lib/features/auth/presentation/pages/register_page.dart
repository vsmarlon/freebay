import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../../data/entities/user_entity.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final errorMessage = useState<String?>(null);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) context.go('/feed');
        },
        error: (err, _) {
          errorMessage.value = err is String ? err : 'Erro ao criar conta. Tente novamente.';
        },
      );
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Junte-se à comunidade FreeBay',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                AppTextField(
                  controller: passwordController,
                  label: 'Senha',
                  hint: 'Mínimo 8 caracteres',
                  obscureText: true,
                  showPasswordToggle: true,
                  clearOnFocusLost: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe sua senha';
                    if (v.length < 8) {
                      return 'Senha deve ter pelo menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorMessage.value!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 13),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem conta? ',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    AppButton(
                      label: 'Entrar',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => context.pop(),
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
