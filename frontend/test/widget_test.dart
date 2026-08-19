import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    await StorageService.init();
  });

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
