import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'access-token',
      'refresh_token': 'refresh-token',
      'biometric_token': 'biometric-credential',
    });
  });

  test('clearTokens alone leaves the biometric credential behind', () async {
    await StorageService.clearTokens();

    expect(await StorageService.getToken(), isNull);
    expect(await StorageService.getBiometricToken(), 'biometric-credential');
  });

  test('clearBiometricToken removes the credential a logout must not keep', () async {
    await StorageService.clearBiometricToken();
    await StorageService.clearTokens();

    expect(await StorageService.getToken(), isNull);
    expect(await StorageService.getRefreshToken(), isNull);
    expect(await StorageService.getBiometricToken(), isNull);
  });
}
