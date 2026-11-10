import 'dart:ui';
import 'dart:math' as math;

bool validVideoEditBounds({
  required int durationMs,
  required int startMs,
  required int endMs,
  required Rect crop,
}) =>
    durationMs > 0 &&
    startMs >= 0 &&
    endMs > startMs &&
    endMs <= durationMs &&
    crop.left.isFinite &&
    crop.top.isFinite &&
    crop.right.isFinite &&
    crop.bottom.isFinite &&
    crop.left >= 0 &&
    crop.top >= 0 &&
    crop.right <= 1 &&
    crop.bottom <= 1 &&
    crop.width > 0 &&
    crop.height > 0;

double maxVideoCropWidth(Size videoSize, double ratio) =>
    (ratio * videoSize.height / videoSize.width).clamp(0.0, 1.0).toDouble();

Rect videoCropForRatio({
  required double width,
  required Size videoSize,
  required double ratio,
}) {
  final maxWidth = maxVideoCropWidth(videoSize, ratio);
  final cropWidth = width.clamp(math.min(.2, maxWidth), maxWidth).toDouble();
  final cropHeight = cropWidth * videoSize.width / videoSize.height / ratio;
  return Rect.fromLTWH(
    (1 - cropWidth) / 2,
    (1 - cropHeight) / 2,
    cropWidth,
    cropHeight,
  );
}
