import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/product_image_entity.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('duplicate product cells do not register duplicate Hero tags', (
    tester,
  ) async {
    const duplicate = ProductEntity(
      id: 'same-product',
      title: 'Product',
      sellerId: 'seller',
      images: [
        ProductImageEntity(
          id: 'image-1',
          url: 'https://example.test/product.jpg',
          productId: 'same-product',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProductResultsGrid(
            products: const [duplicate, duplicate],
            isLoadingMore: false,
            onLoadMore: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Hero), findsNothing);
  });

  testWidgets('a unique product cell uses the detail image Hero tag', (
    tester,
  ) async {
    const product = ProductEntity(
      id: 'product-1',
      title: 'Product',
      sellerId: 'seller',
      images: [
        ProductImageEntity(
          id: 'image-1',
          url: 'https://example.test/product.jpg',
          productId: 'product-1',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProductResultsGrid(
            products: const [product],
            isLoadingMore: false,
            onLoadMore: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'product-image-product-1');
  });
}
