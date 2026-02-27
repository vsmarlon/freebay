import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FreeBayApp());
    // Smoke test — just verify it renders without crashing
    expect(find.byType(FreeBayApp), findsOneWidget);
  });
}
