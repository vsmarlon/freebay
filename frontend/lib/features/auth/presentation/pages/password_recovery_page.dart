import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  ConsumerState<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _requested = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await ref.read(authRepositoryProvider).requestPasswordRecovery(_emailController.text.trim());
    result.fold((failure) {
      setState(() => _message = failure.message);
    }, (_) {
      setState(() {
        _requested = true;
        _message = 'Se o e-mail existir, você receberá um código.';
      });
    });
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final verify = await ref.read(authRepositoryProvider).verifyPasswordRecoveryCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );
    verify.fold((failure) {
      setState(() => _message = failure.message);
    }, (ok) async {
      if (!ok) return;
      final reset = await ref.read(authRepositoryProvider).resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _passwordController.text.trim(),
      );
      reset.fold((failure) {
        setState(() => _message = failure.message);
      }, (_) {
        if (mounted) context.pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Recuperar senha'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  validator: (v) => v == null || v.isEmpty ? 'Informe seu e-mail' : null,
                ),
                const SizedBox(height: 16),
                if (_requested) ...[
                  AppTextField(
                    controller: _codeController,
                    label: 'Código',
                    hint: '123456',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.verified_outlined,
                    validator: (v) => v == null || v.length != 6 ? 'Informe o código de 6 dígitos' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Nova senha',
                    hint: 'Mínimo 8 caracteres',
                    obscureText: true,
                    showPasswordToggle: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => v == null || v.length < 8 ? 'Senha muito curta' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_message != null) ...[
                  Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.white : AppColors.darkGray)),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: _requested ? 'Redefinir senha' : 'Enviar código',
                  onPressed: _requested ? _resetPassword : _requestCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
