import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/presentation/widgets/product_form_fields.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

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
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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
