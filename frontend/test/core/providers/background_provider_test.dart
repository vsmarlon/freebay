import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/providers/background_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to animated background', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(backgroundAnimatedProvider), isTrue);
  });

  test('setAnimated persists and hydrates on new container', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(backgroundAnimatedProvider.notifier)
        .setAnimated(false);
    expect(container.read(backgroundAnimatedProvider), isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 100));
    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    // First read instantiates the notifier (default true), then _load hydrates.
    expect(fresh.read(backgroundAnimatedProvider), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(fresh.read(backgroundAnimatedProvider), isFalse);
  });
}
