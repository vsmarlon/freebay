import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/features/payments/data/services/payment_service.dart';
import 'package:freebay/features/payments/domain/repositories/i_payment_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class PaymentRepository implements IPaymentRepository {
  final PaymentService _service;

  PaymentRepository(this._service);

  @override
  Future<Either<Failure, PixPaymentEntity>> createPixPayment({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  }) {
    return _service.createPixPayment(
      orderId: orderId,
      customerName: customerName,
      customerTaxId: customerTaxId,
      customerEmail: customerEmail,
      idempotencyKey: idempotencyKey,
    );
  }
}
