import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../main_scaffold.dart';

class RoleIntentScreen extends StatelessWidget {
  const RoleIntentScreen({super.key});

  void _selectMode(BuildContext context, String mode) async {
    final auth = context.read<AuthProvider>();
    if (mode != auth.activeMode) {
      await auth.toggleMode();
    }
    if (context.mounted) {
      context.read<TaskProvider>().fetchTasks(roleMode: mode);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _selectMode(context, 'customer'),
            child: Text(
              'Skip',
              style: AppTypography.labelLarge.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'How would you like\nto start?',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your primary mode. You can easily switch between them anytime from your profile.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 36),

              // Option 1: Customer Mode
              FinishCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                onTap: () => _selectMode(context, 'customer'),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I need something done',
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Post small jobs and connect with trusted local helpers.',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Option 2: Tasker Mode
              FinishCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                onTap: () => _selectMode(context, 'tasker'),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.work_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I want to earn by doing tasks',
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find flexible nearby gigs, accept offers, and get paid securely.',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
