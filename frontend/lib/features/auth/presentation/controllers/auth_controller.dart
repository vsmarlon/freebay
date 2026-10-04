import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_dependencies.dart';
import 'package:freebay/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/register_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/verify_password_recovery_code_usecase.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/biometric_key_service.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/features/auth/data/services/apple_auth_nonce.dart';
import 'package:freebay/shared/services/notification_service.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/social/presentation/providers/comment_likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/stories/stories.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/post_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';

export 'auth_dependencies.dart';

part 'auth_google_authentication.dart';
part 'auth_session_lifecycle.dart';

const String _googleGenericError =
    'Não foi possível entrar com o Google. Tente novamente.';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<UserEntity?>>(
      AuthController.new,
    );

class AuthController extends Notifier<AsyncValue<UserEntity?>>
    with AuthSessionLifecycle, AuthGoogleAuthentication {
  Future<bool> enrollBiometrics(
    String stepUpToken, {
    required String expectedUserId,
  }) {
    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    return AuthSessionCoordinator.serialize(() async {
      bool current() =>
          ref.mounted &&
          AuthSessionCoordinator.isCurrentAttempt(attempt) &&
          state.value?.id == expectedUserId;
      if (!current()) return false;
      final biometry = ref.read(biometryServiceProvider);
      var installed = false;
      try {
        final publicKey = await BiometricKeyService().generatePublicKey();
        if (!current()) return false;
        final result = await ref
            .read(authRepositoryProvider)
            .enrollBiometricToken(
              stepUpToken: stepUpToken,
              publicKey: publicKey,
            );
        final token = result.rightOrNull;
        if (!current() || token == null || token.isEmpty) return false;
        await StorageService.saveBiometricToken(token);
        if (!current()) return false;
        await StorageService.saveBiometricOwner(expectedUserId);
        if (!current()) return false;
        await biometry.setHasPrompted(true);
        await StorageService.saveRememberMe(true);
        if (!current()) return false;
        await biometry.setEnabled(true);
        installed = current();
        return installed;
      } catch (_) {
        return false;
      } finally {
        if (!installed) {
          await biometry.clearState();
        }
        if (ref.mounted) ref.invalidate(biometryEnabledProvider);
      }
    });
  }

  @override
  AsyncValue<UserEntity?> build() {
    final attempt = AuthSessionCoordinator.beginAuthentication();
    Future.microtask(() => _initAuth(attempt));
    return const AsyncValue.loading();
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final attempt = AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.loading();
    final request = ref.read(loginUsecaseProvider)(
      LoginParams(
        email: email,
        password: password,
        rememberMe: rememberMe,
        authenticationAttempt: attempt,
      ),
    );
    final result = await request;
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
    await _completeCredentialAuth(result, attempt: attempt);
  }

  Future<bool> loginWithBiometrics() async {
    final attempt = AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.loading();
    final request = ref.read(biometricLoginUsecaseProvider)(attempt);
    final result = await request;
    if (!ref.mounted) return false;
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return false;
    return await result.fold<Future<bool>>(
      (failure) async {
        HttpClient.suspendRefresh();
        await StorageService.clearTokens();
        state = const AsyncValue.data(null);
        return false;
      },
      (user) async {
        await _establishAuthenticatedSession(user, attempt: attempt);
        routerRefreshNotifier.value++;
        return true;
      },
    );
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
    String username,
  ) async {
    final attempt = AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.loading();
    final request = ref.read(registerUsecaseProvider)(
      RegisterParams(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
        authenticationAttempt: attempt,
      ),
    );
    final result = await request;
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
    await _completeCredentialAuth(result, attempt: attempt);
  }

  Future<void> appleLogin() async {
    final sdkAttempt = AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.loading();
    try {
      final available = await SignInWithApple.isAvailable();
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      if (!available) {
        throw const SignInWithAppleNotSupportedException(
          message: 'Apple sign-in is unavailable on this device',
        );
      }
      final rawNonce = generateAppleRawNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashAppleRawNonce(rawNonce),
      );
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw StateError('Apple identity token missing');
      }
      final fullName = [credential.givenName, credential.familyName]
          .whereType<String>()
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .join(' ');
      final request = ref
          .read(authRepositoryProvider)
          .appleAuth(
            identityToken: identityToken,
            authorizationCode: credential.authorizationCode,
            rawNonce: rawNonce,
            authenticationAttempt: sdkAttempt,
            fullName: fullName.isEmpty ? null : fullName,
          );
      final attempt = sdkAttempt;
      final result = await request;
      if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
      await _completeCredentialAuth(result, attempt: attempt);
    } on SignInWithAppleAuthorizationException catch (error, stack) {
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      if (error.code == AuthorizationErrorCode.canceled) {
        state = const AsyncValue.data(null);
        return;
      }
      ErrorReporter.report('apple-signin', error, stack);
      _setAppleError();
    } catch (error, stack) {
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      ErrorReporter.report('apple-signin', error, stack);
      _setAppleError();
    }
  }

  void _setAppleError() {
    state = AsyncValue.error(const ServerFailure(), StackTrace.current);
  }

  Future<bool> requestPasswordRecovery(String email) async {
    final result = await ref.read(requestPasswordRecoveryUsecaseProvider)(
      RequestPasswordRecoveryParams(email: email),
    );
    return result.fold((_) => false, (_) => true);
  }

  Future<bool> verifyPasswordRecoveryCode(String email, String code) async {
    final result = await ref.read(verifyPasswordRecoveryCodeUsecaseProvider)(
      VerifyPasswordRecoveryCodeParams(email: email, code: code),
    );
    return result.fold((_) => false, (value) => value);
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final result = await ref.read(resetPasswordUsecaseProvider)(
      ResetPasswordParams(email: email, code: token, newPassword: newPassword),
    );
    return result.fold((_) => false, (_) => true);
  }

  Future<void> tryRefreshSession() async {
    state = const AsyncValue.loading();
    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    final result = await ref.read(getCurrentUserUsecaseProvider)();
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
    await result.fold(
      (failure) async {
        if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
        await StorageService.clearTokens();
        if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
        state = const AsyncValue.data(null);
      },
      (user) async {
        await _establishAuthenticatedSession(user, attempt: attempt);
        routerRefreshNotifier.value++;
      },
    );
  }

  void setUser(UserEntity? user) {
    final currentUserId = state.value?.id;
    if (user != null && currentUserId != user.id) {
      return;
    }
    state = AsyncValue.data(user);
    routerRefreshNotifier.value++;
  }

  bool needsProfileCompletion(UserEntity? user) {
    return user != null && user.username == null;
  }

  @override
  Future<void> _completeCredentialAuth(
    Either<Failure, UserEntity> result, {
    required int attempt,
  }) async {
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
    await result.fold<Future<void>>(
      (failure) async {
        if (AuthSessionCoordinator.isCurrentAttempt(attempt)) {
          state = AsyncValue.error(failure, StackTrace.current);
        }
      },
      (user) async {
        await _clearBiometryIfAccountSwitch(user, attempt: attempt);
        if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
        await _establishAuthenticatedSession(user, attempt: attempt);
        if (AuthSessionCoordinator.isCurrentAttempt(attempt)) {
          routerRefreshNotifier.value++;
        }
      },
    );
  }

  Future<void> completeProfile({
    required String username,
    String? displayName,
    String? city,
    String? state,
  }) async {
    final attempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    this.state = const AsyncValue.loading();
    final result = await ref.read(completeProfileUsecaseProvider)(
      CompleteProfileParams(
        username: username,
        displayName: displayName,
        city: city,
        state: state,
      ),
    );
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
    result.fold(
      (failure) => this.state = AsyncValue.error(failure, StackTrace.current),
      (user) {
        this.state = AsyncValue.data(user);
        routerRefreshNotifier.value++;
      },
    );
  }
}
