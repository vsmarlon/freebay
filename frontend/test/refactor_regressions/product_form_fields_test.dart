import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/presentation/widgets/product_form_fields.dart';

void main() {
  testWidgets(
    'keeps extracted field controllers, labels, and condition callbacks',
    (tester) async {
      final title = TextEditingController(text: 'Existing title');
      final description = TextEditingController(text: 'Existing description');
      final price = TextEditingController(text: '12,00');
      final conditions = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProductBasicFields(
                  titleController: title,
                  descriptionController: description,
                  priceController: price,
                ),
                ProductConditionSelector(
                  isNew: true,
                  onChanged: conditions.add,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Descrição'), findsOneWidget);
      expect(find.text('Preço (R\$)'), findsOneWidget);
      expect(find.text('Existing title'), findsOneWidget);
      await tester.tap(find.text('USADO'));
      expect(conditions, [false]);
    },
  );
}
