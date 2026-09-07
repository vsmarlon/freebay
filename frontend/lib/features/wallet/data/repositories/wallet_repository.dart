import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/data/services/wallet_service.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class WalletRepository implements IWalletRepository {
  final WalletService _service;

  WalletRepository(this._service);

  @override
  Future<Either<Failure, WalletEntity>> getWallet() => _service.getWallet();

  @override
  Future<Either<Failure, CursorPage<WalletTransactionEntity>>> getTransactions({
    String? cursor,
    int? limit,
  }) => _service.getTransactions(cursor: cursor, limit: limit);

  @override
  Future<Either<Failure, ConnectStatusEntity>> getConnectStatus() =>
      _service.getConnectStatus();

  @override
  Future<Either<Failure, String>> startConnectOnboarding() =>
      _service.startConnectOnboarding();

  @override
  Future<Either<Failure, String>> getConnectDashboardLink() =>
      _service.getConnectDashboardLink();
}
