import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/features/product/presentation/widgets/category_filter_panel.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';

CategoryEntity _category(String id, String name) =>
    CategoryEntity(id: id, name: name, slug: id);

void main() {
  testWidgets('horizontal category drag scrolls the strip, not the page', (
    tester,
  ) async {
    final pageController = PageController();
    double stripScrollPixels = 0;
    final categories = [
      for (var index = 0; index < 24; index++)
        _category('category-$index', 'Category $index'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PageView(
          controller: pageController,
          children: [
            NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                if (notification.metrics.axis == Axis.horizontal) {
                  stripScrollPixels = notification.metrics.pixels;
                }
                return false;
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: CategoryFilterPanel(
                  categories: categories,
                  selectedCategory: null,
                  onCategorySelected: (_) {},
                ),
              ),
            ),
            const Text('SECOND PAGE'),
          ],
        ),
      ),
    );

    expect(find.byType(Wrap), findsNothing);

    await tester.drag(find.byType(CategoryFilterPanel), const Offset(-100, 0));
    await tester.pump();

    expect(pageController.page, 0);
    expect(stripScrollPixels, greaterThan(0));

    pageController.dispose();
  });

  testWidgets('category tap selects once without changing other behavior', (
    tester,
  ) async {
    final selectedCategories = <String?>[];

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryFilterPanel(
          categories: [_category('category-1', 'Category 1')],
          selectedCategory: null,
          onCategorySelected: selectedCategories.add,
        ),
      ),
    );

    await tester.tap(find.text('CATEGORY 1'));
    await tester.pump();

    expect(selectedCategories, ['category-1']);
  });

  testWidgets('product tap keeps the existing product destination', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (_, _) => ProductResultsGrid(
            products: [
              const ProductEntity(
                id: 'product-1',
                title: 'Desk lamp',
                sellerId: 'seller-1',
              ),
            ],
            isLoadingMore: false,
            onLoadMore: () {},
          ),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) => Text('PRODUCT ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Desk lamp'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/products/product-1');
    expect(find.text('PRODUCT product-1'), findsOneWidget);
  });

  testWidgets('horizontal swipe outside the category panel changes page', (
    tester,
  ) async {
    final pageController = PageController();
    final categories = [
      for (var index = 0; index < 8; index++)
        _category('category-$index', 'Category $index'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PageView(
          controller: pageController,
          children: [
            Column(
              children: [
                CategoryFilterPanel(
                  categories: categories,
                  selectedCategory: null,
                  onCategorySelected: (_) {},
                ),
                const Expanded(child: Text('OUTSIDE CATEGORY PANEL')),
              ],
            ),
            const Text('SECOND PAGE'),
          ],
        ),
      ),
    );

    await tester.fling(
      find.text('OUTSIDE CATEGORY PANEL'),
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(pageController.page, 1);
    expect(find.text('SECOND PAGE'), findsOneWidget);

    pageController.dispose();
  });
}
