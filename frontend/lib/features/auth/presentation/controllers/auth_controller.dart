import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
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
  @override
  AsyncValue<UserEntity?> build() {
    Future.microtask(_initAuth);
    return const AsyncValue.loading();
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref.read(loginUsecaseProvider)(
      LoginParams(email: email, password: password, rememberMe: rememberMe),
    );
    _completeCredentialAuth(result);
  }

  Future<bool> loginWithBiometrics() async {
    state = const AsyncValue.loading();
    final result = await ref.read(biometricLoginUsecaseProvider)();
    if (!ref.mounted) return false;
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return false;
      },
      (user) {
        state = AsyncValue.data(user);
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
    state = const AsyncValue.loading();
    final result = await ref.read(registerUsecaseProvider)(
      RegisterParams(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
      ),
    );
    _completeCredentialAuth(result);
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
    final result = await ref.read(getCurrentUserUsecaseProvider)();
    await result.fold(
      (failure) async {
        await StorageService.clearTokens();
        state = const AsyncValue.data(null);
      },
      (user) async {
        state = AsyncValue.data(user);
        routerRefreshNotifier.value++;
      },
    );
  }

  void setUser(UserEntity? user) {
    state = AsyncValue.data(user);
    routerRefreshNotifier.value++;
  }

  bool needsProfileCompletion(UserEntity? user) {
    return user != null && user.username == null;
  }

  @override
  void _completeCredentialAuth(Either<Failure, UserEntity> result) {
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) async {
        await _clearBiometryIfAccountSwitch(user);
        state = AsyncValue.data(user);
        routerRefreshNotifier.value++;
      },
    );
  }

  Future<void> completeProfile({
    required String username,
    String? displayName,
    String? city,
    String? state,
  }) async {
    this.state = const AsyncValue.loading();
    final result = await ref.read(completeProfileUsecaseProvider)(
      CompleteProfileParams(
        username: username,
        displayName: displayName,
        city: city,
        state: state,
      ),
    );
    result.fold(
      (failure) => this.state = AsyncValue.error(failure, StackTrace.current),
      (user) {
        this.state = AsyncValue.data(user);
        routerRefreshNotifier.value++;
      },
    );
  }
}
