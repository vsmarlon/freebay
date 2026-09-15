import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freebay/core/components/app_image_viewer.dart';

void showFullScreenImage(BuildContext context, String imageUrl) {
  unawaited(showAppImageViewer(context, imageUrl));
}
