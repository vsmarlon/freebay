import 'package:flutter/material.dart';

/// Which end of the scroll view triggers the next page.
///
/// Most lists grow downward ([ScrollEdge.end]). A chat transcript renders
/// oldest-first and pages backwards, so it loads from [ScrollEdge.start].
enum ScrollEdge { start, end }

/// Fires [onLoadMore] once a scroll settles within [threshold] pixels of [edge].
class InfiniteScrollListener extends StatelessWidget {
  static const double defaultThreshold = 400;

  final VoidCallback onLoadMore;
  final double threshold;
  final ScrollEdge edge;
  final Widget child;

  const InfiniteScrollListener({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = defaultThreshold,
    this.edge = ScrollEdge.end,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is! ScrollEndNotification) return false;

        final remaining = edge == ScrollEdge.end
            ? notification.metrics.extentAfter
            : notification.metrics.extentBefore;

        if (remaining < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
