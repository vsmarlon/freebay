import 'package:dio/dio.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/data/entities/payment_intent_entity.dart';
import 'package:freebay/features/payments/domain/repositories/payment_repository.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final Dio client;

  PaymentRepositoryImpl({Dio? client}) : client = client ?? HttpClient.instance;

  @override
  Future<Either<Failure, PaymentEntity>> createPaymentSession({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  }) => requestEither(
    () => client.post(
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
    ),
    decoder: (response) => Right(PaymentEntity.fromJson(response.data['data'])),
  );

  @override
  Future<Either<Failure, PaymentIntentEntity>> createPaymentIntent({
    required String orderId,
    String? idempotencyKey,
  }) => requestEither(
    () => client.post(
      '/payments/payment-intent/$orderId',
      options: Options(
        headers: idempotencyKey != null
            ? {'idempotency-key': idempotencyKey}
            : null,
      ),
    ),
    decoder: (response) =>
        Right(PaymentIntentEntity.fromJson(response.data['data'])),
  );
}
