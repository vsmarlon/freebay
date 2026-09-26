import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/data/repositories/payment_repository.dart';
import 'package:freebay/features/payments/domain/repositories/payment_repository.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_session_usecase.dart';
import 'package:freebay/features/payments/domain/usecases/create_payment_intent_usecase.dart';
import 'package:freebay/shared/services/http_client.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(client: HttpClient.instance),
);

final createPaymentSessionUsecaseProvider = Provider(
  (ref) => CreatePaymentSessionUsecase(ref.watch(paymentRepositoryProvider)),
);

final createPaymentIntentUsecaseProvider = Provider(
  (ref) => CreatePaymentIntentUsecase(ref.watch(paymentRepositoryProvider)),
);

/// Page-scoped checkout progress for [PaymentPage].
///
/// The page previously kept `_payment`, `_paymentIntentClientSecret`,
/// `_createdOrderId` and `_isSubmitting` in `setState` fields.
class PaymentCheckoutState {
  final bool isSubmitting;
  final String? createdOrderId;
  final PaymentEntity? payment;
  final String? paymentIntentClientSecret;

  const PaymentCheckoutState({
    this.isSubmitting = false,
    this.createdOrderId,
    this.payment,
    this.paymentIntentClientSecret,
  });

  bool get hasResult => payment != null || paymentIntentClientSecret != null;

  PaymentCheckoutState copyWith({
    bool? isSubmitting,
    String? createdOrderId,
    PaymentEntity? payment,
    String? paymentIntentClientSecret,
  }) {
    return PaymentCheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdOrderId: createdOrderId ?? this.createdOrderId,
      payment: payment ?? this.payment,
      paymentIntentClientSecret:
          paymentIntentClientSecret ?? this.paymentIntentClientSecret,
    );
  }
}

class PaymentCheckoutNotifier extends Notifier<PaymentCheckoutState> {
  @override
  PaymentCheckoutState build() => const PaymentCheckoutState();

  void reset() => state = const PaymentCheckoutState();

  /// Runs create-order + Stripe session/intent. Returns an error message, if any.
  Future<String?> submit({
    required String productId,
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
    required bool isWeb,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final orderResult = await ref
          .read(orderRepositoryProvider)
          .createOrder(productId);
      if (orderResult.isLeft) {
        return orderResult.leftOrNull?.message ?? 'Erro ao criar pedido.';
      }
      final order = orderResult.rightOrNull!;
      state = state.copyWith(createdOrderId: order.id);

      if (isWeb) {
        final sessionResult =
            await ref.read(createPaymentSessionUsecaseProvider)(
              CreatePaymentSessionParams(
                orderId: order.id,
                customerName: customerName,
                customerTaxId: customerTaxId,
                customerEmail: customerEmail,
              ),
            );
        return sessionResult.fold((f) => f.message, (p) {
          state = state.copyWith(payment: p);
          return null;
        });
      }

      final intentResult = await ref.read(createPaymentIntentUsecaseProvider)(
        CreatePaymentIntentParams(orderId: order.id),
      );
      return intentResult.fold((f) => f.message, (intent) {
        state = state.copyWith(
          paymentIntentClientSecret: intent.paymentIntentClientSecret,
        );
        return null;
      });
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final paymentCheckoutProvider =
    NotifierProvider.autoDispose<PaymentCheckoutNotifier, PaymentCheckoutState>(
      PaymentCheckoutNotifier.new,
    );
