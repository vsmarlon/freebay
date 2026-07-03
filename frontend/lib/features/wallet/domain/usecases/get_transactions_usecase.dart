import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/wallet/domain/repositories/i_wallet_repository.dart';

class GetTransactionsUsecase implements NoParamsUsecase<List<dynamic>> {
  final IWalletRepository _repository;

  GetTransactionsUsecase(this._repository);

  @override
  UsecaseResponse<Failure, List<dynamic>> call() {
    return _repository.getTransactions();
  }
}
