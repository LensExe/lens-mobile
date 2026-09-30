import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassType {
  lightFrost, // Header, bottom bar, light floating controls: rgba(255, 255, 255, 0.8)
  darkFrost, // Media floating badges, dark controls: rgba(9, 9, 11, 0.48)
}

class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double blur;
  final GlassType type;
  final Color? customColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxShape shape;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    this.child,
    this.blur = 16.0,
    this.type = GlassType.lightFrost,
    this.customColor,
    this.borderRadius,
    this.border,
    this.padding,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.boxShadow,
  });

  /// Factory for Header & Tab bar glassmorphism
  factory GlassContainer.translucentBar({
    Key? key,
    required Widget child,
    bool isTop = false,
  }) {
    return GlassContainer(
      key: key,
      blur: 20.0,
      customColor: const Color(0xCCFFFFFF), // rgba(255, 255, 255, 0.80)
      border: Border(
        top: isTop
            ? const BorderSide(color: Color(0x99D4D4D8), width: 1.0)
            : BorderSide.none,
        bottom: !isTop
            ? const BorderSide(color: Color(0x99D4D4D8), width: 1.0)
            : BorderSide.none,
      ),
      child: child,
    );
  }

  /// Factory for floating circular buttons (Back, Heart, Share)
  factory GlassContainer.floatingControl({
    Key? key,
    required Widget child,
    double size = 44.0,
    bool isDark = false,
  }) {
    return GlassContainer(
      key: key,
      width: size,
      height: size,
      shape: BoxShape.circle,
      blur: 16.0,
      customColor: isDark
          ? const Color(0x8009090B) // rgba(9, 9, 11, 0.50)
          : const Color(0xC0FFFFFF), // rgba(255, 255, 255, 0.75)
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.8),
        width: 1.0,
      ),
      child: Center(child: child),
    );
  }

  /// Factory for media floating badges (Verified, Duration, Category)
  factory GlassContainer.mediaBadge({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
    BorderRadius? borderRadius,
  }) {
    return GlassContainer(
      key: key,
      blur: 12.0,
      customColor: const Color(0x7A09090B), // rgba(9, 9, 11, 0.48)
      padding: padding,
      borderRadius: borderRadius ?? BorderRadius.circular(9999),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.20),
        width: 1.0,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        customColor ??
        (type == GlassType.lightFrost
            ? const Color(0xCCFFFFFF)
            : const Color(0x7A09090B));

    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(16));

    final effectiveBorder =
        border ??
        Border.all(
          color: type == GlassType.lightFrost
              ? const Color(0x80D4D4D8)
              : Colors.white.withValues(alpha: 0.20),
          width: 1.0,
        );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        shape: shape,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (shape == BoxShape.circle) {
      return ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
