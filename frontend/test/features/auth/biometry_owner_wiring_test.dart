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

    expect(login, isNot(contains('enrollBiometrics(')));
    expect(register, isNot(contains('enrollBiometrics(')));
    expect(completeProfile, isNot(contains('enrollBiometrics(')));
    expect(welcome, contains("purpose: 'biometric_enroll'"));
    expect(
      welcome,
      contains('enrollBiometrics(stepUpToken, expectedUserId: userId)'),
    );
    expect(settings, contains('BiometrySettingTile'));
    expect(settingsTile, contains("purpose: 'biometric_enroll'"));
    expect(
      settingsTile,
      contains('enrollBiometrics(stepUpToken, expectedUserId: userId)'),
    );
    expect(settingsTile, contains('revokeBiometricToken'));
  });
}
