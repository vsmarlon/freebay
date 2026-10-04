import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/services/apple_auth_nonce.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/biometric_key_service.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum _ProofChoice { password, google, apple, biometric }

typedef _StepUpSelection = ({_ProofChoice choice, String? password});

class StepUpAuthenticator {
  StepUpAuthenticator._();

  static Future<String?> authorize(
    BuildContext context,
    WidgetRef ref, {
    required String purpose,
    String? resourceId,
  }) async {
    final userId = ref.read(authControllerProvider).value?.id;
    if (userId == null) return null;
    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    bool current() =>
        context.mounted &&
        AuthSessionCoordinator.isCurrentAttempt(attempt) &&
        ref.read(authControllerProvider).value?.id == userId;
    final biometry = ref.read(biometryServiceProvider);
    final biometricAvailable =
        await biometry.isEnabled() &&
        await biometry.hasCredentials() &&
        await StorageService.getBiometricOwner() == userId &&
        await BiometricKeyService().hasKey();
    var appleAvailable = false;
    try {
      appleAvailable = await SignInWithApple.isAvailable();
    } catch (_) {
      // Unsupported platforms still offer password authentication.
    }
    if (!current()) return null;
    final selection = await showDialog<_StepUpSelection>(
      context: context,
      builder: (dialogContext) => _StepUpDialog(
        biometricAvailable: biometricAvailable,
        appleAvailable: appleAvailable,
        googleAvailable: AppConfig.googleServerClientId.isNotEmpty,
        onChoose: (selection) => dialogContext.pop(selection),
      ),
    );
    if (selection == null || !current()) return null;

    final Map<String, Object?> proof;
    try {
      switch (selection.choice) {
        case _ProofChoice.password:
          final password = selection.password;
          if (password == null || password.isEmpty) return null;
          proof = {'kind': 'password', 'password': password};
        case _ProofChoice.google:
          await ref
              .read(authControllerProvider.notifier)
              .ensureGoogleSignInInitialized();
          if (!current()) return null;
          if (!GoogleSignIn.instance.supportsAuthenticate()) {
            throw StateError('Interactive Google authentication unavailable');
          }
          final account = await GoogleSignIn.instance.authenticate();
          final idToken = account.authentication.idToken;
          if (idToken == null || idToken.isEmpty) return null;
          proof = {'kind': 'google', 'idToken': idToken};
        case _ProofChoice.apple:
          final rawNonce = generateAppleRawNonce();
          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: const [],
            nonce: hashAppleRawNonce(rawNonce),
          );
          final identityToken = credential.identityToken;
          if (identityToken == null || identityToken.isEmpty) return null;
          proof = {
            'kind': 'apple',
            'identityToken': identityToken,
            'rawNonce': rawNonce,
          };
        case _ProofChoice.biometric:
          final token = await StorageService.getBiometricToken();
          if (!current()) return null;
          if (token == null || token.isEmpty) return null;
          final challenge = await ref
              .read(authRepositoryProvider)
              .createBiometricChallenge(
                token,
                purpose: 'step_up',
                stepUpPurpose: purpose,
                resourceId: resourceId,
              );
          if (challenge.isLeft) {
            if (context.mounted) {
              AppSnackbar.handleFailure(context, challenge.leftOrNull);
            }
            return null;
          }
          if (!current()) return null;
          final signed = await BiometricKeyService().sign(
            challenge.rightOrNull!.challenge,
          );
          proof = {
            'kind': 'biometric',
            'biometricToken': token,
            'challengeId': challenge.rightOrNull!.challengeId,
            'signature': signed,
          };
      }
    } on PlatformException catch (error) {
      if (error.code != 'cancelled' && current()) {
        AppSnackbar.error(context, l10n(context).errorUnknown);
      }
      return null;
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled &&
          error.code != GoogleSignInExceptionCode.interrupted &&
          current()) {
        AppSnackbar.error(context, l10n(context).errorUnknown);
      }
      return null;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code != AuthorizationErrorCode.canceled && current()) {
        AppSnackbar.error(context, l10n(context).errorUnknown);
      }
      return null;
    } catch (_) {
      if (current()) AppSnackbar.error(context, l10n(context).errorUnknown);
      return null;
    }

    if (!current()) return null;
    final result = await ref
        .read(authRepositoryProvider)
        .createStepUp(purpose: purpose, resourceId: resourceId, proof: proof);
    if (!current()) return null;
    if (result.isLeft && context.mounted) {
      AppSnackbar.handleFailure(context, result.leftOrNull);
    }
    return result.rightOrNull;
  }
}

class _StepUpDialog extends StatefulWidget {
  const _StepUpDialog({
    required this.biometricAvailable,
    required this.appleAvailable,
    required this.googleAvailable,
    required this.onChoose,
  });

  final bool biometricAvailable;
  final bool appleAvailable;
  final bool googleAvailable;
  final ValueChanged<_StepUpSelection> onChoose;

  @override
  State<_StepUpDialog> createState() => _StepUpDialogState();
}

class _StepUpDialogState extends State<_StepUpDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return AlertDialog(
      title: Text(strings.stepUpConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _password,
              label: strings.stepUpPassword,
              obscureText: true,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            if (widget.googleAvailable) ...[
              Spacing.vMd,
              AppButton(
                label: strings.stepUpGoogle,
                variant: AppButtonVariant.secondary,
                onPressed: () => widget.onChoose((
                  choice: _ProofChoice.google,
                  password: null,
                )),
              ),
            ],
            if (widget.appleAvailable) ...[
              Spacing.vSm,
              AppButton(
                label: strings.stepUpApple,
                variant: AppButtonVariant.secondary,
                onPressed: () => widget.onChoose((
                  choice: _ProofChoice.apple,
                  password: null,
                )),
              ),
            ],
            if (widget.biometricAvailable) ...[
              Spacing.vSm,
              AppButton(
                label: strings.stepUpBiometrics,
                variant: AppButtonVariant.secondary,
                onPressed: () => widget.onChoose((
                  choice: _ProofChoice.biometric,
                  password: null,
                )),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          label: strings.commonCancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        AppButton(
          label: strings.commonContinue,
          onPressed: _password.text.isEmpty
              ? null
              : () => widget.onChoose((
                  choice: _ProofChoice.password,
                  password: _password.text,
                )),
        ),
      ],
    );
  }
}
