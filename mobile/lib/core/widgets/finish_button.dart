import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum FinishButtonVariant { primary, outline, secondary, text }

class FinishButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final FinishButtonVariant variant;
  final Widget? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Gradient? gradient;

  const FinishButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = FinishButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52.0,
    this.borderRadius = 14.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Color? backgroundColor;
    Color textColor;
    Border? border;
    Gradient? activeGradient;
    List<BoxShadow>? shadows;

    switch (variant) {
      case FinishButtonVariant.primary:
        if (isDisabled) {
          backgroundColor = AppColors.primary.withOpacity(0.5);
          activeGradient = null;
          shadows = null;
        } else {
          activeGradient = gradient ??
              const LinearGradient(
                colors: [Color(0xFF087F5B), Color(0xFF066B4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
          shadows = [
            BoxShadow(
              color: const Color(0xFF087F5B).withOpacity(0.26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ];
        }
        textColor = Colors.white;
        border = null;
        break;
      case FinishButtonVariant.outline:
        backgroundColor = Colors.white;
        textColor = isDisabled ? AppColors.textMuted : AppColors.textDark;
        border = Border.all(color: const Color(0xFFE5E7EB), width: 1.2);
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
        break;
      case FinishButtonVariant.secondary:
        backgroundColor = AppColors.surfaceMuted;
        textColor = isDisabled ? AppColors.textMuted : AppColors.textDark;
        border = null;
        break;
      case FinishButtonVariant.text:
        backgroundColor = Colors.transparent;
        textColor = isDisabled ? AppColors.textMuted : AppColors.primary;
        border = null;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width ?? double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: activeGradient == null ? backgroundColor : null,
        gradient: activeGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isDisabled ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        variant == FinishButtonVariant.primary ? Colors.white : AppColors.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleSmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
