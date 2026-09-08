import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/finish_card.dart';
import '../../core/widgets/animated_checkmark.dart';
import '../../data/models/task_model.dart';
import '../../data/services/api_service.dart';
import '../main_scaffold.dart';

class TaskCompletionScreen extends StatefulWidget {
  final TaskModel task;

  const TaskCompletionScreen({super.key, required this.task});

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedTags = [];
  double _tipAmount = 0;
  bool _isSubmittingRating = false;

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate ${widget.task.assignedTaskerName ?? "Tasker"}',
                                style: AppTypography.titleSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Task: "${widget.task.title}"',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // Star Rating Interactive Selector
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              return IconButton(
                                icon: Icon(
                                  star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 38,
                                ),
                                onPressed: () {
                                  setModalState(() => _selectedRating = star);
                                  setState(() => _selectedRating = star);
                                },
                              );
                            }),
                          ),
                          Text(
                            _selectedRating == 5
                                ? '⭐ Exceptional (5.0)'
                                : _selectedRating == 4
                                    ? '⭐ Great Work (4.0)'
                                    : _selectedRating == 3
                                        ? '⭐ Good (3.0)'
                                        : '⭐ Needs Improvement ($_selectedRating.0)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Compliment Chips
                    const Text('What went well?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        '⚡ Fast Delivery',
                        '🎯 High Quality',
                        '🤝 Polite & Friendly',
                        '📍 Accurate GPS',
                        '🛠️ Expert Handling',
                        '📱 Great Updates',
                      ].map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF047857) : AppColors.textDark)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD1FAE5),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB)),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Review Notes Input
                    const Text('Write a review (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reviewController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Share details of your experience with ${widget.task.assignedTaskerName ?? "the tasker"}...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Add a Tip Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add a Tip (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark)),
                        if (_tipAmount > 0)
                          Text('+${_tipAmount.toInt()} ETB Tip', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF047857))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [0, 20, 50, 100].map((tip) {
                        final isSelected = _tipAmount == tip;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () => setModalState(() => _tipAmount = tip.toDouble()),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF064E3B) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFE5E7EB)),
                                ),
                                child: Center(
                                  child: Text(
                                    tip == 0 ? 'No Tip' : '+$tip ETB',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Submit Review Button
                    FinishButton(
                      text: _isSubmittingRating ? 'Saving...' : 'Submit Rating ($_selectedRating.0 ★)',
                      onPressed: _isSubmittingRating
                          ? null
                          : () async {
                              setModalState(() => _isSubmittingRating = true);
                              final reviewText = _reviewController.text.trim().isNotEmpty
                                  ? _reviewController.text.trim()
                                  : (_selectedTags.isNotEmpty ? _selectedTags.join(', ') : 'Great tasker, highly recommended!');

                              await ApiService().rateTasker(
                                widget.task.id,
                                rating: _selectedRating,
                                review: reviewText,
                                tags: _selectedTags,
                                tipAmount: _tipAmount,
                              );

                              if (mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text('Thank you! Your $_selectedRating.0 ★ rating was submitted for ${widget.task.assignedTaskerName ?? "your tasker"}.'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF047857),
                                  ),
                                );
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const MainScaffold()),
                                  (route) => false,
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiptModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Receipt', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              _receiptItem('Task Title', widget.task.title),
              _receiptItem('Task Price', '${widget.task.pricing.budget} ETB'),
              _receiptItem('Platform Fee (10%)', '${widget.task.pricing.platformFee} ETB'),
              const Divider(height: 24, color: AppColors.border),
              _receiptItem('Total Paid', '${widget.task.pricing.budget} ETB', isBold: true),
              const SizedBox(height: 24),
              FinishButton(
                text: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: isBold
                  ? AppTypography.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)
                  : AppTypography.titleSmall.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated completion checkmark
              const AnimatedCheckmark(
                size: 96,
                circleColor: AppColors.primary,
                checkColor: Colors.white,
              ),
              const SizedBox(height: 28),

              Text(
                'Task completed!',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything is done.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Payment Released Box
              FinishCard(
                borderRadius: 14,
                backgroundColor: AppColors.surfaceMuted,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Payment released',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.task.pricing.budget} ETB',
                      style: AppTypography.priceLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Primary: Rate Tasker
              FinishButton(
                text: 'Rate Tasker',
                onPressed: _showRatingModal,
              ),
              const SizedBox(height: 12),

              // Secondary: View Receipt
              FinishButton(
                text: 'View Receipt',
                variant: FinishButtonVariant.outline,
                onPressed: _showReceiptModal,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
