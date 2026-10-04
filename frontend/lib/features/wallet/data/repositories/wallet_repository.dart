import 'package:freebay/shared/either/either.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class WalletRepository {
  final Dio client;

  WalletRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, WalletEntity>> getWallet() => requestEither(
    () => client.get('/wallet/'),
    decoder: (response) => Right(WalletEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, CursorPage<WalletTransactionEntity>>> getTransactions({
    String? cursor,
    int? limit,
  }) => requestEither(
    () => client.get(
      '/wallet/transactions',
      queryParameters: {'cursor': ?cursor, 'limit': ?limit},
    ),
    decoder: (response) => Right(
      parseCursorPage<WalletTransactionEntity>(
        response.data['data'],
        WalletTransactionEntity.fromJson,
      ),
    ),
  );

  Future<Either<Failure, ConnectStatusEntity>> getConnectStatus() =>
      requestEither(
        () => client.get('/payments/connect/status'),
        decoder: (response) =>
            Right(ConnectStatusEntity.fromJson(response.data['data'])),
      );

  Future<Either<Failure, String>> startConnectOnboarding() => requestEither(
    () => client.post('/payments/connect/onboarding'),
    decoder: (response) =>
        Right(response.data['data']['onboardingUrl'] as String),
  );

  Future<Either<Failure, String>> getConnectDashboardLink({
    required String stepUpToken,
  }) => requestEither(
    () => client.post(
      '/payments/connect/dashboard',
      options: Options(headers: {'x-step-up-token': stepUpToken}),
    ),
    decoder: (response) =>
        Right(response.data['data']['dashboardUrl'] as String),
  );
}
