import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';

/// Authenticates the user via biometrics, then uses stored credentials
/// to call the existing login endpoint.
///
/// On cancellation, returns [BiometryCancelledFailure] — credentials
/// are preserved so the user can retry.
/// On definitive authentication failure, clears stale credentials.
class BiometricLoginUsecase implements NoParamsUsecase<UserEntity> {
  final AuthRepository _repository;
  final BiometryService _biometryService;

  BiometricLoginUsecase(this._repository, this._biometryService);

  @override
  UsecaseResponse<Failure, UserEntity> call() async {
    AuthSessionCoordinator.beginAuthentication();
    // Consent is the first gate: availability alone must never prompt.
    final enabled = await _biometryService.isEnabled();
    if (!enabled) {
      return const Left(CacheFailure('Biometria não está habilitada.'));
    }

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

    final ownerId = await StorageService.getBiometricOwner();
    if (ownerId == null || ownerId.isEmpty) {
      await _biometryService.clearState();
      return const Left(CacheFailure('Dono da biometria não encontrado.'));
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
      await _biometryService.clearState();
      return const Left(CacheFailure('Token biométrico não encontrado.'));
    }

    // 5. Call backend biometric login
    final result = await _repository.biometricLogin(biometricToken);

    // Only a 401 means this credential is definitively invalid or revoked.
    if (result.leftOrNull is UnauthorizedFailure) {
      await _biometryService.clearState();
    }

    final user = result.rightOrNull;
    if (user != null && user.id != ownerId) {
      await _biometryService.clearState();
      return const Left(CacheFailure('A biometria pertence a outra conta.'));
    }

    return result;
  }
}
