import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';

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
  '/post/:id/comments': 'Comentários',
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
  if (p.length != l.length) return false;
  for (var i = 0; i < p.length; i++) {
    if (!p[i].startsWith(':') && p[i] != l[i]) return false;
  }
  return true;
}

MapEntry<String, String>? _lookup(String location) {
  if (_labels.containsKey(location)) {
    return MapEntry(location, _labels[location]!);
  }
  for (final e in _labels.entries) {
    if (_matches(e.key, location)) return e;
  }
  return null;
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

    for (var i = 1; i < segs.length; i++) {
      final prefix = '/${segs.sublist(0, i).join('/')}';
      final entry = _lookup(prefix);
      if (entry != null) {
        final path = _concretize(entry.key, location);
        items.add(
          BreadcrumbItem(
            label: entry.value,
            onTap: () => GoRouter.of(ctx).go(path),
          ),
        );
      }
    }

    if (items.isEmpty) return [];

    final current = _lookup(location);
    items.add(
      BreadcrumbItem(label: current?.value ?? _fallbackLabel(location)),
    );
    return items;
  }
}
