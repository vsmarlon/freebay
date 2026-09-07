import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/payments/presentation/widgets/payment_view.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

const _testProduct = ProductEntity(
  id: 'p1',
  title: 'Vintage Camera',
  description: 'A used film camera',
  price: 10000,
  condition: 'used',
  status: 'available',
  sellerId: 's1',
);

final _expiresAtDate = DateTime(2026, 8, 10, 14, 30);

PaymentEntity _testPayment() => PaymentEntity(
  orderId: 'o1',
  stripeSessionId: 'cs_test_123',
  checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_123',
  expiresAt: _expiresAtDate,
);

Widget _wrap(PaymentView view) => MaterialApp(home: Scaffold(body: view));

void main() {
  group('PaymentView web branch (payment != null)', () {
    testWidgets('renders the checkout URL box and expiry date', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaymentView(
            product: _testProduct,
            payment: _testPayment(),
            paymentIntentClientSecret: null,
            createdOrderId: 'o1',
          ),
        ),
      );

      expect(find.text('CHECKOUT STRIPE'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      final urlBox = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(urlBox.data, 'https://checkout.stripe.com/pay/cs_test_123');
      expect(find.textContaining('Expira em'), findsOneWidget);
      expect(find.text('Pagar agora'), findsOneWidget);
      expect(find.text('Pagar com cartão'), findsNothing);
    });

    testWidgets(
      'prefers the web branch when both payment and client secret are set',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            PaymentView(
              product: _testProduct,
              payment: _testPayment(),
              paymentIntentClientSecret: 'pi_test_123_secret',
              createdOrderId: null,
            ),
          ),
        );

        expect(find.text('Pagar agora'), findsOneWidget);
        expect(find.text('Pagar com cartão'), findsNothing);
      },
    );
  });

  group('PaymentView mobile branch (payment == null)', () {
    testWidgets(
      'renders the PaymentSheet button without touching payment fields (null-safety)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const PaymentView(
              product: _testProduct,
              payment: null,
              paymentIntentClientSecret: 'pi_test_123_secret_abc',
              createdOrderId: null,
            ),
          ),
        );

        expect(find.text('Pagar com cartão'), findsOneWidget);
        // The checkout URL box must not render on mobile.
        expect(find.byType(SelectableText), findsNothing);
        expect(find.textContaining('Expira em'), findsNothing);
        expect(find.text('Pagar agora'), findsNothing);

        final verPedido = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Ver pedido'),
        );
        expect(verPedido.onPressed, isNull);
      },
    );

    testWidgets(
      'renders only a disabled "Ver pedido" when neither branch is ready',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const PaymentView(
              product: _testProduct,
              payment: null,
              paymentIntentClientSecret: null,
              createdOrderId: null,
            ),
          ),
        );

        expect(find.text('Pagar com cartão'), findsNothing);
        expect(find.text('Pagar agora'), findsNothing);
        expect(find.byType(SelectableText), findsNothing);

        final verPedido = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Ver pedido'),
        );
        expect(verPedido.onPressed, isNull);
      },
    );

    testWidgets('enables "Ver pedido" once the order id is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentView(
            product: _testProduct,
            payment: null,
            paymentIntentClientSecret: 'pi_test_123_secret_abc',
            createdOrderId: 'o1',
          ),
        ),
      );

      final verPedido = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Ver pedido'),
      );
      expect(verPedido.onPressed, isNotNull);
    });
  });
}
