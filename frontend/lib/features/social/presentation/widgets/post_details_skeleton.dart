import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class PostDetailsSkeleton extends StatelessWidget {
  const PostDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBlock(height: 48),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBlock(width: 48, height: 48),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(height: 14, width: 120),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 12, width: 80),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          ShimmerBlock(height: 300),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerBlock(width: 24, height: 24),
              SizedBox(width: 16),
              ShimmerBlock(width: 24, height: 24),
              SizedBox(width: 16),
              ShimmerBlock(width: 24, height: 24),
            ],
          ),
          SizedBox(height: 24),
          CommentSkeletonRow(),
          SizedBox(height: 12),
          CommentSkeletonRow(),
          SizedBox(height: 12),
          CommentSkeletonRow(),
        ],
      ),
    );
  }
}

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
