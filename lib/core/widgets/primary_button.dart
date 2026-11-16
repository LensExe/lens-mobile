import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;
  final double height;
  final Widget? leadingIcon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.expand = true,
    this.height = AppTokens.primaryButtonHeight, // 52px
    this.leadingIcon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final content = AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        child: SizedBox(
          height: widget.height,
          child: ElevatedButton(
            onPressed: isEnabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ember,
              foregroundColor: AppColors.snow,
              disabledBackgroundColor: const Color(0xFFE8E8E9),
              disabledForegroundColor: const Color(0xFF8E8E93),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.pillRadius),
              ),
              textStyle: AppTypography.titleMd(color: AppColors.snow),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.snow,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        widget.leadingIcon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMd(
                            color: isEnabled
                                ? AppColors.snow
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: content)
        : content;
  }
}
