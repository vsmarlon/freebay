import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthRepository().requestPasswordRecovery(_emailController.text.trim());

    result.fold(
      (failure) {
        if (mounted) {
          setState(() => _errorMessage = failure.message);
        }
      },
      (_) {
        if (mounted) setState(() => _sent = true);
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
      appBar: AppBar(
        title: const Text('Esqueceu a senha?'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccessState() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Redefinir senha',
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          Spacing.vSm,
          Text(
            'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
          ),
          Spacing.vXl,
          AppTextField(
            controller: _emailController,
            label: 'E-mail',
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe seu e-mail';
              if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
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
            label: 'Enviar link',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Spacing.vXxl,
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.success,
        ),
        Spacing.vLg,
        Text(
          'E-mail enviado',
          style: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Spacing.vSm,
        Text(
          'Se este e-mail estiver cadastrado, você receberá um link em breve. Verifique também sua caixa de spam.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            color: AppColors.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
        Spacing.vXl,
        AppButton(
          label: 'Voltar ao login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}