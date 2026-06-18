import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  final String email;
  const ResetPasswordPage({super.key, required this.token, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthRepository()
        .resetPassword(widget.email, widget.token, _passwordController.text.trim());

    result.fold(
      (failure) {
        if (mounted) {
          setState(() => _errorMessage = failure.message);
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha redefinida com sucesso!')),
          );
          context.go('/login');
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'REDEFINIR SENHA',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    color: AppColors.mediumGray,
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
                    if (v == null || v.isEmpty) return 'Informe a nova senha';
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
                    if (v == null || v.isEmpty) return 'Confirme a nova senha';
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
      ),
    ],
  ),
);
  }
}