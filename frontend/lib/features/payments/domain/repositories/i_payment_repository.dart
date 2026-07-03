import 'package:dartz/dartz.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IPaymentRepository {
  Future<Either<Failure, PixPaymentEntity>> createPixPayment({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  });
}
