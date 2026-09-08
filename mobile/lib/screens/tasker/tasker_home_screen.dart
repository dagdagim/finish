import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/task_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/wallet_provider.dart';

import 'tasker_active_job_screen.dart';
import 'tasker_task_details_screen.dart';
import 'tasker_wallet_screen.dart';
import 'verification/tasker_verification_wizard_screen.dart';

class TaskerHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const TaskerHomeScreen({super.key, this.onTabChange});

  @override
  State<TaskerHomeScreen> createState() => _TaskerHomeScreenState();
}

class _TaskerHomeScreenState extends State<TaskerHomeScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id ?? 'tasker_daniel';
      final userName = auth.currentUser?.fullName ?? 'Daniel Kebede';
      context.read<TaskProvider>().setCurrentUser(userId, userName);
      context.read<WalletProvider>().fetchWallet();
      context.read<TaskProvider>().fetchTasks(roleMode: 'tasker');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final tasks = taskProvider.openTasks;

    final filteredTasks = _selectedFilter == 'all'
        ? tasks
        : tasks.where((t) => t.category.toLowerCase() == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await taskProvider.fetchTasks(roleMode: 'tasker');
            await walletProvider.fetchWallet();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Header (Brand Logo, Online Status, Role Toggle & Notifications)
                Row(
                  children: [
                    // Brand & Availability Pill
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF087F5B), Color(0xFF065F44)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF087F5B).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.handyman_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'FINISH',
                                      style: AppTypography.displayLarge.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'TASKER',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Online · Available',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: const Color(0xFF059669),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Role Switcher Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        auth.switchMode();
                        taskProvider.fetchTasks(roleMode: auth.activeMode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Customer',
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Notification Icon
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, _) {
                        final unreadCount = chatProvider.totalUnreadCount;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => widget.onTabChange?.call(3),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 18,
                                  color: AppColors.textDark,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // VERIFICATION STATUS PROMPT BANNER
                if (auth.currentUser?.isIdentityVerified != true) ...[
                  if (auth.currentUser?.verificationStatus == 'PENDING')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: Color(0xFF92400E), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Identity verification under Admin review. Verified Badge ✓ will activate upon approval.',
                              style: TextStyle(color: Color(0xFF92400E), fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TaskerVerificationWizardScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF064E3B).withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Get Verified Tasker Badge ✓',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    'Complete National ID, face scan & category questionnaire',
                                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Verify Now',
                                style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                ],

                // Finish Visa Virtual Card / Earnings Hub
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TaskerWalletScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: walletProvider.wallet.card.isFrozen
                          ? const LinearGradient(
                              colors: [Color(0xFF334155), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF064E3B), Color(0xFF0F172A), Color(0xFF065F46)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: walletProvider.wallet.card.isFrozen
                            ? const Color(0xFF64748B)
                            : const Color(0xFF34D399).withOpacity(0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: walletProvider.wallet.card.isFrozen
                              ? Colors.black.withOpacity(0.2)
                              : const Color(0xFF064E3B).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Top Row: Brand & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFFBBF24)),
                                      SizedBox(width: 3),
                                      Text(
                                        'FINISH',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'VISA DEBIT',
                                  style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: walletProvider.wallet.card.isFrozen
                                    ? const Color(0xFFFEE2E2).withOpacity(0.2)
                                    : const Color(0xFFDCFCE7).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: walletProvider.wallet.card.isFrozen
                                      ? const Color(0xFFFECACA).withOpacity(0.5)
                                      : const Color(0xFF86EFAC).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    walletProvider.wallet.card.isFrozen ? Icons.lock_rounded : Icons.check_circle_rounded,
                                    size: 10,
                                    color: walletProvider.wallet.card.isFrozen ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    walletProvider.wallet.card.isFrozen ? 'FROZEN' : 'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: walletProvider.wallet.card.isFrozen ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Balance & Chip Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AVAILABLE BALANCE',
                                    style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${walletProvider.wallet.availableBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}.00 ETB',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Mini Visa EMV Chip graphic
                            Container(
                              width: 34,
                              height: 25,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFDE68A), Color(0xFFD97706), Color(0xFFFBBF24)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFB45309), width: 0.7),
                              ),
                              child: Center(
                                child: Container(
                                  width: 18,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF78350F).withOpacity(0.6), width: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Divider(color: Colors.white.withOpacity(0.15), height: 1),
                        const SizedBox(height: 10),

                        // Card Mask, Total Earned & Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '•••• ',
                                  style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1),
                                ),
                                Text(
                                  walletProvider.wallet.card.last4,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Total: ', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                                Text(
                                  '${walletProvider.wallet.totalEarned} ETB',
                                  style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Manage & Withdraw',
                                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // High Demand Live Radar Signal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'High Demand Nearby in Bole',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '12 open tasks within 5 km · Avg: 550 ETB',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryDark.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (taskProvider.ongoingTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF064E3B).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flash_on_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ACTIVE JOB IN PROGRESS',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${taskProvider.ongoingTasks.first.pricing.budget} ETB',
                              style: AppTypography.titleSmall.copyWith(
                                color: const Color(0xFF6EE7B7),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          taskProvider.ongoingTasks.first.title,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${taskProvider.ongoingTasks.first.customerName} · ${taskProvider.ongoingTasks.first.pickupLocation.address}',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onTabChange != null) {
                                widget.onTabChange!(1); // Switch to Ongoing tab
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TaskerActiveJobScreen(task: taskProvider.ongoingTasks.first),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.navigation_rounded, size: 16),
                            label: const Text(
                              'Resume Active Job & Track Route',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF064E3B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All Jobs', 'all'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Delivery', 'delivery'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Cleaning', 'cleaning'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Assembly', 'assembly'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Moving', 'moving'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Shopping', 'shopping'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Recommended Jobs Feed Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Tasks Near You',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onTabChange != null) {
                          widget.onTabChange!(1); // Go to Nearby
                        }
                      },
                      child: Text(
                        'View map',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Jobs Feed
                if (filteredTasks.isNotEmpty) ...[
                  for (final task in filteredTasks)
                    TaskCard(
                      title: task.title,
                      category: task.category,
                      price: '${task.pricing.budget} ETB',
                      locationText: task.routeDisplay,
                      distance: '${task.distanceKm} km',
                      timeText: '${task.estimatedDurationMin} min',
                      customerRating: 'Customer ${task.customerRating}',
                      status: task.status,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskerTaskDetailsScreen(task: task),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 32, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks matching this category',
                          style: AppTypography.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Try selecting All Jobs or pull down to refresh.',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
