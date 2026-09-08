import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'status_badge.dart';

class TaskCard extends StatefulWidget {
  final String title;
  final String category;
  final String price;
  final String? distance;
  final String? timeText;
  final String? locationText;
  final String? customerRating;
  final String? status;
  final VoidCallback onTap;
  final String? buttonText;

  const TaskCard({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    this.distance,
    this.timeText,
    this.locationText,
    this.customerRating,
    this.status,
    required this.onTap,
    this.buttonText,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'delivery':
        return const Color(0xFF087F5B);
      case 'cleaning':
        return const Color(0xFF0284C7);
      case 'shopping':
        return const Color(0xFFD97706);
      case 'moving':
        return const Color(0xFF7C3AED);
      case 'assembly':
        return const Color(0xFFEA580C);
      case 'tech':
        return const Color(0xFF2563EB);
      case 'plumbing':
        return const Color(0xFF0D9488);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'moving':
        return Icons.inventory_2_outlined;
      case 'assembly':
        return Icons.build_outlined;
      case 'tech':
        return Icons.laptop_chromebook_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category);
    final categoryIcon = _getCategoryIcon(widget.category);
    final isElevated = _isHovered || _isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isElevated ? categoryColor.withOpacity(0.6) : const Color(0xFFE5E7EB),
                width: isElevated ? 1.5 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isElevated
                      ? categoryColor.withOpacity(0.12)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: isElevated ? 12 : 4,
                  offset: isElevated ? const Offset(0, 4) : const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Category Pill & Status / Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon, size: 12, color: categoryColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.category.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.status != null)
                        StatusBadge(status: widget.status!)
                      else
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Main Row: Title & Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.price,
                          style: AppTypography.priceMedium.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.locationText != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.locationText!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 8),

                  // Bottom Meta Row: Distance, Time, Rating (Overflow Protected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.distance != null) ...[
                              Text(
                                widget.distance!,
                                style: AppTypography.labelMedium.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                            ],
                            if (widget.timeText != null)
                              Flexible(
                                child: Text(
                                  widget.timeText!,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.customerRating != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  widget.customerRating!,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB45309),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
