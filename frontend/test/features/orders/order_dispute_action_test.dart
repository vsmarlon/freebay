import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/widgets/order_actions.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

OrderEntity _order(OrderStatus status) => OrderEntity(
  id: 'order-1',
  buyerId: 'buyer-1',
  sellerId: 'seller-1',
  productId: 'product-1',
  amount: 1000,
  platformFee: 100,
  sellerAmount: 900,
  status: status,
  escrowStatus: EscrowStatus.held,
  createdAt: DateTime(2026, 9, 28),
);

void main() {
  testWidgets('dispute action follows the states accepted by the dispute API', (
    tester,
  ) async {
    for (final status in [OrderStatus.confirmed, OrderStatus.delivered]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OrderActions(
              order: _order(status),
              canReview: false,
              isBuyer: true,
            ),
          ),
        ),
      );
      expect(find.text('Abrir uma disputa'), findsOneWidget);
    }

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OrderActions(
            order: _order(OrderStatus.shipped),
            canReview: false,
            isBuyer: true,
          ),
        ),
      ),
    );
    expect(find.text('Abrir uma disputa'), findsNothing);
  });
}
