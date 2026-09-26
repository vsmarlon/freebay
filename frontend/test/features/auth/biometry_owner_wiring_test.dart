import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only welcome owns post-auth biometric enrollment', () {
    final login = File(
      'lib/features/auth/presentation/pages/login_page.dart',
    ).readAsStringSync();
    final register = File(
      'lib/features/auth/presentation/pages/register_page.dart',
    ).readAsStringSync();
    final completeProfile = File(
      'lib/features/auth/presentation/pages/complete_profile_page.dart',
    ).readAsStringSync();
    final welcome = File(
      'lib/features/onboarding/presentation/pages/welcome_setup_page.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/features/profile/presentation/widgets/profile_settings_sheet.dart',
    ).readAsStringSync();
    final settingsTile = File(
      'lib/features/profile/presentation/widgets/biometry_setting_tile.dart',
    ).readAsStringSync();

    expect(login, isNot(contains('showEnableBiometrySheet')));
    expect(register, isNot(contains('showEnableBiometrySheet')));
    expect(completeProfile, isNot(contains('showEnableBiometrySheet')));
    expect(welcome, contains('enrollBiometricToken'));
    expect(settings, contains('BiometrySettingTile'));
    expect(settingsTile, contains('enrollBiometricToken'));
    expect(settingsTile, contains('revokeBiometricToken'));
  });
}
