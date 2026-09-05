import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/data/entities/payment_intent_entity.dart';
import 'package:freebay/features/payments/data/entities/crypto_payment_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';

class PaymentService extends BaseHttpRepository {
  PaymentService({super.client});

  Future<Either<Failure, PaymentEntity>> createPaymentSession({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  }) => safePost<PaymentEntity>(
    '/payments/checkout/$orderId',
    data: {
      'customerName': customerName,
      'customerTaxId': customerTaxId,
      'customerEmail': customerEmail,
    },
    options: Options(
      headers: idempotencyKey != null
          ? {'idempotency-key': idempotencyKey}
          : null,
    ),
    extractKey: 'data',
    fromJson: PaymentEntity.fromJson,
  );

  Future<Either<Failure, PaymentIntentEntity>> createPaymentIntent({
    required String orderId,
    String? idempotencyKey,
  }) => safePost<PaymentIntentEntity>(
    '/payments/payment-intent/$orderId',
    options: Options(
      headers: idempotencyKey != null
          ? {'idempotency-key': idempotencyKey}
          : null,
    ),
    extractKey: 'data',
    fromJson: PaymentIntentEntity.fromJson,
  );

  Future<Either<Failure, CryptoPaymentEntity>> createCryptoPayment({
    required String orderId,
    String currency = 'XMR',
  }) => safePost<CryptoPaymentEntity>(
    '/payments/crypto/$orderId',
    extractKey: 'data',
    fromJson: CryptoPaymentEntity.fromJson,
  );
}
