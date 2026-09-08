import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/finish_card.dart';
import '../../core/widgets/simulated_map_widget.dart';
import '../../data/models/task_model.dart';
import '../../data/services/location_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../chat/task_chat_screen.dart';

class TaskerActiveJobScreen extends StatefulWidget {
  final TaskModel task;

  const TaskerActiveJobScreen({super.key, required this.task});

  @override
  State<TaskerActiveJobScreen> createState() => _TaskerActiveJobScreenState();
}

class _TaskerActiveJobScreenState extends State<TaskerActiveJobScreen> {
  bool _isStarted = false;
  bool _isSubmitted = false;
  DateTime? _startTime;
  int _elapsedSeconds = 0;
  Timer? _workTimer;
  Timer? _locationBroadcastTimer;
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentTaskerLocation;

  @override
  void initState() {
    super.initState();
    final taskProvider = context.read<TaskProvider>();
    final savedStart = taskProvider.getTaskStartTime(widget.task.id);
    final effectiveStart = widget.task.startedAt ?? savedStart;
    final savedCompleted = taskProvider.getTaskCompletedTime(widget.task.id);
    final effectiveCompleted = widget.task.completedAt ?? savedCompleted;

    final status = widget.task.status.toUpperCase();
    if (status == 'SUBMITTED' || status == 'PAYMENT_PENDING' || status == 'COMPLETED' || status == 'PAID' || effectiveCompleted != null) {
      _isStarted = true;
      _isSubmitted = true;
      _workTimer?.cancel();
      _locationBroadcastTimer?.cancel();
      _locationSubscription?.cancel();
      _startTime = effectiveStart ?? DateTime.now().subtract(const Duration(minutes: 20));
      final compTime = effectiveCompleted ?? DateTime.now();
      _elapsedSeconds = compTime.difference(_startTime!).inSeconds;
    } else if (status == 'IN_PROGRESS' || effectiveStart != null) {
      _isStarted = true;
      _startTime = effectiveStart ?? DateTime.now();
      if (effectiveStart == null) {
        taskProvider.setTaskStartTime(widget.task.id, _startTime!);
      }
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _startTimer();
      _startLocationStreaming();
    }
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _locationBroadcastTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _startTime != null) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
        });
      }
    });
  }

  void _startLocationStreaming() async {
    _locationSubscription?.cancel();
    _locationBroadcastTimer?.cancel();

    // 1. Initial Device GPS lookup & broadcast
    final initialLoc = await LocationService().getCurrentDeviceLocation();
    if (initialLoc != null && mounted) {
      setState(() {
        _currentTaskerLocation = initialLoc;
      });
      context.read<ChatProvider>().emitTaskerLocation(
        widget.task.id,
        initialLoc.latitude,
        initialLoc.longitude,
      );
    }

    // 2. Real-time GPS stream listener
    _locationSubscription = LocationService().realTimeLocationStream.listen((loc) {
      if (mounted) {
        setState(() {
          _currentTaskerLocation = loc;
        });
        context.read<ChatProvider>().emitTaskerLocation(
          widget.task.id,
          loc.latitude,
          loc.longitude,
        );
      }
    });

    // 3. Periodic broadcast pulse every 3 seconds to keep customer map animated
    _locationBroadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final loc = await LocationService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          _currentTaskerLocation = loc;
        });
        context.read<ChatProvider>().emitTaskerLocation(
          widget.task.id,
          loc.latitude,
          loc.longitude,
        );
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTask() async {
    final taskProvider = context.read<TaskProvider>();
    final now = DateTime.now();
    taskProvider.setTaskStartTime(widget.task.id, now);
    setState(() {
      _isStarted = true;
      _startTime = now;
      _elapsedSeconds = 0;
    });

    _startTimer();
    _startLocationStreaming();
    await taskProvider.startTask(widget.task.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.timer_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text('Work Timer Started! Customer can now track your live location & progress.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF087F5B),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showProofUploadModal() {
    final notesController = TextEditingController(text: 'Completed service successfully according to instructions.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Submit Proof of Work', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                'Upload completion photo and note for the customer to review and release payment (${_formatDuration(_elapsedSeconds)} total time).',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 18),

              // Photos upload preview
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=200&auto=format&fit=crop&q=80',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Completion notes',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'GPS Verified: Kazanchis, Addis Ababa',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              FinishButton(
                text: 'Submit Completion & Stop Timer',
                onPressed: () async {
                  Navigator.of(context).pop();
                  final now = DateTime.now();
                  _workTimer?.cancel();
                  _locationBroadcastTimer?.cancel();
                  _locationSubscription?.cancel();

                  final taskProvider = context.read<TaskProvider>();
                  taskProvider.setTaskCompletedTime(widget.task.id, now);
                  setState(() {
                    _isSubmitted = true;
                    if (_startTime != null) {
                      _elapsedSeconds = now.difference(_startTime!).inSeconds;
                    }
                  });

                  await taskProvider.submitProof(
                    widget.task.id,
                    ['https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=500&auto=format&fit=crop&q=80'],
                    notesController.text,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Job Completed! Timer stopped and proof submitted for customer approval.'),
                            ),
                          ],
                        ),
                        backgroundColor: Color(0xFF047857),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.task.pickupLocation.address.isNotEmpty
        ? widget.task.pickupLocation.address
        : 'Bole Medhanialem';
    final dropoff = widget.task.dropoffLocation != null && widget.task.dropoffLocation!.address.isNotEmpty
        ? widget.task.dropoffLocation!.address
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isStarted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isSubmitted
                      ? 'Under Customer Review'
                      : _isStarted
                          ? 'Live Session: ${_formatDuration(_elapsedSeconds)}'
                          : 'Assigned · Ready to Start',
                  style: AppTypography.labelMedium.copyWith(
                    color: _isStarted ? const Color(0xFF047857) : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: AppColors.primary),
            tooltip: 'Chat with Customer',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskChatScreen(
                    task: widget.task,
                    otherUserId: widget.task.customerId.isNotEmpty ? widget.task.customerId : 'customer_sarah',
                    otherUserName: widget.task.customerName,
                    otherUserRating: '${widget.task.customerRating} ★',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark),
            tooltip: 'Refresh Active Job',
            onPressed: () {
              context.read<TaskProvider>().fetchTasks(roleMode: 'tasker');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Google Maps Navigation Route with Live Moving Marker
            SizedBox(
              height: 240,
              child: SimulatedMapWidget(
                pins: [
                  MapTaskPin(
                    id: 'nav_pickup',
                    title: 'Pickup Location',
                    price: 'Pickup',
                    relativePosition: const Offset(0.35, 0.45),
                    location: pickup,
                  ),
                  if (dropoff.isNotEmpty)
                    MapTaskPin(
                      id: 'nav_dropoff',
                      title: 'Drop-off Destination',
                      price: 'Drop-off',
                      relativePosition: const Offset(0.68, 0.40),
                      location: dropoff,
                    ),
                  if (_currentTaskerLocation != null)
                    MapTaskPin(
                      id: 'tasker_live',
                      title: 'My Live GPS Position',
                      price: '🛵 You',
                      relativePosition: const Offset(0.50, 0.50),
                      location: 'Active Tasker Location',
                    ),
                ],
              ),
            ),

            // 2. Active Guidance & Live Work Stopwatch
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => context.read<TaskProvider>().fetchTasks(roleMode: 'tasker'),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIVE WORK STOPWATCH HERO CARD
                      if (_isStarted)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                            _isSubmitted ? 'WORK SESSION COMPLETED' : 'LIVE WORK STOPWATCH',
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isSubmitted ? Icons.check_circle_outline_rounded : Icons.satellite_alt_rounded,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isSubmitted ? 'Timer Stopped' : 'GPS Active',
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
                                  const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
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
                                _isSubmitted
                                    ? 'Total duration recorded for customer review.'
                                    : 'Customer is viewing your live location & elapsed timer.',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      // Task Status & Budget Card
                      FinishCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _isSubmitted
                                        ? 'Awaiting Customer Approval'
                                        : _isStarted
                                            ? 'Delivery In Progress'
                                            : 'Ready to Start',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.task.pricing.budget} ETB',
                                  style: AppTypography.priceMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.task.routeDisplay,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _isSubmitted ? 1.0 : (_isStarted ? 0.70 : 0.25),
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'ETA: ~18 mins (${widget.task.distanceKm.toStringAsFixed(1)} km remaining)',
                                    style: AppTypography.labelMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Opening Google Maps navigation route...')),
                                    );
                                  },
                                  child: const Text('Navigate ↗', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Contact Card
                      FinishCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                widget.task.customerName.isNotEmpty ? widget.task.customerName[0] : 'C',
                                style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.task.customerName,
                                    style: AppTypography.titleSmall.copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Customer · Rating: ${widget.task.customerRating} ★',
                                    style: AppTypography.labelMedium.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TaskChatScreen(
                                      task: widget.task,
                                      otherUserId: widget.task.customerId.isNotEmpty ? widget.task.customerId : 'customer_sarah',
                                      otherUserName: widget.task.customerName,
                                      otherUserRating: '${widget.task.customerRating} ★',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calling customer via private proxy...')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: !_isStarted
                  ? FinishButton(
                      text: 'Start Task (Begin Work Timer ⏱️)',
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      onPressed: _startTask,
                    )
                  : FinishButton(
                      text: _isSubmitted ? 'Proof Submitted (Pending Customer Approval)' : 'Submit Proof & Complete Work 📸',
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                      onPressed: _isSubmitted ? null : _showProofUploadModal,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
