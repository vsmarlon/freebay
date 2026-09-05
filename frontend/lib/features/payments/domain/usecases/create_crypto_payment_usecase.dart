import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/payments/data/entities/crypto_payment_entity.dart';
import 'package:freebay/features/payments/domain/repositories/i_payment_repository.dart';

class CreateCryptoPaymentParams {
  final String orderId;
  final String currency;

  CreateCryptoPaymentParams({required this.orderId, this.currency = 'XMR'});
}

class CreateCryptoPaymentUsecase
    implements Usecase<CryptoPaymentEntity, CreateCryptoPaymentParams> {
  final IPaymentRepository _repository;

  CreateCryptoPaymentUsecase(this._repository);

  @override
  UsecaseResponse<Failure, CryptoPaymentEntity> call(
    CreateCryptoPaymentParams params,
  ) {
    return _repository.createCryptoPayment(
      orderId: params.orderId,
      currency: params.currency,
    );
  }
}
