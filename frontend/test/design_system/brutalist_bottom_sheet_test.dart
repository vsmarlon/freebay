import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay_design_system/components/brutalist_bottom_sheet.dart';

void main() {
  testWidgets(
    'keeps the fixed action visible with a keyboard in a short viewport',
    (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 600),
            viewInsets: EdgeInsets.only(bottom: 200),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showBrutalistSheet<void>(
                    context: context,
                    title: 'Keyboard sheet',
                    scrollable: false,
                    padding: EdgeInsets.zero,
                    builder: (_) => const Column(
                      children: [
                        Expanded(
                          child: ColoredBox(
                            key: Key('sheet-body'),
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: Text('Fixed action', key: Key('sheet-action')),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final bodyHeight = tester
          .getSize(find.byKey(const Key('sheet-body')))
          .height;
      final actionRect = tester.getRect(find.byKey(const Key('sheet-action')));
      expect(bodyHeight, greaterThan(100));
      expect(actionRect.bottom, lessThanOrEqualTo(400));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('uses the requested background color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBrutalistSheet<void>(
                context: context,
                backgroundColor: Colors.red,
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

    expect(
      tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.text('Sheet body'),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color,
      Colors.red,
    );
  });

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

  testWidgets('the handle dismisses a sheet with scrollable content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBrutalistSheet<void>(
                context: context,
                title: 'Long sheet',
                child: Column(
                  children: [
                    for (var index = 0; index < 30; index++)
                      SizedBox(height: 48, child: Text('Row $index')),
                  ],
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Row 0'), findsOneWidget);

    await tester.drag(find.text('Long sheet'), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.text('Row 0'), findsNothing);
  });
}
