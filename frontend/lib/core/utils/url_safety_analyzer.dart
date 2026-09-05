enum UrlRiskLevel { safe, suspicious, dangerous }

class UrlSafetyResult {
  final String originalUrl;
  final String normalizedUrl;
  final String host;
  final UrlRiskLevel riskLevel;
  final List<String> riskReasons;
  final bool isBlocked;

  const UrlSafetyResult({
    required this.originalUrl,
    required this.normalizedUrl,
    required this.host,
    required this.riskLevel,
    required this.riskReasons,
    required this.isBlocked,
  });
}

/// Fast client-side URL analysis and threat heuristic evaluation.
class UrlSafetyAnalyzer {
  static const Set<String> _allowedSchemes = {'http', 'https'};

  static const Set<String> _dangerousSchemes = {
    'javascript',
    'data',
    'file',
    'intent',
    'blob',
    'android-app',
    'content',
    'about',
    'vbscript',
  };

  static const Set<String> _dangerousExtensions = {
    '.exe',
    '.apk',
    '.dmg',
    '.pkg',
    '.bat',
    '.cmd',
    '.scr',
    '.vbs',
    '.js',
    '.msi',
    '.sh',
    '.bin',
    '.jar',
    '.reg',
    '.iso',
    '.com',
  };

  static const List<String> _phishingKeywords = [
    'freebay-login',
    'freebay-auth',
    'freebay-pagamento',
    'freebay-suporte',
    'mercadopago-liberar',
    'seguranca-pix',
    'confirmacao-escrow',
    'recuperar-conta',
  ];

  static const Set<String> _trustedDomains = {
    'freebay.app',
    'freebay.com',
    'github.com',
    'google.com',
    'youtube.com',
    'instagram.com',
    'twitter.com',
    'x.com',
    'linkedin.com',
    'wikipedia.org',
    'apple.com',
    'play.google.com',
  };

  /// Normalizes a raw string URL, adding https:// if scheme is missing.
  static String normalizeUrl(String input) {
    var trimmed = input.trim();
    if (trimmed.startsWith('www.')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  /// Evaluates safety heuristics for a given URL string.
  static UrlSafetyResult analyze(String rawUrl) {
    final normalized = normalizeUrl(rawUrl);
    final reasons = <String>[];
    var isBlocked = false;
    var risk = UrlRiskLevel.safe;

    Uri? uri;
    try {
      uri = Uri.parse(normalized);
    } catch (_) {
      return UrlSafetyResult(
        originalUrl: rawUrl,
        normalizedUrl: normalized,
        host: 'URL Inválida',
        riskLevel: UrlRiskLevel.dangerous,
        riskReasons: const ['Estrutura de URL inválida ou malformada.'],
        isBlocked: true,
      );
    }

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    // 1. Scheme verification
    if (_dangerousSchemes.contains(scheme)) {
      reasons.add('Protocolo potencialmente malicioso detectado ($scheme:).');
      isBlocked = true;
      risk = UrlRiskLevel.dangerous;
    } else if (!_allowedSchemes.contains(scheme)) {
      reasons.add('Protocolo não suportado ($scheme:).');
      isBlocked = true;
      risk = UrlRiskLevel.dangerous;
    }

    // 2. Private IP / Localhost / SSRF targets
    if (_isPrivateOrLocalHost(host)) {
      reasons.add('Endereço de rede local ou IP privado não permitido.');
      isBlocked = true;
      risk = UrlRiskLevel.dangerous;
    }

    // 3. Executable / Dangerous payload extensions
    for (final ext in _dangerousExtensions) {
      if (path.endsWith(ext)) {
        reasons.add(
          'Arquivo executável detectado ($ext). Risco de vírus/malware.',
        );
        isBlocked = true;
        risk = UrlRiskLevel.dangerous;
        break;
      }
    }

    // 4. Phishing / Brand Impersonation in domain
    for (final kw in _phishingKeywords) {
      if (host.contains(kw)) {
        reasons.add('Possível tentativa de phishing ou falsificação de marca.');
        risk = UrlRiskLevel.dangerous;
        break;
      }
    }

    // 5. Punycode / Homograph attack detection
    if (host.startsWith('xn--') || host.contains('.xn--')) {
      reasons.add(
        'Domínio com caracteres internacionais codificados (punycode). Pode ser ataque de substituição.',
      );
      if (risk != UrlRiskLevel.dangerous) {
        risk = UrlRiskLevel.suspicious;
      }
    }

    // 6. Plain HTTP (Insecure connection)
    if (scheme == 'http' && !_isLocalHost(host)) {
      reasons.add(
        'Conexão não criptografada (HTTP). Suas informações podem ser interceptadas.',
      );
      if (risk == UrlRiskLevel.safe) {
        risk = UrlRiskLevel.suspicious;
      }
    }

    // 7. Unusual Port Check
    if (uri.hasPort && uri.port != 80 && uri.port != 443 && uri.port != 8080) {
      reasons.add('Porta de rede incomum (${uri.port}).');
      if (risk == UrlRiskLevel.safe) {
        risk = UrlRiskLevel.suspicious;
      }
    }

    // 8. Whitelist override for safe domains
    if (_isTrusted(host) && risk == UrlRiskLevel.safe) {
      // Clean safe state
    }

    return UrlSafetyResult(
      originalUrl: rawUrl,
      normalizedUrl: normalized,
      host: host.isNotEmpty ? host : normalized,
      riskLevel: risk,
      riskReasons: reasons,
      isBlocked: isBlocked,
    );
  }

  static bool _isTrusted(String host) {
    if (_trustedDomains.contains(host)) return true;
    for (final trusted in _trustedDomains) {
      if (host.endsWith('.$trusted')) return true;
    }
    return false;
  }

  static bool _isLocalHost(String host) {
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  static bool _isPrivateOrLocalHost(String host) {
    if (_isLocalHost(host)) return true;
    if (host == '0.0.0.0' || host == '169.254.169.254') return true;

    // IPv4 regex check for private subnets
    final ipRegex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    final match = ipRegex.firstMatch(host);
    if (match != null) {
      final p1 = int.tryParse(match.group(1)!) ?? 0;
      final p2 = int.tryParse(match.group(2)!) ?? 0;

      // 10.0.0.0/8
      if (p1 == 10) return true;
      // 172.16.0.0/12 (172.16 - 172.31)
      if (p1 == 172 && p2 >= 16 && p2 <= 31) return true;
      // 192.168.0.0/16
      if (p1 == 192 && p2 == 168) return true;
      // 127.0.0.0/8
      if (p1 == 127) return true;
      // 169.254.0.0/16 (link local)
      if (p1 == 169 && p2 == 254) return true;
    }

    return false;
  }
}
