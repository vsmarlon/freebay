/// The one pagination envelope every list endpoint returns.
///
/// The cursor is opaque — never parse it, just hand it back on the next call.
class CursorPage<T> {
  final List<T> items;
  final bool hasMore;
  final String? nextCursor;

  const CursorPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  const CursorPage.empty()
    : items = const [],
      hasMore = false,
      nextCursor = null;

  bool get isEmpty => items.isEmpty;

  CursorPage<T> append(CursorPage<T> next) => CursorPage<T>(
    items: [...items, ...next.items],
    hasMore: next.hasMore,
    nextCursor: next.nextCursor,
  );
}

/// Parses `{ items, hasMore, nextCursor }` out of the unwrapped `data` object.
CursorPage<T> parseCursorPage<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson, {
  String itemsKey = 'items',
}) {
  final map = data as Map<String, dynamic>?;
  final rawItems = (map?[itemsKey] as List?) ?? const [];

  return CursorPage<T>(
    items: rawItems
        .whereType<Map>()
        .map((json) => fromJson(Map<String, dynamic>.from(json)))
        .toList(),
    hasMore: map?['hasMore'] == true,
    nextCursor: map?['nextCursor'] as String?,
  );
}
