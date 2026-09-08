import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../tasker/verification/tasker_verification_wizard_screen.dart';
import '../tasker/tasker_wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isCustomer = auth.isCustomerMode;
    final isAdmin = user?.role == 'admin' || user?.email == 'admin@finish.et';

    final name = user?.fullName ?? (isAdmin ? 'Admin Operations' : (isCustomer ? 'Sarah Mamo' : 'Daniel Kebede'));
    final phone = user?.phone ?? (isAdmin ? '+251 911 000 000' : (isCustomer ? '+251 911 223 344' : '+251 912 345 678'));
    final rating = user?.rating ?? 0.0;
    final isNewTasker = user?.isNewTasker ?? (rating == 0.0);
    final isVerified = user?.isIdentityVerified ?? false;
    final verificationStatus = user?.verificationStatus ?? 'NOT_SUBMITTED';
    final completed = user?.completedTasksCount ?? (isCustomer ? 8 : 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile & Settings', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Profile',
            onPressed: () => auth.fetchMe(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => auth.fetchMe(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              FinishCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isAdmin ? const Color(0xFF064E3B) : AppColors.primaryLight,
                      child: Text(
                        name.isNotEmpty ? name[0] : 'U',
                        style: AppTypography.titleLarge.copyWith(color: isAdmin ? Colors.white : AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: AppTypography.titleSmall.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isAdmin)
                                const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFF10B981))
                              else if (isVerified)
                                const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF047857))
                              else
                                const Icon(Icons.shield_outlined, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(phone, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                isNewTasker ? '★ New Tasker' : '★ ${rating.toStringAsFixed(1)}',
                                style: AppTypography.labelLarge.copyWith(fontSize: 13),
                              ),
                              const SizedBox(width: 10),
                              Text('$completed completed', style: AppTypography.labelMedium.copyWith(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // TASKER VERIFICATION STATUS BANNER
              if (!isAdmin) ...[
                if (isVerified)
                  FinishCard(
                    backgroundColor: const Color(0xFFECFDF5),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                    padding: const EdgeInsets.all(14),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Official Verified Tasker ✓', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 13.5)),
                              Text('Identity, background & skills verified by FINISH Admin', style: TextStyle(color: Color(0xFF047857), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (verificationStatus == 'PENDING')
                  FinishCard(
                    backgroundColor: const Color(0xFFFEF3C7),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                    padding: const EdgeInsets.all(14),
                    child: const Row(
                      children: [
                        Icon(Icons.pending_actions_rounded, color: Color(0xFF92400E), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Verification Under Admin Review ⏳', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w800, fontSize: 13.5)),
                              Text('Your ID, face scan & category questionnaire are being reviewed.', style: TextStyle(color: Color(0xFFB45309), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FinishCard(
                    backgroundColor: const Color(0xFF064E3B),
                    border: Border.all(color: const Color(0xFF047857)),
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TaskerVerificationWizardScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Get Verified Tasker Badge ✓',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fill experience, education, National ID, face scan & category questions',
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
              ],

              // ADMIN MASTER CONTROL DASHBOARD BANNER
              if (isAdmin) ...[
                FinishCard(
                  backgroundColor: const Color(0xFF064E3B),
                  border: Border.all(color: const Color(0xFF047857)),
                  padding: const EdgeInsets.all(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF34D399), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Master Admin Control 🛡️',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Control users, tasks, disputes, escrow & broadcasts',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // PROMINENT MODE SWITCHER BANNER
              FinishCard(
                backgroundColor: isCustomer ? const Color(0xFFEFF6FF) : AppColors.primaryLight,
                border: Border.all(color: isCustomer ? const Color(0xFF93C5FD) : AppColors.primaryBorder),
                padding: const EdgeInsets.all(16),
                onTap: () async {
                  await auth.toggleMode();
                  if (context.mounted) {
                    context.read<TaskProvider>().fetchTasks(roleMode: auth.activeMode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Switched to ${auth.activeMode.toUpperCase()} mode')),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      isCustomer ? Icons.work_outline : Icons.shopping_bag_outlined,
                      color: isCustomer ? const Color(0xFF2563EB) : AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCustomer ? 'Switch to Tasker Mode' : 'Switch to Customer Mode',
                            style: AppTypography.titleSmall.copyWith(
                              color: isCustomer ? const Color(0xFF1E40AF) : AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCustomer
                                ? 'Start earning by discovering nearby tasks'
                                : 'Post small jobs you need done',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Sections
              Text('Account & Preferences', style: AppTypography.labelLarge.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 10),

              _buildSettingsItem(
                context,
                icon: Icons.credit_card_rounded,
                title: 'Finish Wallet & Visa Card',
                subtitle: 'Virtual debit card, payouts, deposits & task ledger',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TaskerWalletScreen()),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (Amharic available)',
                onTap: () {
                  _showLanguageModal(context);
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                subtitle: 'Push, SMS, Task alerts',
                onTap: () {},
              ),
              _buildSettingsItem(
                context,
                icon: Icons.security_outlined,
                title: 'Safety Center & ID Verification',
                subtitle: 'Emergency contact, ID verification, skills assessment',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TaskerVerificationWizardScreen()),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help Center & Support',
                subtitle: 'FAQ, Contact Support',
                onTap: () {},
              ),
              _buildSettingsItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy & Terms of Service',
                subtitle: 'Escrow protection and rules',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // Logout Button
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                  label: Text(
                    'Log Out',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.error),
                  ),
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FinishCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
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
              Text('Select Language', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check, color: AppColors.primary),
                title: const Text('English (US)'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                title: const Text('አማርኛ (Amharic)'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language switched to Amharic (አማርኛ)')),
                  );
                },
              ),
              ListTile(
                title: const Text('Afaan Oromoo'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
