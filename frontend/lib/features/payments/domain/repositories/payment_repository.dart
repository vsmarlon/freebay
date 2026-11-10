import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/data/entities/payment_intent_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract interface class PaymentRepository {
  Future<Either<Failure, PaymentEntity>> createPaymentSession({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  });

  Future<Either<Failure, PaymentIntentEntity>> createPaymentIntent({
    required String orderId,
    String? idempotencyKey,
  });
}
