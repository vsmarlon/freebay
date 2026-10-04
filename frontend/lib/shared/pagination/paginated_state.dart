class PaginatedState<T, C> {
  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final C? cursor;
  final String? error;
}

class PageRequestGuard {
  int _generation = 0;

  int begin() => ++_generation;
  bool isCurrent(int request) => request == _generation;
  void invalidate() => _generation++;
}
