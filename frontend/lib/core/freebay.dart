import 'package:flutter/material.dart';

class Freebay {
  Freebay._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const SizedBox horizontalSpacing4 = SizedBox(width: xs);
  static const SizedBox horizontalSpacing8 = SizedBox(width: sm);
  static const SizedBox horizontalSpacing12 = SizedBox(width: 12);
  static const SizedBox horizontalSpacing16 = SizedBox(width: md);
  static const SizedBox horizontalSpacing24 = SizedBox(width: lg);
  static const SizedBox horizontalSpacing32 = SizedBox(width: xl);
  static const SizedBox horizontalSpacing48 = SizedBox(width: xxl);

  static const SizedBox verticalSpacing4 = SizedBox(height: xs);
  static const SizedBox verticalSpacing8 = SizedBox(height: sm);
  static const SizedBox verticalSpacing12 = SizedBox(height: 12);
  static const SizedBox verticalSpacing16 = SizedBox(height: md);
  static const SizedBox verticalSpacing24 = SizedBox(height: lg);
  static const SizedBox verticalSpacing32 = SizedBox(height: xl);
  static const SizedBox verticalSpacing48 = SizedBox(height: xxl);

  static EdgeInsets paddingAll4 = const EdgeInsets.all(xs);
  static EdgeInsets paddingAll8 = const EdgeInsets.all(sm);
  static EdgeInsets paddingAll12 = const EdgeInsets.all(12);
  static EdgeInsets paddingAll16 = const EdgeInsets.all(md);
  static EdgeInsets paddingAll24 = const EdgeInsets.all(lg);
  static EdgeInsets paddingAll32 = const EdgeInsets.all(xl);

  static EdgeInsets paddingHorizontal8 =
      const EdgeInsets.symmetric(horizontal: sm);
  static EdgeInsets paddingHorizontal12 =
      const EdgeInsets.symmetric(horizontal: 12);
  static EdgeInsets paddingHorizontal16 =
      const EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets paddingHorizontal24 =
      const EdgeInsets.symmetric(horizontal: lg);
  static EdgeInsets paddingHorizontal32 =
      const EdgeInsets.symmetric(horizontal: xl);

  static EdgeInsets paddingVertical8 = const EdgeInsets.symmetric(vertical: sm);
  static EdgeInsets paddingVertical12 =
      const EdgeInsets.symmetric(vertical: 12);
  static EdgeInsets paddingVertical16 =
      const EdgeInsets.symmetric(vertical: md);
  static EdgeInsets paddingVertical24 =
      const EdgeInsets.symmetric(vertical: lg);
  static EdgeInsets paddingVertical32 =
      const EdgeInsets.symmetric(vertical: xl);

  static EdgeInsets paddingLTRB(
          double left, double top, double right, double bottom) =>
      EdgeInsets.fromLTRB(left, top, right, bottom);
}
