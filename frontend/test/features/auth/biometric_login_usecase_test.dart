import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/domain/usecases/biometric_login_usecase.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _BiometryService extends BiometryService {
  int availabilityChecks = 0;
  int authenticationAttempts = 0;
  bool enabled = false;
  bool available = false;
  bool credentials = false;
  bool authenticated = false;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<bool> authenticate({
    String reason = 'Autentique para continuar',
  }) async {
    authenticationAttempts++;
    return authenticated;
  }

  @override
  Future<bool> hasCredentials() async => credentials;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}

class _FailingAuthRepository extends AuthRepository {
  _FailingAuthRepository(this.failure);

  final Failure failure;

  @override
  Future<Either<Failure, UserEntity>> biometricLogin(String biometricToken) {
    return Future.value(Left(failure));
  }
}

class _SuccessfulAuthRepository extends AuthRepository {
  _SuccessfulAuthRepository([
    this.user = const UserEntity(id: 'user-1', email: 'user@example.com'),
  ]);

  final UserEntity user;

  @override
  Future<Either<Failure, UserEntity>> biometricLogin(String biometricToken) {
    return Future.value(Right(user));
  }
}

void main() {
  test('does not check availability or prompt without consent', () async {
    final service = _BiometryService()
      ..available = true
      ..credentials = true;
    final usecase = BiometricLoginUsecase(AuthRepository(), service);

    final result = await usecase();

    expect(result.fold((_) => true, (_) => false), isTrue);
    expect(service.availabilityChecks, 0);
    expect(service.authenticationAttempts, 0);
  });

  test('does not prompt when no biometric credential is enrolled', () async {
    FlutterSecureStorage.setMockInitialValues({
      'biometric_token': 'credential',
      'biometry_enabled': 'true',
      'biometry_owner_id': 'user-1',
    });
    final service = _BiometryService()
      ..enabled = true
      ..available = true;

    final result = await BiometricLoginUsecase(AuthRepository(), service)();

    expect(result.leftOrNull, isA<CacheFailure>());
    expect(service.authenticationAttempts, 0);
  });

  test('clears all biometric state when biometric login fails', () async {
    FlutterSecureStorage.setMockInitialValues({
      'biometric_token': 'credential',
      'biometry_enabled': 'true',
      'biometry_prompted': 'true',
    });
    final service = _BiometryService()
      ..enabled = true
      ..available = true
      ..credentials = true
      ..authenticated = true;

    final result = await BiometricLoginUsecase(
      _FailingAuthRepository(const UnauthorizedFailure()),
      service,
    )();

    expect(result.fold((_) => true, (_) => false), isTrue);
    expect(await StorageService.getBiometricToken(), isNull);
    expect(await service.isEnabled(), isFalse);
    expect(await service.hasPrompted(), isFalse);
  });

  test('returns the authenticated user after biometric success', () async {
    FlutterSecureStorage.setMockInitialValues({
      'biometric_token': 'credential',
      'biometry_owner_id': 'user-1',
    });
    final service = _BiometryService()
      ..enabled = true
      ..available = true
      ..credentials = true
      ..authenticated = true;

    final result = await BiometricLoginUsecase(
      _SuccessfulAuthRepository(),
      service,
    )();

    expect(result.rightOrNull?.id, 'user-1');
    expect(service.authenticationAttempts, 1);
    expect(await StorageService.getBiometricToken(), 'credential');
  });

  test('preserves the credential when the user cancels the prompt', () async {
    FlutterSecureStorage.setMockInitialValues({
      'biometric_token': 'credential',
      'biometry_enabled': 'true',
      'biometry_owner_id': 'user-1',
    });
    final service = _BiometryService()
      ..enabled = true
      ..available = true
      ..credentials = true;

    final result = await BiometricLoginUsecase(
      _SuccessfulAuthRepository(
        const UserEntity(id: 'user-2', email: 'other@example.com'),
      ),
      service,
    )();

    expect(result.leftOrNull, isA<BiometryCancelledFailure>());
    expect(await StorageService.getBiometricToken(), 'credential');
    expect(service.authenticationAttempts, 1);
  });

  test('preserves the credential on a transient failure', () async {
    FlutterSecureStorage.setMockInitialValues({
      'biometric_token': 'credential',
      'biometry_enabled': 'true',
      'biometry_prompted': 'false',
      'biometry_owner_id': 'user-1',
    });
    final service = _BiometryService()
      ..enabled = true
      ..available = true
      ..credentials = true
      ..authenticated = true;

    final result = await BiometricLoginUsecase(
      _FailingAuthRepository(const ServerFailure('offline')),
      service,
    )();

    expect(result.fold((_) => true, (_) => false), isTrue);
    expect(await StorageService.getBiometricToken(), 'credential');
    expect(await service.isEnabled(), isTrue);
    expect(await service.hasPrompted(), isFalse);
  });

  test('clears credentials when the biometric owner does not match', () async {
    FlutterSecureStorage.setMockInitialValues({
      'biometric_token': 'credential',
      'biometry_enabled': 'true',
      'biometry_owner_id': 'user-1',
    });
    final service = _BiometryService()
      ..enabled = true
      ..available = true
      ..credentials = true
      ..authenticated = true;

    final result = await BiometricLoginUsecase(
      _SuccessfulAuthRepository(
        const UserEntity(id: 'user-2', email: 'other@example.com'),
      ),
      service,
    )();

    expect(result.leftOrNull, isA<CacheFailure>());
    expect(await StorageService.getBiometricToken(), isNull);
    expect(await service.isEnabled(), isFalse);
    expect(service.authenticationAttempts, 1);
  });
}
