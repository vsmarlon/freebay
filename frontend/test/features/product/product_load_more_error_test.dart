import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/pages/explorar_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('empty catalog error exposes an inline retry', (tester) async {
    const params = GetProductsParams();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => []),
          productsFeedProvider(
            params,
          ).overrideWithValue(const ProductsFeedState(error: 'Sem conexão')),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('pt', 'BR'),
          home: ProductListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(ProductListPage)),
    );
    expect(find.text(strings.commonRetry.toUpperCase()), findsOneWidget);
    expect(find.text(strings.errorUnknown), findsOneWidget);
  });

  testWidgets('keeps catalog results and offers retry when pagination fails', (
    tester,
  ) async {
    const params = GetProductsParams();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => []),
          productsFeedProvider(params).overrideWithValue(
            const ProductsFeedState(
              products: [
                ProductEntity(id: 'p1', title: 'Produto', sellerId: 'seller'),
              ],
              nextCursor: 'cursor',
              error: 'Sem conexão',
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplorarPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Produto'), findsOneWidget);
    final strings = AppLocalizations.of(
      tester.element(find.byType(ExplorarPage)),
    );
    expect(find.text(strings.errorUnknown), findsOneWidget);
    expect(find.text(strings.commonRetry.toUpperCase()), findsOneWidget);
  });
}
