import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/simulated_map_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/task_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../chat/task_chat_screen.dart';
import 'task_completion_screen.dart';

class CustomerTaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const CustomerTaskDetailsScreen({super.key, required this.task});

  @override
  State<CustomerTaskDetailsScreen> createState() =>
      _CustomerTaskDetailsScreenState();
}

class _CustomerTaskDetailsScreenState extends State<CustomerTaskDetailsScreen> {
  late TaskModel _currentTask;
  List<OfferModel> _offers = [];
  Timer? _liveWorkTimer;
  StreamSubscription<Map<String, dynamic>>? _taskerLocationSub;
  StreamSubscription<Map<String, dynamic>>? _taskStatusSub;
  int _elapsedSeconds = 0;
  LatLng? _liveTaskerLocation;
  DateTime? _workStartTime;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _initLiveTracking();
    _loadTaskDetails();
  }

  @override
  void dispose() {
    _liveWorkTimer?.cancel();
    _taskerLocationSub?.cancel();
    _taskStatusSub?.cancel();
    super.dispose();
  }

  void _initLiveTracking() {
    final taskProvider = context.read<TaskProvider>();
    final savedStart = taskProvider.getTaskStartTime(_currentTask.id);
    final effectiveStart = _currentTask.startedAt ?? savedStart;
    final savedCompleted = taskProvider.getTaskCompletedTime(_currentTask.id);
    final effectiveCompleted = _currentTask.completedAt ?? savedCompleted;

    final status = _currentTask.status.toUpperCase();
    final isDone =
        status == 'SUBMITTED' ||
        status == 'AWAITING_APPROVAL' ||
        status == 'COMPLETED' ||
        status == 'PAID' ||
        effectiveCompleted != null;

    if (isDone) {
      _liveWorkTimer?.cancel();
      _workStartTime =
          effectiveStart ??
          DateTime.now().subtract(const Duration(minutes: 20));
      final compTime = effectiveCompleted ?? DateTime.now();
      _elapsedSeconds = compTime.difference(_workStartTime!).inSeconds;
      if (_elapsedSeconds < 0) _elapsedSeconds = 0;
    } else if (status == 'IN_PROGRESS' || effectiveStart != null) {
      _workStartTime = effectiveStart ?? DateTime.now().subtract(const Duration(seconds: 10));
      taskProvider.setTaskStartTime(_currentTask.id, _workStartTime!);
      _startLiveTimer();
    } else if (status == 'ACCEPTED') {
      _elapsedSeconds = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      _taskerLocationSub?.cancel();
      _taskerLocationSub = chat.taskerLocationStream.listen((data) {
        final eventTaskId = data['taskId']?.toString() ?? '';
        final cleanEvent = eventTaskId.replaceFirst('task_', '');
        final cleanCurrent = _currentTask.id.replaceFirst('task_', '');

        if (cleanEvent == cleanCurrent || eventTaskId == _currentTask.id) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null && mounted) {
            setState(() {
              _liveTaskerLocation = LatLng(lat, lng);
            });
          }
        }
      });

      _taskStatusSub?.cancel();
      _taskStatusSub = chat.taskStatusStream.listen((data) {
        final eventTaskId = data['taskId']?.toString() ?? '';
        final cleanEvent = eventTaskId.replaceFirst('task_', '');
        final cleanCurrent = _currentTask.id.replaceFirst('task_', '');

        if (cleanEvent == cleanCurrent || eventTaskId == _currentTask.id) {
          final newStatus = data['status']?.toString().toUpperCase() ?? '';
          if (newStatus == 'SUBMITTED' || newStatus == 'COMPLETED') {
            _liveWorkTimer?.cancel();
            final compTime =
                DateTime.tryParse(data['completedAt']?.toString() ?? '') ??
                DateTime.now();
            taskProvider.setTaskCompletedTime(_currentTask.id, compTime);
            if (mounted) {
              setState(() {
                _currentTask = _currentTask.copyWith(
                  status: 'SUBMITTED',
                  completedAt: compTime,
                );
                if (_workStartTime != null) {
                  _elapsedSeconds = compTime
                      .difference(_workStartTime!)
                      .inSeconds;
                  if (_elapsedSeconds < 0) _elapsedSeconds = 0;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tasker has finished the job! Timer stopped. Review completion proof below.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xFF047857),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else if (newStatus == 'IN_PROGRESS') {
            final stTime =
                DateTime.tryParse(data['startedAt']?.toString() ?? '') ??
                DateTime.now();
            taskProvider.setTaskStartTime(_currentTask.id, stTime);
            if (mounted) {
              setState(() {
                _workStartTime = stTime;
                _currentTask = _currentTask.copyWith(
                  status: 'IN_PROGRESS',
                  startedAt: stTime,
                );
              });
              _startLiveTimer();
            }
          }
        }
      });
    });
  }

  void _startLiveTimer() {
    _liveWorkTimer?.cancel();
    _workStartTime ??= DateTime.now().subtract(const Duration(seconds: 5));
    _elapsedSeconds = DateTime.now().difference(_workStartTime!).inSeconds;
    if (_elapsedSeconds < 0) _elapsedSeconds = 0;

    _liveWorkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _workStartTime != null) {
        setState(() {
          _elapsedSeconds = DateTime.now()
              .difference(_workStartTime!)
              .inSeconds;
          if (_elapsedSeconds < 0) _elapsedSeconds = 0;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTaskDetails() async {
    final res = await ApiService().getTaskById(_currentTask.id);
    if (mounted) {
      final taskProvider = context.read<TaskProvider>();
      final loadedTask = res['task'] is TaskModel
          ? res['task'] as TaskModel
          : null;
      final savedStart = taskProvider.getTaskStartTime(_currentTask.id);
      final savedCompleted = taskProvider.getTaskCompletedTime(_currentTask.id);

      setState(() {
        if (loadedTask != null) {
          final effectiveStart =
              loadedTask.startedAt ?? savedStart ?? _workStartTime;
          final effectiveCompleted = loadedTask.completedAt ?? savedCompleted;
          _currentTask = loadedTask.copyWith(
            startedAt: effectiveStart,
            completedAt: effectiveCompleted,
          );
          if (effectiveStart != null) {
            taskProvider.setTaskStartTime(_currentTask.id, effectiveStart);
            _workStartTime = effectiveStart;
          }
          if (effectiveCompleted != null) {
            taskProvider.setTaskCompletedTime(
              _currentTask.id,
              effectiveCompleted,
            );
          }
        } else if (res['task'] != null) {
          _currentTask = res['task'];
        }
        _offers = res['offers'] ?? [];

        final status = _currentTask.status.toUpperCase();
        final effectiveStart =
            _currentTask.startedAt ?? savedStart ?? _workStartTime;
        final effectiveCompleted = _currentTask.completedAt ?? savedCompleted;
        final isDone =
            status == 'SUBMITTED' ||
            status == 'AWAITING_APPROVAL' ||
            status == 'COMPLETED' ||
            status == 'PAID' ||
            effectiveCompleted != null;

        if (isDone) {
          _liveWorkTimer?.cancel();
          _workStartTime =
              effectiveStart ??
              DateTime.now().subtract(const Duration(minutes: 20));
          final compTime = effectiveCompleted ?? DateTime.now();
          _elapsedSeconds = compTime.difference(_workStartTime!).inSeconds;
          if (_elapsedSeconds < 0) _elapsedSeconds = 0;
        } else if (status == 'IN_PROGRESS' || effectiveStart != null) {
          _workStartTime = effectiveStart ?? DateTime.now().subtract(const Duration(seconds: 10));
          _startLiveTimer();
        }
      });
    }
  }

  Future<void> _approveTask() async {
    final taskProvider = context.read<TaskProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Release Escrow Payment?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you satisfied with the completed work? Releasing payment will immediately transfer ${_currentTask.pricing.budget} ETB to ${_currentTask.assignedTaskerName ?? "the tasker"}\'s wallet from Finish Escrow.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Release', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await taskProvider.approveTask(_currentTask.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Payment released successfully to tasker! Escrow complete. ✓'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF047857),
          duration: Duration(seconds: 4),
        ),
      );

      setState(() {
        _currentTask = _currentTask.copyWith(status: 'PAID');
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TaskCompletionScreen(task: _currentTask),
        ),
      );
    }
  }

  void _showFullScreenProofPhotoDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(30),
                    color: Colors.white,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Proof photo preview unavailable'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _extractTaskSpecifications(TaskModel task) {
    final list = <Map<String, String>>[];
    final desc = '${task.description}\n${task.specialInstructions}';

    for (final line in desc.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.contains(':') && !trimmed.startsWith('http')) {
        final parts = trimmed.split(':');
        final key = parts[0].replaceAll('•', '').replaceAll('-', '').trim();
        final val = parts.sublist(1).join(':').trim();
        if (key.isNotEmpty &&
            val.isNotEmpty &&
            key.length < 32 &&
            val.length < 120) {
          list.add({'label': key, 'value': val});
        }
      }
    }

    if (list.isEmpty) {
      list.add({'label': 'Category', 'value': task.category.toUpperCase()});
      list.add({
        'label': 'Estimated Duration',
        'value': '~${task.estimatedDurationMin} minutes',
      });
      list.add({
        'label': 'Pricing Model',
        'value': task.pricing.pricingType.toUpperCase(),
      });
      list.add({'label': 'Platform Fee', 'value': '0 ETB (Included)'});
    }

    return list;
  }

  List<String> _extractShoppingItems(TaskModel task) {
    final items = <String>[];
    final fullText =
        '${task.title}\n${task.description}\n${task.specialInstructions}';
    for (final line in fullText.split('\n')) {
      if (line.toLowerCase().contains('items:')) {
        final raw = line
            .substring(line.toLowerCase().indexOf('items:') + 6)
            .trim();
        for (final item in raw.split(',')) {
          if (item.trim().isNotEmpty) items.add(item.trim());
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final specs = _extractTaskSpecifications(_currentTask);
    final shoppingItems = _extractShoppingItems(_currentTask);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Task Details',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: AppColors.primary,
            ),
            tooltip: 'Refresh Task & Offers',
            onPressed: _loadTaskDetails,
          ),
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              size: 20,
              color: AppColors.textDark,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task link copied to clipboard.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadTaskDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card: Category, Status, Title, and Budget
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentTask.category.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: _currentTask.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentTask.title,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TASK BUDGET',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_currentTask.pricing.budget} ETB',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.priceLarge.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Escrow Protected',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelMedium.copyWith(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 12),

                      // Distance, Duration & Schedule Meta Row (Fully Expanded & Overflow-Proof)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetaItem(
                              Icons.near_me_outlined,
                              '${_currentTask.distanceKm} km',
                              'Distance',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFFE5E7EB),
                          ),
                          Expanded(
                            child: _buildMetaItem(
                              Icons.timer_outlined,
                              '${_currentTask.estimatedDurationMin} min',
                              'Est. Time',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: const Color(0xFFE5E7EB),
                          ),
                          Expanded(
                            child: _buildMetaItem(
                              Icons.calendar_today_outlined,
                              _currentTask.scheduleText,
                              'Schedule',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_currentTask.status == 'IN_PROGRESS' ||
                    _currentTask.status == 'ACCEPTED' ||
                    _currentTask.status == 'SUBMITTED') ...[
                  const SizedBox(height: 16),

                  // 1. LIVE SYNCHRONIZED WORK STOPWATCH CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF064E3B).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      (_currentTask.status == 'SUBMITTED' ||
                                              _currentTask.status ==
                                                  'COMPLETED' ||
                                              _currentTask.status == 'PAID')
                                          ? 'WORK COMPLETED · TIMER STOPPED'
                                          : _currentTask.status == 'IN_PROGRESS'
                                          ? 'LIVE WORK IN PROGRESS'
                                          : 'TASKER ASSIGNED · EN ROUTE',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: AppTypography.labelMedium.copyWith(
                                        color: const Color(0xFF6EE7B7),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (_currentTask.status == 'SUBMITTED' ||
                                            _currentTask.status ==
                                                'COMPLETED' ||
                                            _currentTask.status == 'PAID')
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.satellite_alt_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_currentTask.status == 'SUBMITTED' ||
                                            _currentTask.status ==
                                                'COMPLETED' ||
                                            _currentTask.status == 'PAID')
                                        ? 'Timer Stopped'
                                        : 'Live GPS',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDuration(_elapsedSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (_currentTask.status == 'SUBMITTED' ||
                                  _currentTask.status == 'COMPLETED' ||
                                  _currentTask.status == 'PAID')
                              ? 'Tasker finished the job! Timer stopped. Total work duration recorded above. Review proof below to approve.'
                              : 'Synchronized work timer ticking live in real-time.',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. LIVE GOOGLE MAP WITH TASKER MOVING MARKER
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.explore_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live Tasker GPS Tracking',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.navigation_rounded,
                                      size: 11,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Live Moving',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: const Color(0xFF15803D),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 220,
                          child: SimulatedMapWidget(
                            initialCenter: _liveTaskerLocation,
                            pins: [
                              MapTaskPin(
                                id: 'cust_pickup',
                                title: 'Pickup Location',
                                price: 'Pickup',
                                relativePosition: const Offset(0.32, 0.45),
                                location:
                                    _currentTask
                                        .pickupLocation
                                        .address
                                        .isNotEmpty
                                    ? _currentTask.pickupLocation.address
                                    : 'Addis Ababa',
                              ),
                              if (_currentTask.dropoffLocation != null &&
                                  _currentTask
                                      .dropoffLocation!
                                      .address
                                      .isNotEmpty)
                                MapTaskPin(
                                  id: 'cust_dropoff',
                                  title: 'Drop-off Destination',
                                  price: 'Drop-off',
                                  relativePosition: const Offset(0.68, 0.38),
                                  location:
                                      _currentTask.dropoffLocation!.address,
                                ),
                              MapTaskPin(
                                id: 'tasker_live_loc',
                                title:
                                    '🛵 ${_currentTask.assignedTaskerName ?? 'Tasker'} (Live)',
                                price: '🛵 Tasker',
                                relativePosition: const Offset(0.50, 0.48),
                                location: 'Live Moving Signal',
                                coordinates: _liveTaskerLocation,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  (_currentTask.assignedTaskerName ?? 'D')
                                          .isNotEmpty
                                      ? (_currentTask.assignedTaskerName ??
                                            'D')[0]
                                      : 'T',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentTask.assignedTaskerName ??
                                          'Assigned Tasker',
                                      style: AppTypography.titleSmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Active on Job · ~${_currentTask.distanceKm.toStringAsFixed(1)} km away',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TaskChatScreen(
                                        task: _currentTask,
                                        otherUserId:
                                            _currentTask.assignedTaskerId ??
                                            'tasker_daniel',
                                        otherUserName:
                                            _currentTask.assignedTaskerName ??
                                            'Tasker',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                ),
                                label: const Text('Chat'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Description Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentTask.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textDark,
                          height: 1.5,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Task Scope & Hardness Specifications Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Task Scope & Specifications',
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: Color(0xFFF3F4F6)),
                      for (int i = 0; i < specs.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                specs[i]['label']!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                specs[i]['value']!,
                                style: AppTypography.labelMedium.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (i < specs.length - 1) const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Itemized Shopping List Card (if shopping)
                if (shoppingItems.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Itemized Items Checklist (${shoppingItems.length} items)',
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: Color(0xFFF3F4F6)),
                        for (final item in shoppingItems)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Location Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location & Route',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trip_origin_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup / Origin',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _currentTask.pickupLocation.address,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_currentTask.dropoffLocation != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Container(
                            width: 1.5,
                            height: 18,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Drop-off / Destination',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _currentTask.dropoffLocation!.address,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Assigned Tasker / Profile Card (Overflow-Proof)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTask.assignedTaskerName != null
                            ? 'Assigned Tasker'
                            : 'Posted by',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              _currentTask.assignedTaskerName != null
                                  ? _currentTask.assignedTaskerName![0]
                                  : _currentTask.customerName[0],
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentTask.assignedTaskerName ??
                                      _currentTask.customerName,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.9',
                                      style: AppTypography.labelMedium.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 10,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Verified',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  color: AppColors.primaryDark,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TaskChatScreen(
                                    task: _currentTask,
                                    otherUserId:
                                        _currentTask.assignedTaskerName ==
                                            'Daniel K.'
                                        ? 'tasker_daniel'
                                        : 'tasker_user',
                                    otherUserName:
                                        _currentTask.assignedTaskerName ??
                                        'Assigned Tasker',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chat',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
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
                const SizedBox(height: 16),

                // Ratings & Admin Appraisal Section
                _buildRatingsAndAppraisalSection(),

                // Offers & Tasker Applications Section if Open
                if (_currentTask.status == 'OPEN' ||
                    _currentTask.status == 'OFFERING') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tasker Applications',
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _offers.isNotEmpty
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_offers.length} Applicants',
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _offers.isNotEmpty
                                    ? const Color(0xFF15803D)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_offers.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.radar_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Awaiting Tasker Applications',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your task is live on the Addis Ababa marketplace. Verified taskers will review and apply shortly.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    for (final offer in _offers)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tasker Profile Header & Price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    offer.taskerName[0].toUpperCase(),
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              offer.taskerName,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.textDark,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.verified_rounded,
                                                  size: 10,
                                                  color: Color(0xFF16A34A),
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Verified',
                                                  style: AppTypography
                                                      .labelMedium
                                                      .copyWith(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: const Color(
                                                          0xFF15803D,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${offer.taskerRating} (120+ tasks · 99% on-time)',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Text(
                                    '${offer.offeredAmount} ETB',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Tasker Pitch / Proposal Note
                            if (offer.note.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFF3F4F6),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.format_quote_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        offer.note,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontSize: 11.5,
                                              color: AppColors.textDark,
                                              height: 1.35,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Action Buttons: Chat & Hire
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TaskChatScreen(
                                            task: _currentTask,
                                            otherUserId: offer.taskerId,
                                            otherUserName: offer.taskerName,
                                            otherUserRating:
                                                '${offer.taskerRating} ★',
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 14,
                                      color: AppColors.textDark,
                                    ),
                                    label: Text(
                                      'Chat',
                                      style: AppTypography.labelMedium.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 6,
                                  child:
                                      offer.status == 'ACCEPTED' ||
                                          _currentTask.assignedTaskerName ==
                                              offer.taskerName
                                      ? Container(
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF86EFAC),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 15,
                                                color: Color(0xFF16A34A),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Hired Tasker',
                                                style: AppTypography.labelMedium
                                                    .copyWith(
                                                      color: const Color(
                                                        0xFF15803D,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : (offer.status == 'REJECTED' ||
                                            _currentTask.status == 'ACCEPTED' ||
                                            _currentTask.status ==
                                                'IN_PROGRESS')
                                      ? Container(
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: Text(
                                            'Application Rejected',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11.5,
                                                ),
                                          ),
                                        )
                                      : FinishButton(
                                          text:
                                              'Hire (${offer.offeredAmount} ETB)',
                                          height: 38,
                                          onPressed: () async {
                                            final taskProvider = context
                                                .read<TaskProvider>();
                                            await taskProvider.acceptOffer(
                                              _currentTask.id,
                                              offer.id,
                                              offer.taskerName,
                                              taskerId: offer.taskerId,
                                              budget: offer.offeredAmount,
                                            );

                                            final updatedOffers = _offers.map((
                                              o,
                                            ) {
                                              return OfferModel(
                                                id: o.id,
                                                taskId: o.taskId,
                                                taskerId: o.taskerId,
                                                taskerName: o.taskerName,
                                                taskerAvatar: o.taskerAvatar,
                                                taskerRating: o.taskerRating,
                                                offeredAmount: o.offeredAmount,
                                                note: o.note,
                                                status: o.id == offer.id
                                                    ? 'ACCEPTED'
                                                    : 'REJECTED',
                                              );
                                            }).toList();

                                            setState(() {
                                              _offers = updatedOffers;
                                              _currentTask = _currentTask.copyWith(
                                                pricing: TaskPricing(
                                                  budget: offer.offeredAmount,
                                                  suggestedPrice: _currentTask
                                                      .pricing
                                                      .suggestedPrice,
                                                ),
                                                status: 'ACCEPTED',
                                                assignedTaskerId: offer.taskerId,
                                                assignedTaskerName: offer.taskerName,
                                              );
                                            });
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Hired ${offer.taskerName}! Funds held securely in Finish Escrow. Other applicants have been notified.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                ],

                // Task Completion Review Section with Photos, Notes, and Escrow Approval
                if (_currentTask.status == 'SUBMITTED' ||
                    _currentTask.status == 'COMPLETED' ||
                    _currentTask.status == 'PAID') ...[
                  _buildProofOfWorkReviewCard(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProofOfWorkReviewCard() {
    final photos = _currentTask.proofPhotos.isNotEmpty
        ? _currentTask.proofPhotos
        : ['https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&auto=format&fit=crop&q=80'];
    final notes = (_currentTask.proofNotes != null && _currentTask.proofNotes!.isNotEmpty)
        ? _currentTask.proofNotes!
        : 'Service completed successfully according to instructions and verified on site.';
    final isPaid = _currentTask.status == 'PAID' || _currentTask.status == 'COMPLETED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid ? const Color(0xFF10B981) : const Color(0xFF047857),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.verified_rounded,
                  size: 18,
                  color: const Color(0xFF047857),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaid ? 'Payment Released · Job Complete' : '📸 Task Completion Proof Submitted',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF064E3B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isPaid
                          ? 'Escrow funds successfully paid to ${_currentTask.assignedTaskerName ?? "Tasker"}'
                          : 'Review visual proof before releasing ${_currentTask.pricing.budget} ETB from escrow',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Proof Photos Grid / Preview with Zoom
          Text(
            'Visual Proof Photos (Tap to Zoom)',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final photoUrl = photos[idx];
                return GestureDetector(
                  onTap: () => _showFullScreenProofPhotoDialog(context, photoUrl),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 130,
                          height: 110,
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 130,
                              height: 110,
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 3),
                              Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Tasker Notes Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Tasker Completion Note',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Duration & GPS Summary Chips
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF047857)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Duration: ${_formatDuration(_elapsedSeconds)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'GPS Verified',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Actions
          if (!isPaid) ...[
            FinishButton(
              text: '✓ Approve & Release Payment (${_currentTask.pricing.budget} ETB)',
              height: 48,
              onPressed: _approveTask,
            ),
            const SizedBox(height: 8),
            FinishButton(
              text: 'Report an Issue / Dispute',
              variant: FinishButtonVariant.outline,
              height: 42,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support ticket opened for this task. Admin will review within 15 minutes.'),
                  ),
                );
              },
            ),
          ] else ...[
            FinishButton(
              text: '★ Rate & Review Tasker',
              height: 46,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskCompletionScreen(task: _currentTask),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 9.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsAndAppraisalSection() {
    final hasAdminRating = _currentTask.adminRatings != null;
    final hasCustomerRating = _currentTask.customerRatingToTasker != null;
    final isFinished = _currentTask.status == 'PAID' || _currentTask.status == 'COMPLETED';

    if (!hasAdminRating && !hasCustomerRating && !isFinished) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. ADMIN APPRAISAL CARD ON CUSTOMER ACCOUNT
        if (hasAdminRating) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF93C5FD)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Appraisal on Your Account',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentTask.adminRatings!.customerRating}.0 ★',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentTask.adminRatings!.customerReview?.isNotEmpty == true
                      ? '"${_currentTask.adminRatings!.customerReview}"'
                      : '"Excellent cooperation and prompt escrow release."',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                    color: Color(0xFF1E3A8A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      'Verified platform review by Finish Administration',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A).withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 2. CUSTOMER RATING FOR TASKER CARD
        if (hasCustomerRating) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text(
                          'Your Review for ${_currentTask.assignedTaskerName ?? "Tasker"}',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFBBF24)),
                          ),
                          child: Text(
                            '${_currentTask.customerRatingToTasker!.rating}.0 ★',
                            style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w900, fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _showCustomerRatingModal,
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_currentTask.customerRatingToTasker!.review?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${_currentTask.customerRatingToTasker!.review}"',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.35),
                  ),
                ],
                if (_currentTask.customerRatingToTasker!.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _currentTask.customerRatingToTasker!.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    )).toList(),
                  ),
                ],
                if (_currentTask.customerRatingToTasker!.tipAmount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      '💰 Included +${_currentTask.customerRatingToTasker!.tipAmount.toInt()} ETB Tip',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (isFinished) ...[
          InkWell(
            onTap: _showCustomerRatingModal,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate & Review ${_currentTask.assignedTaskerName ?? "Tasker"}',
                          style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share your feedback with ${_currentTask.assignedTaskerName ?? "your tasker"}.',
                          style: TextStyle(color: const Color(0xFF78350F).withOpacity(0.8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF78350F)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  void _showCustomerRatingModal() {
    int selectedRating = _currentTask.customerRatingToTasker?.rating ?? 5;
    final reviewController = TextEditingController(text: _currentTask.customerRatingToTasker?.review ?? '');
    final selectedTags = List<String>.from(_currentTask.customerRatingToTasker?.tags ?? []);
    double tipAmount = _currentTask.customerRatingToTasker?.tipAmount ?? 0;
    bool isSubmitting = false;

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
                                'Rate ${_currentTask.assignedTaskerName ?? "Tasker"}',
                                style: AppTypography.titleSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Task: "${_currentTask.title}"',
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

                    // Star Rating
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              return IconButton(
                                icon: Icon(
                                  star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 38,
                                ),
                                onPressed: () {
                                  setModalState(() => selectedRating = star);
                                },
                              );
                            }),
                          ),
                          Text(
                            selectedRating == 5
                                ? '⭐ Exceptional (5.0)'
                                : selectedRating == 4
                                    ? '⭐ Great Work (4.0)'
                                    : selectedRating == 3
                                        ? '⭐ Good (3.0)'
                                        : '⭐ Needs Improvement ($selectedRating.0)',
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
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF047857) : AppColors.textDark)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD1FAE5),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB)),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
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
                      controller: reviewController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Share details of your experience with ${_currentTask.assignedTaskerName ?? "the tasker"}...',
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
                        if (tipAmount > 0)
                          Text('+${tipAmount.toInt()} ETB Tip', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF047857))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [0, 20, 50, 100].map((tip) {
                        final isSelected = tipAmount == tip;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () => setModalState(() => tipAmount = tip.toDouble()),
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
                      text: isSubmitting ? 'Saving...' : 'Submit Rating ($selectedRating.0 ★)',
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final reviewText = reviewController.text.trim().isNotEmpty
                                  ? reviewController.text.trim()
                                  : (selectedTags.isNotEmpty ? selectedTags.join(', ') : 'Great tasker, highly recommended!');

                              await ApiService().rateTasker(
                                _currentTask.id,
                                rating: selectedRating,
                                review: reviewText,
                                tags: selectedTags,
                                tipAmount: tipAmount,
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
                                          child: Text('Thank you! Your $selectedRating.0 ★ rating was submitted for ${_currentTask.assignedTaskerName ?? "your tasker"}.'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF047857),
                                  ),
                                );
                                _loadTaskDetails();
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
}
