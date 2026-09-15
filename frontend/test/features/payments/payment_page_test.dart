import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/payments/presentation/pages/payment_page.dart';
import 'package:freebay/features/payments/presentation/providers/payment_providers.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';

const _product = ProductEntity(
  id: 'product-1',
  title: 'Vintage Camera',
  description: 'A used film camera',
  price: 10000,
  condition: 'used',
  status: 'available',
  sellerId: 'seller-1',
);

const _userA = UserEntity(
  id: 'user-a',
  displayName: 'User A',
  email: 'a@example.com',
);

const _userB = UserEntity(
  id: 'user-b',
  displayName: 'User B',
  email: 'b@example.com',
);

class _TestAuthController extends AuthController {
  _TestAuthController(this.initialUser);

  final UserEntity initialUser;

  @override
  AsyncValue<UserEntity?> build() => AsyncValue.data(initialUser);
}

void main() {
  testWidgets(
    'resets checkout fields and state when authenticated identity changes',
    (tester) async {
      final authController = _TestAuthController(_userA);
      final router = GoRouter(
        initialLocation: '/payment?productId=product-1',
        routes: [
          GoRoute(path: '/payment', builder: (_, _) => const PaymentPage()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => authController),
            productByIdProvider(
              'product-1',
            ).overrideWith((_) async => _product),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(fields.elementAt(0).controller?.text, 'User A');
      expect(fields.elementAt(1).controller?.text, 'a@example.com');

      await tester.enterText(find.byType(TextFormField).at(0), 'Edited A');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'edited-a@example.com',
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PaymentPage)),
      );
      container.read(paymentCheckoutProvider.notifier).state =
          const PaymentCheckoutState(paymentIntentClientSecret: 'secret-a');

      authController.state = const AsyncValue.data(_userB);
      await tester.pump();

      final updatedFields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(updatedFields.elementAt(0).controller?.text, 'User B');
      expect(updatedFields.elementAt(1).controller?.text, 'b@example.com');
      expect(container.read(paymentCheckoutProvider).hasResult, isFalse);
    },
  );
}
