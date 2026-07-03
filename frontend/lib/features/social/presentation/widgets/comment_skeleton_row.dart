import 'package:flutter/material.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';

class CommentSkeletonRow extends StatelessWidget {
  const CommentSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBlock(width: 32, height: 32),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(height: 14, width: 100),
            SizedBox(height: 6),
            ShimmerBlock(height: 12, width: 160),
          ],
        ),
      ],
    );
  }
}
