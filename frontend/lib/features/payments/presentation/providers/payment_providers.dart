import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/payments/data/repositories/payment_repository.dart';
import 'package:freebay/features/payments/data/services/payment_service.dart';
import 'package:freebay/features/payments/domain/repositories/i_payment_repository.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_session_usecase.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_intent_usecase.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return PaymentRepository(ref.watch(paymentServiceProvider));
});

final createPaymentSessionUsecaseProvider = Provider(
  (ref) => CreatePaymentSessionUsecase(ref.watch(paymentRepositoryProvider)),
);

final createPaymentIntentUsecaseProvider = Provider(
  (ref) => CreatePaymentIntentUsecase(ref.watch(paymentRepositoryProvider)),
);
