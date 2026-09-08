import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/finish_button.dart';
import '../../core/widgets/finish_text_field.dart';
import '../../data/models/task_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/task_provider.dart';
import '../chat/task_chat_screen.dart';
import 'tasker_active_job_screen.dart';

class TaskerTaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskerTaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskerTaskDetailsScreen> createState() => _TaskerTaskDetailsScreenState();
}

class _TaskerTaskDetailsScreenState extends State<TaskerTaskDetailsScreen> {
  late TaskModel _currentTask;
  OfferModel? _myOffer;
  bool _hasApplied = false;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    final res = await ApiService().getTaskById(_currentTask.id);
    if (mounted) {
      final task = (res['task'] as TaskModel?) ?? _currentTask;
      final offers = (res['offers'] as List<OfferModel>?) ?? [];

      final taskProvider = context.read<TaskProvider>();
      OfferModel? myOffer = taskProvider.getMyOffer(_currentTask.id);

      if (myOffer == null && offers.isNotEmpty) {
        try {
          myOffer = offers.firstWhere(
            (o) => o.taskerName == 'Daniel K.' || o.taskerId == 'tasker_daniel' || o.taskerId == 'tasker_current',
          );
        } catch (_) {}
      }

      final hasApplied = taskProvider.hasApplied(_currentTask.id) || myOffer != null;

      setState(() {
        _currentTask = task;
        _myOffer = myOffer;
        _hasApplied = hasApplied;
      });
    }
  }

  void _showOfferModal({bool isCounter = false}) {
    final defaultPrice = isCounter
        ? ((_currentTask.pricing.budget * 1.15).round()).toString()
        : _currentTask.pricing.budget.toString();
    final offerController = TextEditingController(text: defaultPrice);
    final noteController = TextEditingController(
      text: isCounter
          ? 'Counter offer: I have specialized tools and transport. Can begin on schedule.'
          : 'I have the tools and experience needed. Ready to begin on schedule.',
    );
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCounter ? 'Submit Counter Offer' : 'Apply for Task',
                        style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Budget: ${_currentTask.pricing.budget} ETB',
                          style: AppTypography.labelMedium.copyWith(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submit your proposal. The customer will review your star rating, chat with you, and approve.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),

                  FinishTextField(
                    controller: offerController,
                    label: 'Your Proposed Payout (ETB)',
                    hintText: _currentTask.pricing.budget.toString(),
                    keyboardType: TextInputType.number,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(widthFactor: 1, child: Text('ETB', style: AppTypography.labelLarge)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Quick pitch templates:', style: AppTypography.labelMedium.copyWith(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickPitchChip('⚡ Ready in 15 mins', noteController, setModalState),
                        const SizedBox(width: 6),
                        _buildQuickPitchChip('🔧 Have all specialized tools', noteController, setModalState),
                        const SizedBox(width: 6),
                        _buildQuickPitchChip('⭐ 5-Star rated expert', noteController, setModalState),
                        const SizedBox(width: 6),
                        _buildQuickPitchChip('🚗 Fast transport ready', noteController, setModalState),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  FinishTextField(
                    controller: noteController,
                    label: 'Proposal message for customer',
                    hintText: 'Introduce your experience and arrival time...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  FinishButton(
                    text: 'Submit Application',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      setModalState(() => isSubmitting = true);
                      final amount = int.tryParse(offerController.text.trim()) ?? _currentTask.pricing.budget;
                      final note = noteController.text.trim();
                      final offer = await context.read<TaskProvider>().submitOffer(
                        _currentTask.id,
                        amount,
                        note,
                        taskerId: 'tasker_daniel',
                        taskerName: 'Daniel K.',
                      );
                      setModalState(() => isSubmitting = false);
                      setState(() {
                        _hasApplied = true;
                        if (offer != null) _myOffer = offer;
                      });
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Application of $amount ETB sent to customer! Once they approve & chat, you can start the task.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickPitchChip(String text, TextEditingController controller, StateSetter setModalState) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setModalState(() {
          controller.text = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartTask() async {
    setState(() => _isStarting = true);
    final taskProvider = context.read<TaskProvider>();
    final success = await taskProvider.startTask(_currentTask.id);
    setState(() => _isStarting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task started! Live location tracking is active.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TaskerActiveJobScreen(task: _currentTask),
        ),
      );
    }
  }

  List<Map<String, String>> _extractTaskSpecifications(TaskModel task) {
    final list = <Map<String, String>>[];
    final desc = '${task.description}\n${task.specialInstructions}';

    // Parse structured tags if present
    for (final line in desc.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.contains(':') && !trimmed.startsWith('http')) {
        final parts = trimmed.split(':');
        final key = parts[0].replaceAll('•', '').replaceAll('-', '').trim();
        final val = parts.sublist(1).join(':').trim();
        if (key.isNotEmpty && val.isNotEmpty && key.length < 32 && val.length < 120) {
          list.add({'label': key, 'value': val});
        }
      }
    }

    if (list.isEmpty) {
      list.add({'label': 'Category', 'value': task.category.toUpperCase()});
      list.add({'label': 'Estimated Duration', 'value': '~${task.estimatedDurationMin} minutes'});
      list.add({'label': 'Pricing Model', 'value': task.pricing.pricingType.toUpperCase()});
      list.add({'label': 'Platform Fee', 'value': '0 ETB (Free for Tasker)'});
    }

    return list;
  }

  List<String> _extractShoppingItems(TaskModel task) {
    final items = <String>[];
    final fullText = '${task.title}\n${task.description}\n${task.specialInstructions}';
    for (final line in fullText.split('\n')) {
      if (line.toLowerCase().contains('items:')) {
        final raw = line.substring(line.toLowerCase().indexOf('items:') + 6).trim();
        for (final item in raw.split(',')) {
          if (item.trim().isNotEmpty) items.add(item.trim());
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    final specs = _extractTaskSpecifications(task);
    final shoppingItems = _extractShoppingItems(task);
    final hasDropoff = task.dropoffLocation != null && task.dropoffLocation!.address.isNotEmpty;

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
            icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primary),
            tooltip: 'Refresh Task',
            onPressed: _loadTaskDetails,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.textDark),
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
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadTaskDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Application Status Banner (Approved / Rejected / Pending)
                    _buildApplicationStatusBanner(),

                    // Hero Task Overview Card with Gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF064E3B).withOpacity(0.3),
                            blurRadius: 14,
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
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.category.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34D399),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${task.pricing.budget} ETB',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: const Color(0xFF022C22),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            task.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.route_rounded, size: 14, color: Color(0xFF6EE7B7)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.routeDisplay,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Metrics Strip
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            icon: Icons.near_me_rounded,
                            label: '${task.distanceKm} km',
                            sub: 'Distance',
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricPill(
                            icon: Icons.timer_rounded,
                            label: '~${task.estimatedDurationMin} min',
                            sub: 'Est. Time',
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricPill(
                            icon: Icons.shield_rounded,
                            label: 'Escrow',
                            sub: 'Protected',
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 1: Task Scope & Hardness Specifications
                    _buildSectionCard(
                      title: 'Task Scope & Specifications',
                      icon: Icons.assignment_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description.isNotEmpty) ...[
                            Text(
                              task.description,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 13,
                                color: AppColors.textDark,
                                height: 1.45,
                              ),
                            ),
                            const Divider(height: 20, color: Color(0xFFF3F4F6)),
                          ],
                          for (int i = 0; i < specs.length; i++) ...[
                            _buildSpecificationRow(specs[i]['label']!, specs[i]['value']!),
                            if (i < specs.length - 1) const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 2: Itemized Shopping List (if shopping)
                    if (shoppingItems.isNotEmpty) ...[
                      _buildSectionCard(
                        title: 'Itemized Items Checklist (${shoppingItems.length} items)',
                        icon: Icons.shopping_bag_outlined,
                        child: Column(
                          children: [
                            for (final item in shoppingItems)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFFD97706)),
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
                      const SizedBox(height: 12),
                    ],

                    // Section 3: Location & Route Information
                    _buildSectionCard(
                      title: 'Location & Navigation',
                      icon: Icons.location_on_outlined,
                      child: Column(
                        children: [
                          _buildLocationPoint(
                            icon: Icons.trip_origin_rounded,
                            iconColor: AppColors.primary,
                            label: hasDropoff ? 'Pickup / Origin Location' : 'Service Address',
                            address: task.pickupLocation.address,
                            instructions: task.pickupLocation.instructions,
                          ),
                          if (hasDropoff) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                              child: Container(width: 1.5, height: 18, color: const Color(0xFFE5E7EB)),
                            ),
                            _buildLocationPoint(
                              icon: Icons.location_on_rounded,
                              iconColor: const Color(0xFFEF4444),
                              label: 'Drop-off / Destination Location',
                              address: task.dropoffLocation!.address,
                              instructions: task.dropoffLocation!.instructions,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car_filled_outlined, size: 14, color: AppColors.textDark),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${task.distanceKm} km estimated road distance (~${task.estimatedDurationMin} mins)',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 12),

                    // Section 4: Schedule & Timing
                    _buildSectionCard(
                      title: 'Schedule & Execution Window',
                      icon: Icons.schedule_rounded,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.scheduleText,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Guaranteed punctuality window · ETA tracked in chat',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 5: Tasker Guaranteed Earnings Breakdown
                    _buildSectionCard(
                      title: 'Earnings & Payout Agreement',
                      icon: Icons.payments_outlined,
                      child: Column(
                        children: [
                          _buildSpecificationRow('Customer Budget', '${task.pricing.budget} ETB'),
                          const SizedBox(height: 6),
                          _buildSpecificationRow('Platform Service Fee', '0 ETB (Free)'),
                          const Divider(height: 16, color: Color(0xFFF3F4F6)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Net Payout',
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${task.pricing.budget} ETB',
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF087F5B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 6: Customer Profile & Direct Contact
                    _buildSectionCard(
                      title: 'Customer Verification',
                      icon: Icons.person_outline_rounded,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              task.customerName.isNotEmpty ? task.customerName[0].toUpperCase() : 'C',
                              style: AppTypography.titleSmall.copyWith(
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.customerName,
                                        style: AppTypography.titleSmall.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified_rounded, size: 10, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Verified',
                                            style: AppTypography.labelMedium.copyWith(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF15803D),
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
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${task.customerRating} (${task.customerReviewCount} reviews)',
                                      style: AppTypography.labelMedium.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TaskChatScreen(
                                    task: task,
                                    otherUserId: task.customerId.isNotEmpty ? task.customerId : (task.customerName == 'Sarah M.' ? 'customer_sarah' : 'customer_user'),
                                    otherUserName: task.customerName,
                                    otherUserRating: '${task.customerRating} ★',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 7: Ratings & Admin Performance Appraisal
                    _buildRatingsAndAppraisalSection(task),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Floating Action Bar: Apply for Task, Chat, or Start Task
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsAndAppraisalSection(TaskModel task) {
    final hasAdminRating = task.adminRatings != null;
    final hasCustomerRating = task.customerRatingToTasker != null;
    final isFinished = task.status == 'PAID' || task.status == 'COMPLETED' || task.status == 'SUBMITTED';

    if (!hasAdminRating && !hasCustomerRating && !isFinished) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CUSTOMER REVIEW CARD (Received from Customer)
        if (hasCustomerRating) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withOpacity(0.08),
                  blurRadius: 8,
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
                        const Icon(Icons.star_rounded, size: 20, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text(
                          'Customer Rating (${task.customerName})',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${task.customerRatingToTasker!.rating}.0 ★',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (task.customerRatingToTasker!.review?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${task.customerRatingToTasker!.review}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: Color(0xFF78350F),
                      height: 1.4,
                    ),
                  ),
                ],
                if (task.customerRatingToTasker!.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: task.customerRatingToTasker!.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFBBF24)),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    )).toList(),
                  ),
                ],
                if (task.customerRatingToTasker!.tipAmount > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💰 Customer included +${task.customerRatingToTasker!.tipAmount.toInt()} ETB Tip in your payout!',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (isFinished) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Awaiting customer rating from ${task.customerName}. You will receive a notification when submitted.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. ADMIN PERFORMANCE APPRAISAL CARD (Received from Admin)
        if (hasAdminRating) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withOpacity(0.06),
                  blurRadius: 8,
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified_rounded, size: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Finish Admin Quality Appraisal',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF064E3B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${task.adminRatings!.taskerRating}.0 ★',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  task.adminRatings!.taskerReview?.isNotEmpty == true
                      ? '"${task.adminRatings!.taskerReview}"'
                      : '"Professional service execution verified by Finish admin."',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                    color: Color(0xFF064E3B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF047857)),
                    const SizedBox(width: 4),
                    Text(
                      'Official reputation rating by Platform Administrator',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF064E3B).withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (isFinished) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF047857), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Admin quality appraisal pending. High ratings boost your task feed priority!',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildApplicationStatusBanner() {
    final taskProvider = context.watch<TaskProvider>();
    final myOffer = _myOffer ?? taskProvider.getMyOffer(_currentTask.id);

    final isRejected = myOffer?.status == 'REJECTED' ||
        ((_currentTask.status == 'ACCEPTED' || _currentTask.status == 'IN_PROGRESS') &&
            _currentTask.assignedTaskerName != 'Daniel K.' &&
            myOffer?.status != 'ACCEPTED' &&
            _hasApplied);

    final isApproved = myOffer?.status == 'ACCEPTED' ||
        (_currentTask.status == 'ACCEPTED' &&
            (_currentTask.assignedTaskerName == 'Daniel K.' || (_hasApplied && myOffer?.status != 'REJECTED')));

    if (isRejected) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Not Selected',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'The customer selected another applicant for this task. Don\'t worry—explore other open tasks on your feed!',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFFB91C1C),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isApproved) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎉 Application Approved by Customer!',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF166534),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'You have been officially hired for this task! Tap "Start Task Now" below when you arrive to begin working.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF15803D),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_hasApplied || myOffer?.status == 'PENDING') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Applied · Waiting for Customer Approval',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your proposal is being reviewed. The customer may chat with you before accepting. You can only apply once.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFFB45309),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomActionBar() {
    final taskProvider = context.watch<TaskProvider>();
    final myOffer = _myOffer ?? taskProvider.getMyOffer(_currentTask.id);

    final isRejected = myOffer?.status == 'REJECTED' ||
        ((_currentTask.status == 'ACCEPTED' || _currentTask.status == 'IN_PROGRESS') &&
            _currentTask.assignedTaskerName != 'Daniel K.' &&
            myOffer?.status != 'ACCEPTED' &&
            _hasApplied);

    final isApproved = myOffer?.status == 'ACCEPTED' ||
        (_currentTask.status == 'ACCEPTED' &&
            (_currentTask.assignedTaskerName == 'Daniel K.' || (_hasApplied && myOffer?.status != 'REJECTED')));

    // 1. REJECTED: Another tasker was chosen
    if (isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                'Position Filled · Another Tasker Chosen',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Task is OPEN / OFFERING
    if (_currentTask.status == 'OPEN' || _currentTask.status == 'OFFERING') {
      if (_hasApplied || myOffer?.status == 'PENDING') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskChatScreen(
                          task: _currentTask,
                          otherUserId: _currentTask.customerId.isNotEmpty ? _currentTask.customerId : (_currentTask.customerName == 'Sarah M.' ? 'customer_sarah' : 'customer_user'),
                          otherUserName: _currentTask.customerName,
                          otherUserRating: '${_currentTask.customerRating} ★',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.textDark),
                  label: Text(
                    'Chat',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Applied · Pending Approval',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: FinishButton(
                text: 'Counter Offer',
                variant: FinishButtonVariant.outline,
                onPressed: () => _showOfferModal(isCounter: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: FinishButton(
                text: 'Apply for Task (${_currentTask.pricing.budget} ETB)',
                onPressed: () => _showOfferModal(isCounter: false),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Customer approved this tasker -> Status is ACCEPTED
    if (_currentTask.status == 'ACCEPTED' || isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskChatScreen(
                        task: _currentTask,
                        otherUserId: _currentTask.customerId.isNotEmpty ? _currentTask.customerId : (_currentTask.customerName == 'Sarah M.' ? 'customer_sarah' : 'customer_user'),
                        otherUserName: _currentTask.customerName,
                        otherUserRating: '${_currentTask.customerRating} ★',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.textDark),
                label: Text(
                  'Chat',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: FinishButton(
                text: 'Start Task Now 🚀',
                isLoading: _isStarting,
                onPressed: _handleStartTask,
              ),
            ),
          ],
        ),
      );
    }

    // 4. Task is already IN_PROGRESS
    if (_currentTask.status == 'IN_PROGRESS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: FinishButton(
          text: 'Continue Active Job 🚀',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TaskerActiveJobScreen(task: _currentTask),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 9.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
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
            value,
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
    );
  }

  Widget _buildLocationPoint({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
    String? instructions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                address,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (instructions != null && instructions.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  instructions,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

