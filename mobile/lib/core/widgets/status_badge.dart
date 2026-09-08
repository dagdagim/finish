import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.replaceAll('_', ' ');

    switch (status.toUpperCase()) {
      case 'OPEN':
      case 'POSTED':
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        label = 'OPEN';
        break;
      case 'ACCEPTED':
      case 'ASSIGNED':
        bg = const Color(0xFFEFF6FF); // Light blue
        fg = const Color(0xFF2563EB); // Blue
        label = 'ASSIGNED';
        break;
      case 'IN_PROGRESS':
        bg = const Color(0xFFFEF3C7); // Amber light
        fg = const Color(0xFFD97706); // Amber dark
        label = 'IN PROGRESS';
        break;
      case 'SUBMITTED':
      case 'AWAITING_APPROVAL':
        bg = const Color(0xFFF3E8FF); // Purple light
        fg = const Color(0xFF7C3AED); // Purple
        label = 'UNDER REVIEW';
        break;
      case 'COMPLETED':
      case 'PAID':
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        label = 'COMPLETED';
        break;
      case 'DISPUTED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'DISPUTED';
        break;
      default:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
