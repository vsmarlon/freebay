import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/pages/product_detail_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _AuthController extends AuthController {
  @override
  AsyncValue<UserEntity?> build() => const AsyncValue.data(null);
}

class _FavoritesNotifier extends FavoritesNotifier {
  @override
  FavoritesState build() => const FavoritesState();
}

void main() {
  for (final scale in [1.5, 2.0]) {
    testWidgets('loaded product detail fits at ${scale}x text scale', (
      tester,
    ) async {
      const product = ProductEntity(
        id: 'product-long',
        title:
            'Título extremamente longo de um produto para testar leitura acessível',
        description:
            'Descrição com detalhes longos que devem continuar legíveis sem transbordar.',
        price: 19990,
        sellerId: 'seller-1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_AuthController.new),
            productByIdProvider(product.id).overrideWith((_) async => product),
            favoritesProvider.overrideWith(_FavoritesNotifier.new),
            isFavoritedProvider(product.id).overrideWith((_) async => false),
            cartItemCountProvider.overrideWithValue(0),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: ProductDetailPage(productId: product.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Título extremamente longo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
