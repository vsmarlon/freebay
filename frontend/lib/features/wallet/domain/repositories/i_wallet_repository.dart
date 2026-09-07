import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';

abstract class IWalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet();
  Future<Either<Failure, CursorPage<WalletTransactionEntity>>> getTransactions({
    String? cursor,
    int? limit,
  });
  Future<Either<Failure, ConnectStatusEntity>> getConnectStatus();
  Future<Either<Failure, String>> startConnectOnboarding();
  Future<Either<Failure, String>> getConnectDashboardLink();
}
