import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';

class GetWalletUsecase implements NoParamsUsecase<WalletEntity> {
  final IWalletRepository _repository;

  GetWalletUsecase(this._repository);

  @override
  UsecaseResponse<Failure, WalletEntity> call() {
    return _repository.getWallet();
  }
}
