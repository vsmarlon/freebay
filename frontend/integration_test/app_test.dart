import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freebay/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app can be instantiated', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FreeBayApp()));
  });
}