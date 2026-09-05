import 'package:freebay/shared/config/app_config.dart';

const String uploadsPrefix = '/uploads/';

String mediaUrl(String path) {
  if (!path.startsWith(uploadsPrefix)) return path;
  final base = AppConfig.apiBaseUrl;
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$root$path';
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
