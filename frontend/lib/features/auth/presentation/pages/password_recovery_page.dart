import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordRecovery(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _step = 2;
        } else {
          _errorMessage =
              'Não foi possível enviar o código. Verifique o e-mail.';
        }
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: _emailController.text.trim(),
          token: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/login');
      } else {
        setState(() {
          _errorMessage = 'Código inválido ou expirado. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistBackground(
      child: SafeArea(
        child: Column(
          children: [
            PageHeader(
              text: 'RECUPERAR SENHA',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: CenteredFormWrapper(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        hint: 'seu@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Informe seu e-mail'
                            : null,
                      ),
                      Spacing.vMd,
                      AnimatedSize(
                        duration: AppMotion.enter,
                        curve: AppMotion.enterCurve,
                        child: _step == 2
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppTextField(
                                    controller: _codeController,
                                    label: 'Código',
                                    hint: '123456',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.verified_outlined,
                                    validator: (v) => v == null || v.length != 6
                                        ? 'Informe o código de 6 dígitos'
                                        : null,
                                  ),
                                  Spacing.vMd,
                                  AppTextField(
                                    controller: _passwordController,
                                    label: 'Nova senha',
                                    hint: 'Mínimo 8 caracteres',
                                    obscureText: true,
                                    showPasswordToggle: true,
                                    prefixIcon: Icons.lock_outline,
                                    validator: (v) => v == null || v.length < 8
                                        ? 'Senha muito curta'
                                        : null,
                                  ),
                                  Spacing.vMd,
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        Spacing.vMd,
                      ],
                      AppButton(
                        label: _step == 2 ? 'Redefinir senha' : 'Enviar código',
                        isLoading: _isLoading,
                        onPressed: _step == 2 ? _resetPassword : _requestCode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
