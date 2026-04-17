import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';

class PaymentService {
  Future<Either<Failure, PixPaymentEntity>> createPixPayment({
    required String orderId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    String? idempotencyKey,
  }) async {
    try {
      final response = await HttpClient.instance.post(
        '/payments/pix/$orderId',
        data: {
          'customerName': customerName,
          'customerTaxId': customerTaxId,
          'customerEmail': customerEmail,
        },
        options: Options(
          headers: idempotencyKey == null
              ? null
              : {
                  'idempotency-key': idempotencyKey,
                },
        ),
      );

      final payload = response.data['data'] as Map<String, dynamic>;
      return Right(PixPaymentEntity.fromJson(payload));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
