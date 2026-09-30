import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay_design_system/components/brutalist_bottom_sheet.dart';

void main() {
  testWidgets('dragging the sheet down dismisses it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBrutalistSheet<void>(
                context: context,
                child: const SizedBox(height: 200, child: Text('Sheet body')),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);

    await tester.drag(find.text('Sheet body'), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.text('Sheet body'), findsNothing);
  });
}
