import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/domain/usecases/biometric_login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/google_auth_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/register_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/verify_password_recovery_code_usecase.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/biometric_key_service.dart';

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
    ref.watch(biometricKeyServiceProvider),
  ),
);
final biometricKeyServiceProvider = Provider((ref) => BiometricKeyService());
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

final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingNotifier, bool>(
      HasSeenOnboardingNotifier.new,
    );
