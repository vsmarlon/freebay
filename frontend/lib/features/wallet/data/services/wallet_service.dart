import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/withdrawal_entity.dart';

class WalletService extends BaseHttpRepository {
  WalletService({super.client});

  Future<Either<Failure, WalletEntity>> getWallet() => safeGet<WalletEntity>(
    '/wallet/',
    extractKey: 'data',
    fromJson: WalletEntity.fromJson,
  );

  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions() =>
      safeGetList<WalletTransactionEntity>(
        '/wallet/transactions',
        listKey: 'data.transactions',
        fromJson: WalletTransactionEntity.fromJson,
      );

  Future<Either<Failure, List<WithdrawalEntity>>> getWithdrawals() =>
      safeGetList<WithdrawalEntity>(
        '/wallet/withdrawals',
        listKey: 'data.withdrawals',
        fromJson: WithdrawalEntity.fromJson,
      );

  Future<Either<Failure, void>> withdraw({
    required int amountCents,
    required String pixKey,
    required String pixKeyType,
    required String idempotencyKey,
  }) => safeVoid(
    () => client.post(
      '/wallet/withdraw',
      data: {
        'amount': amountCents,
        'pixKey': pixKey,
        'pixKeyType': pixKeyType,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );
}
