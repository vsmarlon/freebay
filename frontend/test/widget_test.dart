import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FreeBayApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));

    expect(find.byType(FreeBayApp), findsOneWidget);
  });
}
