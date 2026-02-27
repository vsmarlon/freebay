import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/guest_login_usecase.dart';
import '../../data/entities/user_entity.dart';
import '../../../../shared/templates/usecase.dart';
import '../../../../shared/services/storage_service.dart';

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

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>((ref) {
  return AuthController(
    ref.watch(loginUsecaseProvider),
    ref.watch(registerUsecaseProvider),
    ref.watch(logoutUsecaseProvider),
    ref.watch(getCurrentUserUsecaseProvider),
    ref.watch(guestLoginUsecaseProvider),
  );
});

// Controller
class AuthController extends StateNotifier<AsyncValue<UserEntity?>> {
  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  final LogoutUsecase _logoutUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final GuestLoginUsecase _guestLoginUsecase;

  AuthController(
    this._loginUsecase,
    this._registerUsecase,
    this._logoutUsecase,
    this._getCurrentUserUsecase,
    this._guestLoginUsecase,
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
}
