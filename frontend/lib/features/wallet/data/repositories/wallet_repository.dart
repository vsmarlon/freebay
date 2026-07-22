import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/withdrawal_entity.dart';
import 'package:freebay/features/wallet/data/services/wallet_service.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class WalletRepository implements IWalletRepository {
  final WalletService _service;

  WalletRepository(this._service);

  @override
  Future<Either<Failure, WalletEntity>> getWallet() {
    return _service.getWallet();
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions() {
    return _service.getTransactions();
  }

  @override
  Future<Either<Failure, List<WithdrawalEntity>>> getWithdrawals() {
    return _service.getWithdrawals();
  }

  @override
  Future<Either<Failure, void>> withdraw({
    required int amountCents,
    required String pixKey,
    required String pixKeyType,
    required String idempotencyKey,
  }) {
    return _service.withdraw(
      amountCents: amountCents,
      pixKey: pixKey,
      pixKeyType: pixKeyType,
      idempotencyKey: idempotencyKey,
    );
  }
}
