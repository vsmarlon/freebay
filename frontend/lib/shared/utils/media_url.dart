import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';

const String uploadsPrefix = '/uploads/';
const String privateMediaPrefix = '/media/';

bool isPrivateMedia(String url) =>
    url.startsWith(privateMediaPrefix) ||
    url.contains('${AppConfig.apiBaseUrl}$privateMediaPrefix');

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
