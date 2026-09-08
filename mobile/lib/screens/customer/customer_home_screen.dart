import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';

import 'post_task/post_task_wizard_screen.dart';
import 'customer_task_details_screen.dart';
import '../chat/task_chat_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const CustomerHomeScreen({super.key, this.onTabChange});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks(roleMode: 'customer');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = const [
    {
      'id': 'delivery',
      'label': 'Delivery',
      'subtitle': 'Fast Courier',
      'icon': Icons.local_shipping_outlined,
      'color': Color(0xFF087F5B),
      'badge': 'POPULAR',
    },
    {
      'id': 'cleaning',
      'label': 'Cleaning',
      'subtitle': 'Home & Office',
      'icon': Icons.cleaning_services_outlined,
      'color': Color(0xFF0284C7),
      'badge': 'HOT',
    },
    {
      'id': 'shopping',
      'label': 'Shopping',
      'subtitle': 'Errands & Stores',
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFD97706),
      'badge': null,
    },
    {
      'id': 'moving',
      'label': 'Moving',
      'subtitle': 'Trucks & Labor',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFF7C3AED),
      'badge': 'TOP',
    },
    {
      'id': 'assembly',
      'label': 'Assembly',
      'subtitle': 'Furniture & Items',
      'icon': Icons.build_outlined,
      'color': Color(0xFFEA580C),
      'badge': null,
    },
    {
      'id': 'tech',
      'label': 'Tech Help',
      'subtitle': 'PC, Phone & Wifi',
      'icon': Icons.laptop_chromebook_outlined,
      'color': Color(0xFF2563EB),
      'badge': null,
    },
    {
      'id': 'plumbing',
      'label': 'Plumbing',
      'subtitle': 'Pipes & Repairs',
      'icon': Icons.plumbing_outlined,
      'color': Color(0xFF0D9488),
      'badge': null,
    },
    {
      'id': 'electrical',
      'label': 'Electrical',
      'subtitle': 'Wiring & Light',
      'icon': Icons.electrical_services_outlined,
      'color': Color(0xFFB45309),
      'badge': null,
    },
    {
      'id': 'handyman',
      'label': 'Handyman',
      'subtitle': 'Home Fixes',
      'icon': Icons.handyman_outlined,
      'color': Color(0xFF475569),
      'badge': 'PROS',
    },
  ];

  void _openPostTask([String? initialCategory]) {
    final taskProvider = context.read<TaskProvider>();
    taskProvider.resetWizard();
    if (initialCategory != null && initialCategory != 'all') {
      taskProvider.wizardCategory = initialCategory;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostTaskWizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final activeTasks = taskProvider.activeTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await taskProvider.fetchTasks(roleMode: 'customer');
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Header (Brand Logo, Location Badge, Role Toggle & Notifications)
                Row(
                  children: [
                    // Brand & Location
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
                                Icons.check_rounded,
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
                                Text(
                                  'FINISH',
                                  style: AppTypography.displayLarge.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: AppColors.primary,
                                  ),
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
                                        'Addis Ababa, Bole',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.textMuted,
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
                              'Tasker',
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
                const SizedBox(height: 16),

                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks, delivery, repairs...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Hero Post a Task Banner (Emerald Gradient with Action)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF087F5B), Color(0xFF065F44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF087F5B).withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Escrow Protected',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_alt_outlined, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '1,200+ Taskers',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Need something done today?',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Post your task in 60 seconds and receive instant offers.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openPostTask(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Post a Task Now',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Popular Categories Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore Services',
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select a category to find verified taskers',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openPostTask(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View all',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Interactive 3x3 Animated Hover Category Grid (Spacious childAspectRatio 0.82)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return _ServiceCategoryTile(
                      id: cat['id'] as String,
                      label: cat['label'] as String,
                      subtitle: cat['subtitle'] as String,
                      icon: cat['icon'] as IconData,
                      color: cat['color'] as Color,
                      badge: cat['badge'] as String?,
                      onTap: () => _openPostTask(cat['id'] as String),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Active Tasks Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Tasks',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (activeTasks.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          if (widget.onTabChange != null) widget.onTabChange!(1);
                        },
                        child: Text(
                          'View all',
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

                if (activeTasks.isNotEmpty) ...[
                  for (final task in activeTasks.take(2))
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerTaskDetailsScreen(task: task),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        task.category.toUpperCase(),
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2563EB),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'In Progress',
                                            style: AppTypography.labelMedium.copyWith(
                                              color: const Color(0xFF1D4ED8),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        task.scheduleText,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${task.pricing.budget} ETB',
                                      style: AppTypography.priceMedium.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primaryLight,
                                      child: const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        task.assignedTaskerName != null
                                            ? 'Tasker: ${task.assignedTaskerName}'
                                            : 'Reviewing offers...',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TaskChatScreen(
                                              task: task,
                                              otherUserId: task.assignedTaskerName == 'Daniel K.' ? 'tasker_daniel' : 'tasker_user',
                                              otherUserName: task.assignedTaskerName ?? 'Tasker Partner',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppColors.primary),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Chat',
                                              style: AppTypography.labelMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ] else ...[
                  // Clean Empty State
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 22,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks currently in progress',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Post any errand, delivery, or repair and get matched quickly.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // How FINISH Works (Security Reassurance Card)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'How FINISH Protects You',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSecurityStep(
                        number: '1',
                        title: 'Post Free',
                        subtitle: 'Describe the task and set your budget.',
                      ),
                      const SizedBox(height: 6),
                      _buildSecurityStep(
                        number: '2',
                        title: 'Select Tasker',
                        subtitle: 'Compare verified tasker profiles and ratings.',
                      ),
                      const SizedBox(height: 6),
                      _buildSecurityStep(
                        number: '3',
                        title: 'Pay on Completion',
                        subtitle: 'Funds released only after you are 100% satisfied.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCategoryTile extends StatefulWidget {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ServiceCategoryTile({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  State<_ServiceCategoryTile> createState() => _ServiceCategoryTileState();
}

class _ServiceCategoryTileState extends State<_ServiceCategoryTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isElevated = _isHovered || _isPressed;
    final primaryColor = widget.color;

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
          scale: _isPressed ? 0.95 : _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              gradient: isElevated
                  ? LinearGradient(
                      colors: [
                        Colors.white,
                        primaryColor.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isElevated ? primaryColor : const Color(0xFFE5E7EB),
                width: isElevated ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isElevated
                      ? primaryColor.withOpacity(0.18)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: isElevated ? 12 : 4,
                  offset: isElevated ? const Offset(0, 5) : const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.badge != null)
                  Positioned(
                    top: -4,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isElevated ? 38 : 34,
                        height: isElevated ? 38 : 34,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(isElevated ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryColor.withOpacity(isElevated ? 0.4 : 0.0),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            widget.icon,
                            size: isElevated ? 20 : 18,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isElevated ? primaryColor : AppColors.textDark,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
