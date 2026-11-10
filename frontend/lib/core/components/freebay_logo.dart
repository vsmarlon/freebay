import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class FreeBayLogo extends StatelessWidget {
  const FreeBayLogo({super.key, this.width = 220, this.color});

  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'FreeBay',
      child: SvgPicture.asset(
        'assets/images/freebay_logo.svg',
        width: width,
        theme: SvgTheme(currentColor: color ?? context.textPrimary),
        excludeFromSemantics: true,
      ),
    );
  }
}
