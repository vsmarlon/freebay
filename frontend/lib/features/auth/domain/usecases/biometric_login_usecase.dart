import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/services/biometric_key_service.dart';
import 'package:flutter/services.dart';

/// Authenticates the user via biometrics, then uses stored credentials
/// to call the existing login endpoint.
///
/// On cancellation, returns [BiometryCancelledFailure] — credentials
/// are preserved so the user can retry.
/// On definitive authentication failure, clears stale credentials.
class BiometricLoginUsecase implements Usecase<UserEntity, int> {
  final AuthRepository _repository;
  final BiometryService _biometryService;
  final BiometricKeyService _keyService;

  BiometricLoginUsecase(
    this._repository,
    this._biometryService,
    this._keyService,
  );

  Future<void> _clearIfCurrent(int attempt) =>
      AuthSessionCoordinator.serialize(() async {
        if (AuthSessionCoordinator.isCurrentAttempt(attempt)) {
          await _biometryService.clearState();
        }
      });

  @override
  UsecaseResponse<Failure, UserEntity> call(int attempt) async {
    // Consent is the first gate: availability alone must never prompt.
    final enabled = await _biometryService.isEnabled();
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }
    if (!enabled) {
      return const Left(CacheFailure('Biometria não está habilitada.'));
    }

    // 1. Check biometrics available
    final available = await _biometryService.isAvailable();
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }
    if (!available) {
      return const Left(
        CacheFailure('Biometria não disponível neste dispositivo.'),
      );
    }

    // 2. Check credentials stored
    final hasCreds = await _biometryService.hasCredentials();
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }
    if (!hasCreds) {
      return const Left(
        CacheFailure('Credenciais biométricas não encontradas.'),
      );
    }

    final ownerId = await StorageService.getBiometricOwner();
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }
    if (ownerId == null || ownerId.isEmpty) {
      await _clearIfCurrent(attempt);
      return const Left(CacheFailure('Dono da biometria não encontrado.'));
    }

    if (!await _keyService.hasKey()) {
      await _clearIfCurrent(attempt);
      return const Left(CacheFailure('Chave biométrica não encontrada.'));
    }
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }

    // The token vault and non-exportable signing key each enforce biometrics.
    String? biometricToken;
    try {
      biometricToken = await StorageService.getBiometricToken();
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') {
        return const Left(BiometryCancelledFailure());
      }
      if (error.code == 'key_missing_or_invalidated') {
        await _clearIfCurrent(attempt);
      }
      return const Left(CacheFailure('Falha na autenticação biométrica.'));
    } on MissingPluginException {
      return const Left(
        CacheFailure('Biometria não disponível neste dispositivo.'),
      );
    }
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }
    if (biometricToken == null) {
      await _clearIfCurrent(attempt);
      return const Left(CacheFailure('Token biométrico não encontrado.'));
    }

    final challenge = await _repository.createBiometricLoginChallenge(
      biometricToken,
    );
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }
    if (challenge.isLeft) {
      if (challenge.leftOrNull is UnauthorizedFailure) {
        await _clearIfCurrent(attempt);
      }
      return Left(challenge.leftOrNull!);
    }

    String signature;
    try {
      signature = await _keyService.sign(challenge.rightOrNull!.challenge);
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') {
        return const Left(BiometryCancelledFailure());
      }
      if (error.code == 'key_missing_or_invalidated') {
        await _clearIfCurrent(attempt);
      }
      return const Left(CacheFailure('Falha na autenticação biométrica.'));
    }
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }

    final result = await _repository.biometricLogin(
      biometricToken,
      challengeId: challenge.rightOrNull!.challengeId,
      signature: signature,
      expectedUserId: ownerId,
      authenticationAttempt: attempt,
    );
    if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
      return const Left(CacheFailure('Authentication attempt superseded.'));
    }

    // Only a 401 means this credential is definitively invalid or revoked.
    if (result.leftOrNull is UnauthorizedFailure) {
      await _clearIfCurrent(attempt);
    }

    final user = result.rightOrNull;
    if (user != null && user.id != ownerId) {
      await _clearIfCurrent(attempt);
      return const Left(CacheFailure('A biometria pertence a outra conta.'));
    }

    return result;
  }
}
