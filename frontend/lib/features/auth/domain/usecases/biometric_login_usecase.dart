import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/storage_service.dart';

/// Authenticates the user via biometrics, then uses stored credentials
/// to call the existing login endpoint.
///
/// On cancellation, returns [BiometryCancelledFailure] — credentials
/// are preserved so the user can retry.
/// On API failure (wrong password, etc.), clears stale credentials.
class BiometricLoginUsecase implements NoParamsUsecase<UserEntity> {
  final IAuthRepository _repository;
  final BiometryService _biometryService;

  BiometricLoginUsecase(this._repository, this._biometryService);

  @override
  UsecaseResponse<Failure, UserEntity> call() async {
    // 1. Check biometrics available
    final available = await _biometryService.isAvailable();
    if (!available) {
      return const Left(
        CacheFailure('Biometria não disponível neste dispositivo.'),
      );
    }

    // 2. Check credentials stored
    final hasCreds = await _biometryService.hasCredentials();
    if (!hasCreds) {
      return const Left(
        CacheFailure('Credenciais biométricas não encontradas.'),
      );
    }

    // 3. Prompt biometric auth
    final authenticated = await _biometryService.authenticate(
      reason: 'Autentique para fazer login',
    );
    if (!authenticated) {
      // User cancelled — do NOT clear credentials
      return const Left(BiometryCancelledFailure());
    }

    // 4. Retrieve biometric token from secure storage
    final biometricToken = await StorageService.getBiometricToken();
    if (biometricToken == null) {
      await _biometryService.clearCredentials();
      return const Left(CacheFailure('Token biométrico não encontrado.'));
    }

    // 5. Call backend biometric login
    final result = await _repository.biometricLogin(biometricToken);

    // 6. On API failure — credentials are stale/wrong, clear them
    result.fold((failure) async {
      // BiometryCancelledFailure should never reach here (returned above),
      // but guard against it to avoid wrongly clearing credentials.
      if (failure is! BiometryCancelledFailure) {
        await _biometryService.clearCredentials();
      }
    }, (_) {});

    return result;
  }
}
