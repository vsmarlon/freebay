import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class WalletRepository extends BaseHttpRepository {
  WalletRepository({super.client});

  Future<Either<Failure, WalletEntity>> getWallet() => safeGet<WalletEntity>(
    '/wallet/',
    extractKey: 'data',
    fromJson: WalletEntity.fromJson,
  );

  Future<Either<Failure, CursorPage<WalletTransactionEntity>>> getTransactions({
    String? cursor,
    int? limit,
  }) => safePage<WalletTransactionEntity>(
    '/wallet/transactions',
    WalletTransactionEntity.fromJson,
    cursor: cursor,
    limit: limit,
  );

  Future<Either<Failure, ConnectStatusEntity>> getConnectStatus() =>
      safeGet<ConnectStatusEntity>(
        '/payments/connect/status',
        extractKey: 'data',
        fromJson: ConnectStatusEntity.fromJson,
      );

  Future<Either<Failure, String>> startConnectOnboarding() => safePost<String>(
    '/payments/connect/onboarding',
    extractKey: 'data.onboardingUrl',
    customMapper: (value) => value as String,
  );

  Future<Either<Failure, String>> getConnectDashboardLink() => safePost<String>(
    '/payments/connect/dashboard',
    extractKey: 'data.dashboardUrl',
    customMapper: (value) => value as String,
  );
}
