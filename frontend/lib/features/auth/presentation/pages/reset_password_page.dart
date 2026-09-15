import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String token;
  final String email;
  const ResetPasswordPage({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: widget.email,
          token: widget.token,
          newPassword: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go(AppRoutes.login);
      } else {
        setState(() {
          _errorMessage =
              'Não foi possível redefinir sua senha. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'REDEFINIR SENHA',
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
                      Text(
                        'Crie uma nova senha',
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Spacing.vSm,
                      Text(
                        'Escolha uma senha forte com pelo menos 8 caracteres.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                      Spacing.vXl,
                      AppTextField(
                        controller: _passwordController,
                        label: 'Nova senha',
                        hint: 'Mínimo 8 caracteres',
                        obscureText: true,
                        showPasswordToggle: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe a nova senha';
                          }
                          if (v.length < 8) return 'Mínimo 8 caracteres';
                          return null;
                        },
                      ),
                      Spacing.vMd,
                      AppTextField(
                        controller: _confirmController,
                        label: 'Confirmar nova senha',
                        hint: 'Repita a nova senha',
                        obscureText: true,
                        showPasswordToggle: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirme a nova senha';
                          }
                          if (v != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      Spacing.vLg,
                      AppButton(
                        label: 'Redefinir senha',
                        isLoading: _isLoading,
                        onPressed: _submit,
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
