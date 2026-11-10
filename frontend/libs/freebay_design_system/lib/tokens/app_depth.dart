import 'package:flutter/material.dart';

class AppDepth {
  AppDepth._();

  static const double pressOffset = 3.0;
  static const Offset shadowOffset = Offset(3, 3);
  static const Offset shadowOffsetSmall = Offset(2, 2);
  static const double borderThin = 1.5;
  static const double borderThick = 2.0;

  static List<BoxShadow> hard(Color color) => [
    BoxShadow(color: color, offset: shadowOffset),
  ];

  static List<BoxShadow> hardSmall(Color color) => [
    BoxShadow(color: color, offset: shadowOffsetSmall),
  ];
}
