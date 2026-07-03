import 'package:dartz/dartz.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IWalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet();
  Future<Either<Failure, List<dynamic>>> getTransactions();
}
