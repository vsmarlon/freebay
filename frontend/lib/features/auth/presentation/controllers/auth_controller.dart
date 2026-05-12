import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/domain/usecases/login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/register_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/logout_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/guest_login_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/verify_password_recovery_code_usecase.dart';
import 'package:freebay/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/shared/services/storage_service.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});

final loginUsecaseProvider =
    Provider((ref) => LoginUsecase(ref.watch(authRepositoryProvider)));
final registerUsecaseProvider =
    Provider((ref) => RegisterUsecase(ref.watch(authRepositoryProvider)));
final logoutUsecaseProvider =
    Provider((ref) => LogoutUsecase(ref.watch(authRepositoryProvider)));
final getCurrentUserUsecaseProvider =
    Provider((ref) => GetCurrentUserUsecase(ref.watch(authRepositoryProvider)));
final guestLoginUsecaseProvider =
    Provider((ref) => GuestLoginUsecase(ref.watch(authRepositoryProvider)));
final requestPasswordRecoveryUsecaseProvider =
    Provider((ref) => RequestPasswordRecoveryUsecase(ref.watch(authRepositoryProvider)));
final verifyPasswordRecoveryCodeUsecaseProvider =
    Provider((ref) => VerifyPasswordRecoveryCodeUsecase(ref.watch(authRepositoryProvider)));
final resetPasswordUsecaseProvider =
    Provider((ref) => ResetPasswordUsecase(ref.watch(authRepositoryProvider)));

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>((ref) {
  return AuthController(
    ref.watch(loginUsecaseProvider),
    ref.watch(registerUsecaseProvider),
    ref.watch(logoutUsecaseProvider),
    ref.watch(getCurrentUserUsecaseProvider),
    ref.watch(guestLoginUsecaseProvider),
    ref.watch(requestPasswordRecoveryUsecaseProvider),
    ref.watch(verifyPasswordRecoveryCodeUsecaseProvider),
    ref.watch(resetPasswordUsecaseProvider),
  );
});

// Controller
class AuthController extends StateNotifier<AsyncValue<UserEntity?>> {
  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  final LogoutUsecase _logoutUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final GuestLoginUsecase _guestLoginUsecase;
  final RequestPasswordRecoveryUsecase _requestPasswordRecoveryUsecase;
  final VerifyPasswordRecoveryCodeUsecase _verifyPasswordRecoveryCodeUsecase;
  final ResetPasswordUsecase _resetPasswordUsecase;

  AuthController(
    this._loginUsecase,
    this._registerUsecase,
    this._logoutUsecase,
    this._getCurrentUserUsecase,
    this._guestLoginUsecase,
    this._requestPasswordRecoveryUsecase,
    this._verifyPasswordRecoveryCodeUsecase,
    this._resetPasswordUsecase,
  ) : super(const AsyncValue.loading()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    state = const AsyncValue.loading();

    final token = await StorageService.getToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    final result = await _getCurrentUserUsecase(NoParams());

    result.fold(
      (failure) async {
        await StorageService.clearTokens();
        state = const AsyncValue.data(null);
      },
      (user) {
        state = AsyncValue.data(user);
      },
    );
  }

  Future<void> login(String email, String password,
      {bool rememberMe = false}) async {
    state = const AsyncValue.loading();
    final result = await _loginUsecase(
        LoginParams(email: email, password: password, rememberMe: rememberMe));

    result.fold(
        (failure) =>
            state = AsyncValue.error(failure.message, StackTrace.current),
        (user) => state = AsyncValue.data(user));
  }

  Future<void> register(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    final result = await _registerUsecase(RegisterParams(
        email: email, password: password, displayName: displayName));

    result.fold(
        (failure) =>
            state = AsyncValue.error(failure.message, StackTrace.current),
        (user) => state = AsyncValue.data(user));
  }

  Future<void> loginAsGuest() async {
    state = const AsyncValue.loading();
    final result = await _guestLoginUsecase(NoParams());

    result.fold(
        (failure) =>
            state = AsyncValue.error(failure.message, StackTrace.current),
        (user) => state = AsyncValue.data(user));
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await _logoutUsecase(NoParams());

    result.fold(
        (failure) =>
            state = AsyncValue.error(failure.message, StackTrace.current),
        (_) => state = const AsyncValue.data(null));
  }

  Future<void> requestPasswordRecovery(String email) async {
    await _requestPasswordRecoveryUsecase(RequestPasswordRecoveryParams(email: email));
  }

  Future<bool> verifyPasswordRecoveryCode(String email, String code) async {
    final result = await _verifyPasswordRecoveryCodeUsecase(
      VerifyPasswordRecoveryCodeParams(email: email, code: code),
    );
    return result.fold((_) => false, (value) => value);
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    await _resetPasswordUsecase(
      ResetPasswordParams(email: email, code: code, newPassword: newPassword),
    );
  }
}
