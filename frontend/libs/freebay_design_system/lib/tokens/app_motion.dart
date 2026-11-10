import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Duration tap = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration enter = Duration(milliseconds: 240);
  static const Duration shimmer = Duration(milliseconds: 1000);
  static const Duration ambient = Duration(milliseconds: 8000);

  static const Curve tapCurve = Curves.linear;
  static const Curve baseCurve = Curves.linear;
  static const Curve enterCurve = Curves.easeOut;

  static Duration forContext(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
