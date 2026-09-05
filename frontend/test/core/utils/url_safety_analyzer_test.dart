import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/utils/url_safety_analyzer.dart';

void main() {
  group('UrlSafetyAnalyzer', () {
    test('normalizes www. prefix to https://', () {
      expect(
        UrlSafetyAnalyzer.normalizeUrl('www.google.com'),
        'https://www.google.com',
      );
    });

    test('identifies safe external https links', () {
      final result = UrlSafetyAnalyzer.analyze('https://google.com/search?q=freebay');
      expect(result.riskLevel, UrlRiskLevel.safe);
      expect(result.isBlocked, false);
      expect(result.host, 'google.com');
    });

    test('identifies dangerous javascript: scheme and blocks it', () {
      final result = UrlSafetyAnalyzer.analyze('javascript:alert(document.cookie)');
      expect(result.riskLevel, UrlRiskLevel.dangerous);
      expect(result.isBlocked, true);
    });

    test('identifies file: and data: schemes as dangerous', () {
      final fileRes = UrlSafetyAnalyzer.analyze('file:///etc/passwd');
      expect(fileRes.riskLevel, UrlRiskLevel.dangerous);
      expect(fileRes.isBlocked, true);

      final dataRes = UrlSafetyAnalyzer.analyze('data:text/html,<script>alert(1)</script>');
      expect(dataRes.riskLevel, UrlRiskLevel.dangerous);
      expect(dataRes.isBlocked, true);
    });

    test('identifies localhost and private IP addresses as dangerous (SSRF/local network protection)', () {
      final localRes = UrlSafetyAnalyzer.analyze('http://127.0.0.1:8080');
      expect(localRes.riskLevel, UrlRiskLevel.dangerous);
      expect(localRes.isBlocked, true);

      final privateRes = UrlSafetyAnalyzer.analyze('http://192.168.1.1/admin');
      expect(privateRes.riskLevel, UrlRiskLevel.dangerous);
      expect(privateRes.isBlocked, true);

      final awsMetaRes = UrlSafetyAnalyzer.analyze('http://169.254.169.254/latest/meta-data');
      expect(awsMetaRes.riskLevel, UrlRiskLevel.dangerous);
      expect(awsMetaRes.isBlocked, true);
    });

    test('identifies executable extensions as dangerous malware risk', () {
      final exeRes = UrlSafetyAnalyzer.analyze('https://example.com/software/installer.exe');
      expect(exeRes.riskLevel, UrlRiskLevel.dangerous);
      expect(exeRes.isBlocked, true);

      final apkRes = UrlSafetyAnalyzer.analyze('https://example.com/app.apk');
      expect(apkRes.riskLevel, UrlRiskLevel.dangerous);
      expect(apkRes.isBlocked, true);
    });

    test('identifies phishing keywords as dangerous', () {
      final phishRes = UrlSafetyAnalyzer.analyze('https://freebay-login-secure.com');
      expect(phishRes.riskLevel, UrlRiskLevel.dangerous);
    });

    test('identifies unencrypted HTTP as suspicious', () {
      final httpRes = UrlSafetyAnalyzer.analyze('http://unencrypted-website.com');
      expect(httpRes.riskLevel, UrlRiskLevel.suspicious);
      expect(httpRes.isBlocked, false);
    });
  });
}
