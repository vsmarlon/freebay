import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('freebay-test-paths-');
  });
  setUp(() {
    // ponytail: mock directory lookup only; cache cleanup and auth stay real.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'getTemporaryDirectory' ||
            'getApplicationSupportDirectory' => directory.path,
            _ => throw MissingPluginException(call.method),
          };
        });
  });
  tearDownAll(() => directory.delete(recursive: true));

  await testMain();
}
