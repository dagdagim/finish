import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_card.dart';
import '../../core/widgets/task_card.dart';
import '../../core/widgets/simulated_map_widget.dart';
import '../../providers/task_provider.dart';
import 'tasker_task_details_screen.dart';

class NearbyTasksScreen extends StatefulWidget {
  const NearbyTasksScreen({super.key});

  @override
  State<NearbyTasksScreen> createState() => _NearbyTasksScreenState();
}

class _NearbyTasksScreenState extends State<NearbyTasksScreen> {
  bool _isMapMode = true;
  String? _previewTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks(roleMode: 'tasker');
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.openTasks;

    final mapPins = tasks.isNotEmpty
        ? tasks.map((t) {
            return MapTaskPin(
              id: t.id,
              title: t.title,
              price: '${t.pricing.budget} ETB',
              relativePosition: const Offset(0.5, 0.5),
              location: t.pickupLocation.address.isNotEmpty ? t.pickupLocation.address : 'Bole',
              category: t.category,
            );
          }).toList()
        : [
            MapTaskPin(
              id: 't1',
              title: 'Package Pickup',
              price: '500 ETB',
              relativePosition: const Offset(0.35, 0.32),
              location: 'Bole Medhanialem',
            ),
            MapTaskPin(
              id: 't2',
              title: 'Pick up documents',
              price: '450 ETB',
              relativePosition: const Offset(0.68, 0.28),
              location: 'Office, Bole',
            ),
            MapTaskPin(
              id: 't3',
              title: 'Move small table',
              price: '700 ETB',
              relativePosition: const Offset(0.65, 0.48),
              location: 'Sarbet',
            ),
            MapTaskPin(
              id: 't4',
              title: 'Buy fresh groceries',
              price: '350 ETB',
              relativePosition: const Offset(0.28, 0.68),
              location: 'Piassa',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Container(
          width: 170,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isMapMode = false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_isMapMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        'List',
                        style: AppTypography.labelMedium.copyWith(
                          color: !_isMapMode ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isMapMode = true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isMapMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        'Map',
                        style: AppTypography.labelMedium.copyWith(
                          color: _isMapMode ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark, size: 20),
            tooltip: 'Refresh Nearby Tasks',
            onPressed: () => context.read<TaskProvider>().fetchTasks(roleMode: 'tasker'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Main Body View (Map or List)
          if (_isMapMode)
            SimulatedMapWidget(
              pins: mapPins,
              onPinSelected: (pin) {
                setState(() {
                  _previewTaskId = pin.id;
                });
              },
            )
          else
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<TaskProvider>().fetchTasks(roleMode: 'tasker'),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
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
                  );
                },
              ),
            ),

          // Filter Chips Floating Bar at Top
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Category ▾', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Distance ▾', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Price ▾', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Date ▾', false),
                ],
              ),
            ),
          ),

          // Map Target Center Button
          if (_isMapMode)
            Positioned(
              right: 18,
              bottom: _previewTaskId != null ? 180 : 30,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                elevation: 3,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Centered on current location (Bole)')),
                  );
                },
                child: const Icon(Icons.my_location, color: AppColors.textDark, size: 20),
              ),
            ),

          // Map Mode Task Bottom Preview Sheet (when a marker is tapped)
          if (_isMapMode && _previewTaskId != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Builder(
                builder: (context) {
                  final task = tasks.firstWhere(
                    (t) => t.id == _previewTaskId,
                    orElse: () => tasks.first,
                  );

                  return FinishCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              task.category.toUpperCase(),
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${task.pricing.budget} ETB',
                              style: AppTypography.priceMedium.copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.title,
                          style: AppTypography.titleSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.routeDisplay,
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${task.distanceKm} km · ${task.estimatedDurationMin} min',
                                style: AppTypography.labelMedium,
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TaskerTaskDetailsScreen(task: task),
                                  ),
                                );
                              },
                              child: const Text('View Task', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.textDark : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
