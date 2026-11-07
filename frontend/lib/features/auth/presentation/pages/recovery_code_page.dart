import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_header.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class RecoveryCodePage extends ConsumerStatefulWidget {
  const RecoveryCodePage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<RecoveryCodePage> createState() => _RecoveryCodePageState();
}

class _RecoveryCodePageState extends ConsumerState<RecoveryCodePage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final strings = l10n(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final valid = await ref
        .read(authControllerProvider.notifier)
        .verifyPasswordRecoveryCode(widget.email, _codeController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (valid) {
      context.push(
        '${AppRoutes.resetPassword}'
        '?email=${Uri.encodeComponent(widget.email)}'
        '&token=${Uri.encodeComponent(_codeController.text.trim())}',
      );
    } else {
      setState(() => _errorMessage = strings.authRecoveryCodeInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AuthHeader(
                title: strings.authVerificationCode.toUpperCase(),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: CenteredFormWrapper(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacing.vLg,
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/recovery_lock.svg',
                            width: 200,
                          ),
                        ),
                        Spacing.vMd,
                        Text(
                          strings.authRecoveryCodeHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        Spacing.vLg,
                        AppTextField(
                          controller: _codeController,
                          label: strings.authVerificationCode,
                          hint: '123456',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.verified_outlined,
                          validator: (v) => v == null || v.length != 6
                              ? strings.authCodeSixDigitsRequired
                              : null,
                        ),
                        if (_errorMessage != null) ...[
                          Spacing.vMd,
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                        Spacing.vLg,
                        AppButton(
                          label: strings.commonVerify,
                          isLoading: _isLoading,
                          onPressed: _verify,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
