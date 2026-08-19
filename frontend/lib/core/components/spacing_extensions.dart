import 'package:flutter/widgets.dart';

extension SpacingNumX on num {
  Widget get vGap => SizedBox(height: toDouble());
  Widget get hGap => SizedBox(width: toDouble());
}
