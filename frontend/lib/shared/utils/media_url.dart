import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';

const String uploadsPrefix = '/uploads/';
const String privateMediaPrefix = '/media/';

bool isPrivateMedia(String url) {
  if (url.startsWith(privateMediaPrefix)) return true;

  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasAuthority) return false;
  if (parsed.scheme != 'http' && parsed.scheme != 'https') return false;

  final base = Uri.tryParse(AppConfig.apiBaseUrl);
  if (base == null || !base.hasAuthority) return false;

  return parsed.origin == base.origin &&
      parsed.path.startsWith(privateMediaPrefix);
}

String mediaUrl(String path) {
  if (!path.startsWith(uploadsPrefix) && !path.startsWith(privateMediaPrefix)) {
    return path;
  }
  final base = AppConfig.apiBaseUrl;
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$root$path';
}

Map<String, String>? mediaAuthHeaders(String url) {
  if (!isPrivateMedia(url)) return null;
  final token = StorageService.cachedToken;
  if (token == null) return null;
  return {'Authorization': 'Bearer $token'};
}

Future<Map<String, String>?> getMediaAuthHeadersAsync(String url) async {
  if (!isPrivateMedia(url)) return null;
  final token = StorageService.cachedToken ?? await StorageService.getToken();
  if (token == null) return null;
  return {'Authorization': 'Bearer $token'};
}

dynamic absolutizeMediaUrls(dynamic node) {
  if (node is String) return mediaUrl(node);
  if (node is List) {
    for (var i = 0; i < node.length; i++) {
      node[i] = absolutizeMediaUrls(node[i]);
    }
    return node;
  }
  if (node is Map) {
    for (final key in node.keys.toList()) {
      node[key] = absolutizeMediaUrls(node[key]);
    }
    return node;
  }
  return node;
}
