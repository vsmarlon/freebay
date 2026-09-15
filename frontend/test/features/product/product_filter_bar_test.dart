import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/features/product/presentation/widgets/product_filter_bar.dart';

void main() {
  testWidgets('applies a changed price range only after tapping Apply', (
    tester,
  ) async {
    final appliedRanges = <RangeValues?>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductFilterBar(
              sort: ProductSort.recent,
              condition: null,
              priceRange: null,
              onSortChanged: (_) {},
              onConditionChanged: (_) {},
              onPriceRangeChanged: appliedRanges.add,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(RangeSlider), const Offset(-80, 0));
    await tester.pump();

    expect(appliedRanges, isEmpty);

    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    expect(appliedRanges, hasLength(1));
    expect(appliedRanges.single, isNotNull);
  });

  testWidgets('Cancel restores the applied range without applying the draft', (
    tester,
  ) async {
    const appliedRange = RangeValues(100, 200);
    final appliedRanges = <RangeValues?>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductFilterBar(
              sort: ProductSort.recent,
              condition: null,
              priceRange: appliedRange,
              onSortChanged: (_) {},
              onConditionChanged: (_) {},
              onPriceRangeChanged: appliedRanges.add,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(RangeSlider), const Offset(80, 0));
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(
      tester.widget<RangeSlider>(find.byType(RangeSlider)).values,
      appliedRange,
    );
    expect(appliedRanges, isEmpty);
  });

  testWidgets('Apply emits null for the full range', (tester) async {
    final appliedRanges = <RangeValues?>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductFilterBar(
            sort: ProductSort.recent,
            condition: null,
            priceRange: null,
            onSortChanged: (_) {},
            onConditionChanged: (_) {},
            onPriceRangeChanged: appliedRanges.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aplicar'));

    expect(appliedRanges, [null]);
  });

  testWidgets('reopening after dismissal restores the applied range', (
    tester,
  ) async {
    const appliedRange = RangeValues(100, 200);
    final bar = ProductFilterBar(
      sort: ProductSort.recent,
      condition: null,
      priceRange: appliedRange,
      onSortChanged: (_) {},
      onConditionChanged: (_) {},
      onPriceRangeChanged: (_) {},
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: bar)));
    await tester.drag(find.byType(RangeSlider), const Offset(80, 0));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: bar)));

    expect(
      tester.widget<RangeSlider>(find.byType(RangeSlider)).values,
      appliedRange,
    );
  });
}
