import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _FailingAuthRepository extends AuthRepository {
  @override
  Future<Either<Failure, void>> logout() async =>
      const Left(ServerFailure('server unavailable'));
}

class _SwitchingAuthRepository extends AuthRepository {
  _SwitchingAuthRepository(this.user);

  final UserEntity user;

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
    bool rememberMe,
  ) async => Right(user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'access-token',
      'refresh_token': 'refresh-token',
      'biometric_token': 'biometric-credential',
      'biometry_owner_id': 'user-1',
      'biometry_enabled': 'true',
      'biometry_prompted': 'true',
      'remember_me': 'false',
    });
  });

  test('clearTokens alone leaves the biometric credential behind', () async {
    await StorageService.clearTokens();

    expect(await StorageService.getToken(), isNull);
    expect(await StorageService.getBiometricToken(), 'biometric-credential');
  });

  test(
    'session expiry clears the session but preserves reauthentication data',
    () async {
      await StorageService.saveEmail(' User@Example.COM ');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container.read(authControllerProvider.notifier).expireSession();

      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.getRefreshToken(), isNull);
      expect(await StorageService.getEmail(), 'user@example.com');
      expect(await StorageService.getBiometricToken(), 'biometric-credential');
      expect(await BiometryService().isEnabled(), isTrue);
    },
  );

  test('saved email can be read and deleted independently', () async {
    await StorageService.saveEmail('User@Example.COM');
    expect(await StorageService.getEmail(), 'user@example.com');

    await StorageService.clearEmail();
    expect(await StorageService.getEmail(), isNull);
  });

  test(
    'clearBiometricToken removes the credential a logout must not keep',
    () async {
      await StorageService.clearBiometricToken();
      await StorageService.clearTokens();

      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.getRefreshToken(), isNull);
      expect(await StorageService.getBiometricToken(), isNull);
      expect(await StorageService.getBiometricOwner(), isNull);
    },
  );

  test('logout biometric cleanup clears state for the next account', () async {
    final service = BiometryService();
    await service.clearState();

    expect(await StorageService.getBiometricToken(), isNull);
    expect(await service.isEnabled(), isFalse);
    expect(await service.hasPrompted(), isFalse);
  });

  test('forceLogout clears biometric state for the next account', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await container.read(authControllerProvider.notifier).forceLogout();

    final service = BiometryService();
    expect(await StorageService.getBiometricToken(), isNull);
    expect(await service.isEnabled(), isFalse);
    expect(await service.hasPrompted(), isFalse);
  });

  test('account switch clears the previous biometric owner state', () async {
    const nextUser = UserEntity(id: 'user-2', email: 'next@example.com');
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _SwitchingAuthRepository(nextUser),
        ),
      ],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await container
        .read(authControllerProvider.notifier)
        .login('next@example.com', 'password123', rememberMe: true);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(container.read(authControllerProvider).value?.id, nextUser.id);
    expect(await StorageService.getBiometricToken(), isNull);
    expect(await StorageService.getBiometricOwner(), isNull);
    expect(await BiometryService().isEnabled(), isFalse);
    expect(await BiometryService().hasPrompted(), isFalse);
  });

  test('logout remains unauthenticated when server logout fails', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await container.read(authControllerProvider.notifier).logout();

    final state = container.read(authControllerProvider);
    expect(state.hasValue, isTrue);
    expect(state.value, isNull);
  });

  test('logout clears saved email when remember me is disabled', () async {
    await StorageService.saveEmail('user@example.com');
    await StorageService.saveRememberMe(false);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await container.read(authControllerProvider.notifier).logout();

    expect(await StorageService.getEmail(), isNull);
  });

  test('logout retains saved email when remember me is enabled', () async {
    await StorageService.saveEmail('user@example.com');
    await StorageService.saveRememberMe(true);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await container.read(authControllerProvider.notifier).logout();

    expect(await StorageService.getEmail(), 'user@example.com');
  });
}
