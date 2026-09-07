import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

String _currentLocation = '/';

void updateCurrentLocation(String location) {
  _currentLocation = location;
}

const _labels = <String, String>{
  '/feed': 'Feed',
  '/explore': 'Explorar',
  '/products': 'Produtos',
  '/wallet': 'Carteira',
  '/chat': 'Chat',
  '/profile': 'Perfil',
  '/create-post': 'Nova Publicação',
  '/post/:id': 'Post',
  '/posts/search': 'Buscar',
  '/products/create': 'Novo Anúncio',
  '/products/:id': 'Produto',
  '/products/:id/edit': 'Editar Anúncio',
  '/profile/edit': 'Editar Perfil',
  '/profile/blocked': 'Usuários Bloqueados',
  '/profile/saved': 'Salvos',
  '/profile/posts': 'Meus Posts',
  '/profile/stories': 'Minhas Histórias',
  '/profile/liked': 'Posts Curtidos',
  '/profile/products': 'Meus Anúncios',
  '/profile/favorites': 'Favoritos',
  '/profile/purchases': 'Minhas Compras',
  '/profile/payment': 'Pagamento',
  '/profile/followers': 'Seguidores',
  '/profile/following': 'Seguindo',
  '/chat/new': 'Novo Chat',
  '/chat/archived': 'Arquivados',
  '/chat/:chatId': 'Conversa',
  '/cart': 'Carrinho',
  '/checkout/cart': 'Checkout',
  '/orders/:orderId': 'Detalhes do Pedido',
  '/user/:id/reviews': 'Avaliações',
  '/reviews/create': 'Avaliar',
  '/disputes': 'Minhas Disputas',
  '/disputes/:disputeId': 'Detalhes da Disputa',
  '/disputes/create/:orderId': 'Abrir Disputa',
  '/notifications': 'Notificações',
  '/faq': 'FAQ',
};

bool _matches(String pattern, String location) {
  final p = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final l = location.split('/').where((s) => s.isNotEmpty).toList();

  // Must have same number of segments
  if (p.length != l.length) return false;

  for (var i = 0; i < p.length; i++) {
    // Skip parameter segments (start with ':')
    if (p[i].startsWith(':')) continue;

    // Exact match required for static segments
    if (p[i] != l[i]) return false;
  }
  return true;
}

/// More lenient match that allows partial prefix matching for breadcrumbs.
/// Returns true if the pattern matches the beginning of the location.
bool _matchesPrefix(String pattern, String location) {
  final p = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final l = location.split('/').where((s) => s.isNotEmpty).toList();

  // Pattern must be shorter or equal to location
  if (p.length > l.length) return false;

  for (var i = 0; i < p.length; i++) {
    // Skip parameter segments
    if (p[i].startsWith(':')) continue;

    // Exact match required for static segments
    if (p[i] != l[i]) return false;
  }
  return true;
}

MapEntry<String, String>? _lookup(String location) {
  // First try exact match
  if (_labels.containsKey(location)) {
    return MapEntry(location, _labels[location]!);
  }

  // Then try pattern matching
  for (final e in _labels.entries) {
    if (_matches(e.key, location)) return e;
  }

  return null;
}

/// Look up a breadcrumb label for a path segment, handling nested routes.
MapEntry<String, String>? _lookupBreadcrumb(String location) {
  // First try exact match
  if (_labels.containsKey(location)) {
    return MapEntry(location, _labels[location]!);
  }

  // Try pattern matching (exact segment count)
  for (final e in _labels.entries) {
    if (_matches(e.key, location)) return e;
  }

  // Try prefix matching for nested routes (e.g., /post/:id for /post/:id/comments)
  MapEntry<String, String>? bestMatch;
  int bestLength = 0;

  for (final e in _labels.entries) {
    if (_matchesPrefix(e.key, location)) {
      final segments = e.key.split('/').where((s) => s.isNotEmpty).length;
      if (segments > bestLength) {
        bestLength = segments;
        bestMatch = e;
      }
    }
  }

  return bestMatch;
}

String _concretize(String pattern, String location) {
  final p = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final l = location.split('/').where((s) => s.isNotEmpty).toList();
  return '/${[for (var i = 0; i < p.length; i++) p[i].startsWith(':') && i < l.length ? l[i] : p[i]].join('/')}';
}

String _fallbackLabel(String path) {
  final seg = path
      .split('/')
      .lastWhere((s) => s.isNotEmpty && !s.startsWith(':'), orElse: () => '');
  if (seg.isEmpty) return '';
  return seg
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

extension BreadcrumbX on BuildContext {
  List<BreadcrumbItem> get breadcrumbs {
    final location = _currentLocation;
    final segs = location.split('/').where((s) => s.isNotEmpty).toList();
    final items = <BreadcrumbItem>[];
    final ctx = this;

    // Build breadcrumb items from path segments
    for (var i = 1; i <= segs.length; i++) {
      final prefix = '/${segs.sublist(0, i).join('/')}';
      final entry = _lookupBreadcrumb(prefix);

      if (entry != null) {
        // Concretize the path (replace :id with actual value)
        final path = _concretize(entry.key, location);

        // Skip duplicate entries (e.g., /post/:id appearing twice)
        if (items.isNotEmpty && items.last.label == entry.value) continue;

        items.add(
          BreadcrumbItem(
            label: entry.value,
            onTap: () => GoRouter.of(ctx).go(path),
          ),
        );
      }
    }

    if (items.isEmpty) return [];

    // Add current page as last item (non-clickable)
    final current = _lookup(location);
    final currentLabel = current?.value ?? _fallbackLabel(location);

    // Avoid duplicate last item
    if (items.last.label != currentLabel) {
      items.add(BreadcrumbItem(label: currentLabel));
    }

    return items;
  }
}
