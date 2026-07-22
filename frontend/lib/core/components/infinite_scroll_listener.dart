import 'package:flutter/material.dart';

/// Fires [onLoadMore] once a scroll settles within [threshold] pixels of the end.
class InfiniteScrollListener extends StatelessWidget {
  static const double defaultThreshold = 400;

  final VoidCallback onLoadMore;
  final double threshold;
  final Widget child;

  const InfiniteScrollListener({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = defaultThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
