import 'package:flutter/material.dart';

class LensLogo extends StatelessWidget {
  const LensLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.semanticLabel = 'LENS',
  });

  final double? width;
  final double? height;
  final Color? color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/lens-logo.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    semanticLabel: semanticLabel,
  );
}
