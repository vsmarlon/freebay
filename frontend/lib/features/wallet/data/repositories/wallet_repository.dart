import 'package:dartz/dartz.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
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
  Future<Either<Failure, List<dynamic>>> getTransactions() {
    return _service.getTransactions();
  }
}
