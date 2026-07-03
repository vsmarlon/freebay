import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/features/payments/domain/repositories/i_payment_repository.dart';

class CreatePixPaymentParams {
  final String orderId;
  final String customerName;
  final String customerTaxId;
  final String customerEmail;
  final String? idempotencyKey;

  CreatePixPaymentParams({
    required this.orderId,
    required this.customerName,
    required this.customerTaxId,
    required this.customerEmail,
    this.idempotencyKey,
  });
}

class CreatePixPaymentUsecase
    implements Usecase<PixPaymentEntity, CreatePixPaymentParams> {
  final IPaymentRepository _repository;

  CreatePixPaymentUsecase(this._repository);

  @override
  UsecaseResponse<Failure, PixPaymentEntity> call(
      CreatePixPaymentParams params) {
    return _repository.createPixPayment(
      orderId: params.orderId,
      customerName: params.customerName,
      customerTaxId: params.customerTaxId,
      customerEmail: params.customerEmail,
      idempotencyKey: params.idempotencyKey,
    );
  }
}
