import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/task_card.dart';
import '../../data/models/task_model.dart';
import '../../providers/task_provider.dart';
import 'customer_task_details_screen.dart';
import 'post_task/post_task_wizard_screen.dart';

class CustomerTasksScreen extends StatefulWidget {
  const CustomerTasksScreen({super.key});

  @override
  State<CustomerTasksScreen> createState() => _CustomerTasksScreenState();
}

class _CustomerTasksScreenState extends State<CustomerTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks(roleMode: 'customer');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks, String query) {
    var result = tasks;
    if (_selectedCategory != 'all') {
      result = result.where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q) ||
        (t.assignedTaskerName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return result;
  }

  void _openPostTask() {
    final taskProvider = context.read<TaskProvider>();
    taskProvider.resetWizard();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostTaskWizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allTasks = taskProvider.tasks;
    final activeTasks = taskProvider.activeTasks;
    final completedTasks = allTasks.where((t) => t.status == 'PAID' || t.status == 'COMPLETED').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF087F5B), Color(0xFF065F44)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'My Tasks',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${allTasks.length} total tasks managed',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Tasks',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: AppColors.textDark, size: 20),
            ),
            onPressed: () => context.read<TaskProvider>().fetchTasks(roleMode: 'customer'),
          ),
          IconButton(
            tooltip: 'Post New Task',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            ),
            onPressed: _openPostTask,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Bar & Search
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search my tasks or taskers...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () => setState(() => _searchController.clear()),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Segmented Modern Tab Bar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                      tabs: [
                        Tab(text: 'Active (${activeTasks.length})'),
                        Tab(text: 'Done (${completedTasks.length})'),
                        Tab(text: 'All (${allTasks.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Category Filter Pills
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildCategoryFilter('All', 'all'),
                    const SizedBox(width: 6),
                    _buildCategoryFilter('Delivery', 'delivery'),
                    const SizedBox(width: 6),
                    _buildCategoryFilter('Cleaning', 'cleaning'),
                    const SizedBox(width: 6),
                    _buildCategoryFilter('Assembly', 'assembly'),
                    const SizedBox(width: 6),
                    _buildCategoryFilter('Moving', 'moving'),
                    const SizedBox(width: 6),
                    _buildCategoryFilter('Shopping', 'shopping'),
                  ],
                ),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(
                    _filterTasks(activeTasks, _searchController.text),
                    'No active tasks',
                    'Post a new errand, repair, or delivery to get help right away.',
                    Icons.inventory_2_outlined,
                  ),
                  _buildTaskList(
                    _filterTasks(completedTasks, _searchController.text),
                    'No completed tasks yet',
                    'Tasks you mark complete and pay for will appear here.',
                    Icons.verified_outlined,
                  ),
                  _buildTaskList(
                    _filterTasks(allTasks, _searchController.text),
                    'No tasks found',
                    'Try changing your search keywords or filter category.',
                    Icons.assignment_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(String label, String value) {
    final isSelected = _selectedCategory == value;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
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

  Widget _buildTaskList(
    List<TaskModel> tasks,
    String emptyTitle,
    String emptySubtitle,
    IconData emptyIcon,
  ) {
    if (tasks.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await context.read<TaskProvider>().fetchTasks(roleMode: 'customer');
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(emptyIcon, size: 30, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyTitle,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Post a Task',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: _openPostTask,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await context.read<TaskProvider>().fetchTasks(roleMode: 'customer');
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            title: task.title,
            category: task.category,
            price: '${task.pricing.budget} ETB',
            locationText: task.routeDisplay,
            distance: '${task.distanceKm} km',
            timeText: task.scheduleText,
            status: task.status,
            customerRating: task.assignedTaskerName != null ? 'Tasker: ${task.assignedTaskerName}' : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerTaskDetailsScreen(task: task),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
