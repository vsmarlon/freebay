import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/domain/usecases/google_auth_usecase.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late GoogleAuthUsecase googleAuthUsecase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    googleAuthUsecase = GoogleAuthUsecase(mockAuthRepository);
  });

  const tIdToken = 'valid_google_id_token_12345';
  const tUser = UserEntity(
    id: 'user_123',
    displayName: 'Google Test User',
    username: null,
    email: 'test@gmail.com',
    avatarUrl: 'https://avatar.com/test.png',
  );

  test('should return UserEntity when repository googleAuth succeeds', () async {
    when(() => mockAuthRepository.googleAuth(tIdToken))
        .thenAnswer((_) async => const Right(tUser));

    final result = await googleAuthUsecase(tIdToken);

    expect(result, const Right(tUser));
    verify(() => mockAuthRepository.googleAuth(tIdToken)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return Failure when repository googleAuth fails', () async {
    const tFailure = ServerFailure('Token Google inválido');
    when(() => mockAuthRepository.googleAuth(tIdToken))
        .thenAnswer((_) async => const Left(tFailure));

    final result = await googleAuthUsecase(tIdToken);

    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.googleAuth(tIdToken)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
