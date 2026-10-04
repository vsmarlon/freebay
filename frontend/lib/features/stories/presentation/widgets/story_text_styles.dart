import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';

TextStyle storyTextStyle(StoryTextStyle style, Color color) {
  switch (style) {
    case StoryTextStyle.classic:
      return AppTypography.h2
          .weight(500)
          .copyWith(fontFamily: AppTypography.fontFamily, color: color);
    case StoryTextStyle.strong:
      return AppTypography.h2
          .weight(800)
          .copyWith(
            fontFamily: AppTypography.displayFontFamily,
            color: color,
            letterSpacing: -0.7,
          );
    case StoryTextStyle.editorial:
      return AppTypography.h2
          .weight(600)
          .copyWith(
            fontFamily: AppTypography.displayFontFamily,
            color: color,
            letterSpacing: 1.2,
          );
    case StoryTextStyle.compact:
      return AppTypography.bodyLarge
          .weight(700)
          .copyWith(
            fontFamily: AppTypography.fontFamily,
            color: color,
            letterSpacing: 0.3,
          );
  }
}

Color storyColorFromArgb(int value) => Color(value);
