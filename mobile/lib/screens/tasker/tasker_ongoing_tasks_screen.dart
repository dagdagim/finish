import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../chat/task_chat_screen.dart';
import 'nearby_tasks_screen.dart';
import 'tasker_active_job_screen.dart';
import 'tasker_task_details_screen.dart';

class TaskerOngoingTasksScreen extends StatefulWidget {
  final VoidCallback? onExploreNearby;

  const TaskerOngoingTasksScreen({super.key, this.onExploreNearby});

  @override
  State<TaskerOngoingTasksScreen> createState() => _TaskerOngoingTasksScreenState();
}

class _TaskerOngoingTasksScreenState extends State<TaskerOngoingTasksScreen> {
  String _selectedTab = 'active'; // 'active', 'assigned', 'in_progress', 'submitted', 'completed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id ?? 'tasker_daniel';
      final userName = auth.currentUser?.fullName ?? 'Daniel Kebede';
      context.read<TaskProvider>().setCurrentUser(userId, userName);
      context.read<TaskProvider>().fetchTasks(roleMode: 'tasker');
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allOngoing = taskProvider.ongoingTasks;
    final assigned = taskProvider.assignedTasks;
    final inProgress = taskProvider.inProgressTasks;
    final submitted = taskProvider.submittedTasks;
    final completed = taskProvider.completedTasks;

    List<TaskModel> displayList;
    switch (_selectedTab) {
      case 'assigned':
        displayList = assigned;
        break;
      case 'in_progress':
        displayList = inProgress;
        break;
      case 'submitted':
        displayList = submitted;
        break;
      case 'completed':
        displayList = completed;
        break;
      case 'active':
      default:
        displayList = allOngoing;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ongoing Tasks',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                if (allOngoing.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Text(
                      '${allOngoing.length} Active',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Manage your hired jobs, live delivery & payouts',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark),
            tooltip: 'Refresh Active Jobs',
            onPressed: () => taskProvider.fetchTasks(roleMode: 'tasker'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal Status Tabs Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTabChip(
                    id: 'active',
                    label: 'All Active',
                    count: allOngoing.length,
                    icon: Icons.flash_on_rounded,
                  ),
                  _buildTabChip(
                    id: 'assigned',
                    label: 'Ready to Start',
                    count: assigned.length,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  _buildTabChip(
                    id: 'in_progress',
                    label: 'In Progress',
                    count: inProgress.length,
                    icon: Icons.directions_bike_rounded,
                  ),
                  _buildTabChip(
                    id: 'submitted',
                    label: 'Under Review',
                    count: submitted.length,
                    icon: Icons.pending_actions_rounded,
                  ),
                  _buildTabChip(
                    id: 'completed',
                    label: 'Completed',
                    count: completed.length,
                    icon: Icons.task_alt_rounded,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // 2. Task List or Empty State
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => taskProvider.fetchTasks(roleMode: 'tasker'),
              child: displayList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final task = displayList[index];
                        return _buildOngoingTaskCard(task);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String id,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selectedTab = id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingTaskCard(TaskModel task) {
    final status = task.status.toUpperCase();
    final isAssigned = status == 'ACCEPTED' || status == 'ASSIGNED';
    final isInProgress = status == 'IN_PROGRESS';
    final isSubmitted = status == 'SUBMITTED' || status == 'PAYMENT_PENDING';
    final isCompleted = status == 'COMPLETED' || status == 'PAID';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isAssigned) {
      statusColor = const Color(0xFF2563EB);
      statusText = '🎉 Hired · Ready to Start';
      statusIcon = Icons.stars_rounded;
    } else if (isInProgress) {
      statusColor = const Color(0xFF087F5B);
      statusText = '🚀 Work In Progress';
      statusIcon = Icons.directions_bike_rounded;
    } else if (isSubmitted) {
      statusColor = const Color(0xFFD97706);
      statusText = '📸 Proof Under Customer Review';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isCompleted) {
      statusColor = const Color(0xFF059669);
      statusText = '✅ Completed & Paid';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppColors.primary;
      statusText = status;
      statusIcon = Icons.info_outline_rounded;
    }

    final pickupText = task.pickupLocation.address.isNotEmpty
        ? task.pickupLocation.address
        : 'Addis Ababa';
    final dropoffText = task.dropoffLocation != null && task.dropoffLocation!.address.isNotEmpty
        ? task.dropoffLocation!.address
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isInProgress ? const Color(0xFF087F5B).withOpacity(0.3) : const Color(0xFFE5E7EB),
          width: isInProgress ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isAssigned || isInProgress) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TaskerActiveJobScreen(task: task)),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TaskerTaskDetailsScreen(task: task)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status Banner + Budget Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                statusText,
                                style: AppTypography.labelMedium.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF087F5B)),
                          const SizedBox(width: 4),
                          Text(
                            '${task.pricing.budget} ETB',
                            style: AppTypography.titleSmall.copyWith(
                              color: const Color(0xFF087F5B),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Task Title
                Text(
                  task.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Customer Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        task.customerName.isNotEmpty ? task.customerName[0] : 'C',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Customer: ${task.customerName}',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 13, color: AppColors.primary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        task.scheduleText,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location Route (Origin -> Destination)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickupText,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (dropoffText.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 12,
                              child: VerticalDivider(color: Color(0xFFD1D5DB), thickness: 1.5),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dropoffText,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.distanceKm > 0)
                              Text(
                                '${task.distanceKm.toStringAsFixed(1)} km',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons Row
                Row(
                  children: [
                    // Chat Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskChatScreen(
                                task: task,
                                otherUserId: 'customer_sarah',
                                otherUserName: task.customerName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Main Action Button: Start / Navigate / View
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskerActiveJobScreen(task: task),
                            ),
                          );
                        },
                        icon: Icon(
                          isInProgress ? Icons.navigation_rounded : Icons.play_arrow_rounded,
                          size: 17,
                        ),
                        label: Text(
                          isAssigned
                              ? 'Start Working'
                              : (isInProgress ? 'Live Navigation' : 'View Job Status'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInProgress ? const Color(0xFF087F5B) : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Ongoing Tasks in This Tab',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When a customer approves your application or hires you, the active job will appear here with live tracking & chat.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.onExploreNearby != null) {
                    widget.onExploreNearby!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NearbyTasksScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text(
                  'Browse Nearby Open Tasks',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
