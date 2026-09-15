import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/domain/usecases/google_auth_usecase.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(this.result) : super(client: Dio());

  Either<Failure, UserEntity> result;
  String? receivedToken;
  int calls = 0;

  @override
  Future<Either<Failure, UserEntity>> googleAuth(String idToken) async {
    receivedToken = idToken;
    calls++;
    return result;
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late GoogleAuthUsecase googleAuthUsecase;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository(const Left(ServerFailure()));
    googleAuthUsecase = GoogleAuthUsecase(fakeAuthRepository);
  });

  const tIdToken = 'valid_google_id_token_12345';
  const tUser = UserEntity(
    id: 'user_123',
    displayName: 'Google Test User',
    email: 'test@gmail.com',
    avatarUrl: 'https://avatar.com/test.png',
  );

  test(
    'returns UserEntity when repository googleAuth succeeds',
    () async {
      fakeAuthRepository.result = const Right(tUser);

      final result = await googleAuthUsecase(tIdToken);

      expect(result, const Right(tUser));
      expect(fakeAuthRepository.receivedToken, tIdToken);
      expect(fakeAuthRepository.calls, 1);
    },
  );

  test('returns Failure when repository googleAuth fails', () async {
    const tFailure = ServerFailure('Token Google inválido');
    fakeAuthRepository.result = const Left(tFailure);

    final result = await googleAuthUsecase(tIdToken);

    expect(result, const Left(tFailure));
    expect(fakeAuthRepository.receivedToken, tIdToken);
    expect(fakeAuthRepository.calls, 1);
  });
}
