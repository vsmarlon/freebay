import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/payments/data/entities/payment_intent_entity.dart';
import 'package:freebay/features/payments/domain/repositories/i_payment_repository.dart';

class CreatePaymentIntentParams {
  final String orderId;
  final String? idempotencyKey;

  CreatePaymentIntentParams({required this.orderId, this.idempotencyKey});
}

class CreatePaymentIntentUsecase
    implements Usecase<PaymentIntentEntity, CreatePaymentIntentParams> {
  final IPaymentRepository _repository;

  CreatePaymentIntentUsecase(this._repository);

  @override
  UsecaseResponse<Failure, PaymentIntentEntity> call(
    CreatePaymentIntentParams params,
  ) {
    return _repository.createPaymentIntent(
      orderId: params.orderId,
      idempotencyKey: params.idempotencyKey,
    );
  }
}
