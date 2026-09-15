import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/domain/usecases/login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/register_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/verify_password_recovery_code_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/biometric_login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/google_auth_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

const String _googleGenericError =
    'Não foi possível entrar com o Google. Tente novamente.';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final loginUsecaseProvider = Provider(
  (ref) => LoginUsecase(ref.watch(authRepositoryProvider)),
);
final registerUsecaseProvider = Provider(
  (ref) => RegisterUsecase(ref.watch(authRepositoryProvider)),
);
final getCurrentUserUsecaseProvider = Provider(
  (ref) => GetCurrentUserUsecase(ref.watch(authRepositoryProvider)),
);
final requestPasswordRecoveryUsecaseProvider = Provider(
  (ref) => RequestPasswordRecoveryUsecase(ref.watch(authRepositoryProvider)),
);
final verifyPasswordRecoveryCodeUsecaseProvider = Provider(
  (ref) => VerifyPasswordRecoveryCodeUsecase(ref.watch(authRepositoryProvider)),
);
final resetPasswordUsecaseProvider = Provider(
  (ref) => ResetPasswordUsecase(ref.watch(authRepositoryProvider)),
);

// ── Biometry providers ──────────────────────────────────────────────────

final biometryServiceProvider = Provider<BiometryService>((ref) {
  return BiometryService();
});

final biometryAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometryServiceProvider).isAvailable();
});

final biometryEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometryServiceProvider).isEnabled();
});

final biometricLoginUsecaseProvider = Provider(
  (ref) => BiometricLoginUsecase(
    ref.watch(authRepositoryProvider),
    ref.watch(biometryServiceProvider),
  ),
);
final googleAuthUsecaseProvider = Provider(
  (ref) => GoogleAuthUsecase(ref.watch(authRepositoryProvider)),
);
final completeProfileUsecaseProvider = Provider(
  (ref) => CompleteProfileUsecase(ref.watch(authRepositoryProvider)),
);

class IsInitialAuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  @override
  set state(bool value) => super.state = value;
  void set(bool value) => state = value;
}

// Whether the initial cold-boot auth check is running
final isInitialAuthLoadingProvider =
    NotifierProvider<IsInitialAuthLoadingNotifier, bool>(
      IsInitialAuthLoadingNotifier.new,
    );

class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => StorageService.hasSeenOnboardingSync();

  @override
  set state(bool value) => super.state = value;
  void set(bool value) => state = value;
}

// Whether the post-login onboarding carousel has been seen, seeded once
// during auth init alongside the session itself so the router's redirect
// can read it synchronously instead of awaiting secure storage on every nav.
final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingNotifier, bool>(
      HasSeenOnboardingNotifier.new,
    );

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<UserEntity?>>(
      AuthController.new,
    );

// Controller
class AuthController extends Notifier<AsyncValue<UserEntity?>> {
  @override
  AsyncValue<UserEntity?> build() {
    Future.microtask(_initAuth);
    return const AsyncValue.loading();
  }

  Future<void> _initAuth() async {
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    ref.read(isInitialAuthLoadingProvider.notifier).set(true);

    try {
      final hasSeenOnboarding = StorageService.hasSeenOnboardingSync();
      if (!ref.mounted) return;
      ref.read(hasSeenOnboardingProvider.notifier).set(hasSeenOnboarding);

      final rememberMe = await StorageService.getRememberMe();
      if (!ref.mounted) return;
      if (!rememberMe) {
        await StorageService.clearTokens();
        if (!ref.mounted) return;
        state = const AsyncValue.data(null);
        return;
      }

      final token = await StorageService.getToken();
      if (!ref.mounted) return;
      if (token == null) {
        await _tryBiometricLogin();
        return;
      }

      final result = await ref.read(getCurrentUserUsecaseProvider)();
      if (!ref.mounted) return;
      await result.fold(
        (failure) async {
          await StorageService.clearTokens();
          if (!ref.mounted) return;
          state = const AsyncValue.data(null);
        },
        (user) async {
          if (!ref.mounted) return;
          await AuthSessionCoordinator.establishSession();
          state = AsyncValue.data(user);
        },
      );
    } catch (_) {
      await StorageService.clearTokens();
      if (!ref.mounted) return;
      state = const AsyncValue.data(null);
    } finally {
      if (ref.mounted) {
        ref.read(isInitialAuthLoadingProvider.notifier).set(false);
        routerRefreshNotifier.value++;
      }
    }
  }

  /// Attempt biometric login. On success, state becomes the user.
  /// On any failure/cancellation, state becomes null (login page shown).
  Future<void> _tryBiometricLogin() async {
    final result = await ref.read(biometricLoginUsecaseProvider)();
    if (!ref.mounted) return;
    result.fold(
      (failure) {
        state = const AsyncValue.data(null);
      },
      (user) {
        state = AsyncValue.data(user);
      },
    );
  }

  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    final serverClientId = AppConfig.googleServerClientId;
    if (serverClientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    } else {
      await GoogleSignIn.instance.initialize();
    }
    _isGoogleSignInInitialized = true;
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

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) async {
        await _clearBiometryIfAccountSwitch(user);
        state = AsyncValue.data(user);
        routerRefreshNotifier.value++;
      },
    );
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

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) async {
        await _clearBiometryIfAccountSwitch(user);
        state = AsyncValue.data(user);
        routerRefreshNotifier.value++;
      },
    );
  }

  void _invalidateUserProviders() {
    ref.read(walletProvider.notifier).reset();
    ref.read(walletHistoryProvider.notifier).reset();
    ref.read(connectStatusProvider.notifier).reset();
    ref.invalidate(walletProvider);
    ref.invalidate(walletHistoryProvider);
    ref.invalidate(connectStatusProvider);
    ref.invalidate(cartProvider);
    ref.invalidate(disputeListProvider);
    ref.invalidate(purchasesListProvider);
    ref.invalidate(salesListProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(chatsProvider);
    ref.invalidate(liveChatListProvider);
  }

  Future<void> logout() async {
    HttpClient.suspendRefresh();
    final rememberMe = await StorageService.getRememberMe();
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).logout();

    await result.fold((failure) async {
      await _clearLocalAuthState(clearSavedEmail: !rememberMe);
      ErrorReporter.report('logout', failure);
    }, (_) async => _clearLocalAuthState(clearSavedEmail: !rememberMe));
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

  Future<void> forceLogout() async {
    await _clearLocalAuthState();
  }

  Future<void> _clearBiometryIfAccountSwitch(UserEntity user) async {
    final ownerId = await StorageService.getBiometricOwner();
    if (ownerId != null && ownerId != user.id) {
      await BiometryService().clearState();
    }
  }

  Future<void> expireSession() async {
    HttpClient.suspendRefresh();
    await _clearLocalAuthState(clearBiometric: false);
  }

  Future<void> _clearLocalAuthState({
    bool clearBiometric = true,
    bool clearSavedEmail = false,
  }) async {
    HttpClient.suspendRefresh();
    if (clearBiometric) {
      try {
        await BiometryService().clearState();
      } catch (_) {}
    }
    try {
      await StorageService.clearTokens();
    } catch (_) {}
    if (clearSavedEmail) {
      try {
        await StorageService.clearEmail();
      } catch (_) {}
    }
    _invalidateUserProviders();
    state = const AsyncValue.data(null);
    routerRefreshNotifier.value++;
  }

  void setUser(UserEntity? user) {
    state = AsyncValue.data(user);
    routerRefreshNotifier.value++;
  }

  bool needsProfileCompletion(UserEntity? user) {
    return user != null && user.username == null;
  }

  Future<void> googleLogin() async {
    AuthSessionCoordinator.beginAuthentication();
    state = const AsyncValue.loading();
    try {
      final serverClientId = AppConfig.googleServerClientId;
      if (serverClientId.isEmpty) {
        ErrorReporter.report(
          'google-signin',
          StateError('GOOGLE_SERVER_CLIENT_ID ausente'),
        );
        state = AsyncValue.error(
          const ServerFailure(_googleGenericError),
          StackTrace.current,
        );
        return;
      }

      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        ErrorReporter.report(
          'google-signin',
          StateError('idToken ausente — serverClientId != Web Client ID?'),
        );
        state = AsyncValue.error(
          const ServerFailure(_googleGenericError),
          StackTrace.current,
        );
        return;
      }

      final result = await ref.read(googleAuthUsecaseProvider)(idToken);
      result.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (user) async {
          await _clearBiometryIfAccountSwitch(user);
          state = AsyncValue.data(user);
          routerRefreshNotifier.value++;
        },
      );
    } on GoogleSignInException catch (e, stack) {
      debugPrint(
        '[GoogleSignIn] code=${e.code.name} description=${e.description}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        state = const AsyncValue.data(null);
        return;
      }
      ErrorReporter.report('google-signin', e, stack);
      state = AsyncValue.error(
        const ServerFailure(_googleGenericError),
        StackTrace.current,
      );
    } catch (e, stack) {
      ErrorReporter.report('google-signin', e, stack);
      state = AsyncValue.error(
        const ServerFailure(_googleGenericError),
        StackTrace.current,
      );
    }
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
