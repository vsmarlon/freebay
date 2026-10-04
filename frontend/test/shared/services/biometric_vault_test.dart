import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.freebay.app/biometric_key');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    FlutterSecureStorage.setMockInitialValues({
      'biometric_auth_v1_present': 'true',
      'biometry_owner_id': 'owner',
      'auth_token': 'unrelated-session',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'readVault') return 'native-credential';
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('each credential read invokes the native biometric vault', () async {
    expect(await StorageService.getBiometricToken(), 'native-credential');
    expect(await StorageService.getBiometricToken(), 'native-credential');
    expect(calls, ['readVault', 'readVault']);
  });

  test('metadata checks and deletion never read the biometric vault', () async {
    expect(await StorageService.hasBiometricToken(), isTrue);
    await StorageService.clearBiometricToken();
    expect(calls, ['clearVault']);
    expect(await StorageService.hasBiometricToken(), isFalse);
    expect(await StorageService.getBiometricOwner(), isNull);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'),
        'unrelated-session');
  });

  test('native cleanup failure does not retain enabled credential metadata', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'vault_delete_failed');
        });
    await expectLater(StorageService.clearBiometricToken(), throwsA(isA<PlatformException>()));
    expect(await StorageService.hasBiometricToken(), isFalse);
    expect(await StorageService.getBiometricOwner(), isNull);
  });
}
