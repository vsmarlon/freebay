import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/pages/explorar_page.dart';

void main() {
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
        child: const MaterialApp(home: ExplorarPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Produto'), findsOneWidget);
    expect(find.text('Sem conexão'), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);
  });
}
