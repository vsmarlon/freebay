import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/withdrawal_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IWalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet();
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions();
  Future<Either<Failure, List<WithdrawalEntity>>> getWithdrawals();
  Future<Either<Failure, void>> withdraw({
    required int amountCents,
    required String pixKey,
    required String pixKeyType,
    required String idempotencyKey,
  });
}
