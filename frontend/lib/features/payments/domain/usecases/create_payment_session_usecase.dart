import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/domain/repositories/payment_repository.dart';

class CreatePaymentSessionParams {
  final String orderId;
  final String customerName;
  final String customerTaxId;
  final String customerEmail;
  final String? idempotencyKey;

  CreatePaymentSessionParams({
    required this.orderId,
    required this.customerName,
    required this.customerTaxId,
    required this.customerEmail,
    this.idempotencyKey,
  });
}

class CreatePaymentSessionUsecase
    implements Usecase<PaymentEntity, CreatePaymentSessionParams> {
  final PaymentRepository _repository;

  CreatePaymentSessionUsecase(this._repository);

  @override
  UsecaseResponse<Failure, PaymentEntity> call(
    CreatePaymentSessionParams params,
  ) {
    return _repository.createPaymentSession(
      orderId: params.orderId,
      customerName: params.customerName,
      customerTaxId: params.customerTaxId,
      customerEmail: params.customerEmail,
      idempotencyKey: params.idempotencyKey,
    );
  }
}
