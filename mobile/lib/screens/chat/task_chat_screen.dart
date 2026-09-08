import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class TaskChatScreen extends StatefulWidget {
  final TaskModel task;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserRating;

  const TaskChatScreen({
    super.key,
    required this.task,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserRating,
  });

  @override
  State<TaskChatScreen> createState() => _TaskChatScreenState();
}

class _TaskChatScreenState extends State<TaskChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingDebounce;
  int _lastMsgCount = 0;

  String _getOtherUserId(bool isCustomer) {
    if (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) {
      return widget.otherUserId!;
    }
    if (isCustomer) {
      return widget.task.assignedTaskerName == 'Daniel K.' ? 'tasker_daniel' : 'tasker_user';
    } else {
      return widget.task.customerName == 'Sarah M.' ? 'customer_sarah' : 'customer_user';
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final isCustomer = auth.isCustomerMode;
    final userId = auth.currentUser?.id ?? (isCustomer ? 'customer_sarah' : 'tasker_daniel');
    final otherId = _getOtherUserId(isCustomer);

    context.read<ChatProvider>().initializeChat(widget.task.id, userId, otherUserId: otherId);
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final auth = context.read<AuthProvider>();
    final isCustomer = auth.isCustomerMode;
    final userId = auth.currentUser?.id ?? (isCustomer ? 'customer_sarah' : 'tasker_daniel');
    final userName = auth.currentUser?.firstName.isNotEmpty == true
        ? auth.currentUser!.firstName
        : (isCustomer ? 'Customer' : 'Tasker');
    final otherId = _getOtherUserId(isCustomer);
    final chat = context.read<ChatProvider>();

    if (_messageController.text.trim().isNotEmpty) {
      chat.sendTyping(widget.task.id, userName, userId: userId, recipientId: otherId);
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 3), () {
        chat.sendStopTyping(widget.task.id, userName, userId: userId, recipientId: otherId);
      });
    } else {
      chat.sendStopTyping(widget.task.id, userName, userId: userId, recipientId: otherId);
    }
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    try {
      context.read<ChatProvider>().leaveChat();
    } catch (_) {}
    super.dispose();
  }

  void _sendMessage({String? customText}) {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final isCustomer = auth.isCustomerMode;
    final userId = auth.currentUser?.id ?? (isCustomer ? 'customer_sarah' : 'tasker_daniel');
    final userName = auth.currentUser?.fullName.isNotEmpty == true
        ? auth.currentUser!.fullName
        : (isCustomer ? 'Customer' : 'Tasker');
    final otherId = _getOtherUserId(isCustomer);

    final chat = context.read<ChatProvider>();
    chat.sendStopTyping(widget.task.id, userName, userId: userId, recipientId: otherId);
    chat.sendMessage(widget.task.id, text, userId, userName, recipientId: otherId);
    if (customText == null) {
      _messageController.clear();
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final isCustomer = auth.isCustomerMode;
    final currentUserId = auth.currentUser?.id ?? (isCustomer ? 'customer_user' : 'tasker_user');

    if (chatProvider.messages.length != _lastMsgCount) {
      _lastMsgCount = chatProvider.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    final defaultOtherName = isCustomer
        ? (widget.task.assignedTaskerName?.isNotEmpty == true ? widget.task.assignedTaskerName! : 'Assigned Tasker')
        : (widget.task.customerName.isNotEmpty ? widget.task.customerName : 'Customer');
    final displayName = widget.otherUserName?.isNotEmpty == true ? widget.otherUserName! : defaultOtherName;
    final displayRating = widget.otherUserRating ?? (isCustomer ? '5.0 ★' : '${widget.task.customerRating} ★');


    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textDark),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                style: AppTypography.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: AppTypography.titleSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          displayRating,
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  if (chatProvider.isOtherUserTyping)
                    Row(
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
                        Text(
                          'typing...',
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
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
                        Expanded(
                          child: Text(
                            '${widget.task.pricing.budget} ETB · ${widget.task.title}',
                            style: AppTypography.labelMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
            tooltip: 'Refresh messages',
            onPressed: () {
              final auth = context.read<AuthProvider>();
              final userId = auth.currentUser?.id ?? (auth.isCustomerMode ? 'customer_sarah' : 'tasker_daniel');
              context.read<ChatProvider>().fetchMessages(
                    widget.task.id,
                    userId,
                    otherUserId: _getOtherUserId(auth.isCustomerMode),
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔒 Privacy Call: Connecting via FINISH masked private relay...')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // End-to-End Privacy & Escrow Protection Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                border: Border(bottom: BorderSide(color: Color(0xFFDCFCE7))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'End-to-End Task Protected · Phone numbers & payments secured by FINISH Escrow.',
                      style: AppTypography.labelMedium.copyWith(
                        color: const Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  final auth = context.read<AuthProvider>();
                  final userId = auth.currentUser?.id ?? (auth.isCustomerMode ? 'customer_user' : 'tasker_user');
                  await context.read<ChatProvider>().fetchMessages(
                        widget.task.id,
                        userId,
                        otherUserId: _getOtherUserId(auth.isCustomerMode),
                      );
                },
                child: chatProvider.messages.isEmpty && !chatProvider.isOtherUserTyping
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Direct Escrow Chat',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Coordinate task details, location, and arrival safely with $displayName.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        itemCount: chatProvider.messages.length + (chatProvider.isOtherUserTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (chatProvider.isOtherUserTyping && index == chatProvider.messages.length) {
                            return _buildTypingIndicator(chatProvider.typingUserName);
                          }

                          final msg = chatProvider.messages[index];
                          final isMe = msg.senderId == currentUserId || msg.isMe;
                          final timeStr = DateFormat('h:mm a').format(msg.createdAt);

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
                                  bottomLeft: !isMe ? const Radius.circular(2) : const Radius.circular(16),
                                ),
                                border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.content,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isMe ? Colors.white : AppColors.textDark,
                                      fontSize: 13.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Quick Prompt Chips (Role-Tailored with Material Icons)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: isCustomer
                      ? [
                          _buildQuickChip(Icons.access_time_rounded, 'What is your ETA?'),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.meeting_room_outlined, "I'm waiting at the entrance"),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.handshake_outlined, 'Looks good, please proceed'),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.photo_camera_outlined, 'Please send photo proof'),
                        ]
                      : [
                          _buildQuickChip(Icons.directions_car_rounded, "I'm on my way now"),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.location_on_outlined, 'Arrived at the location'),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.build_outlined, 'I have all necessary tools'),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.photo_camera_outlined, 'Job completed, sending photo'),
                          const SizedBox(width: 6),
                          _buildQuickChip(Icons.verified_outlined, 'Ready for inspection & release'),
                        ],
                ),
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select task photo or document to attach.')),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'Type a private message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(IconData icon, String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _sendMessage(customText: text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              text,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(String userName) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(2),
          ),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedTypingDots(),
            const SizedBox(width: 8),
            Text(
              '$userName is typing...',
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedTypingDots extends StatefulWidget {
  const AnimatedTypingDots({super.key});

  @override
  State<AnimatedTypingDots> createState() => _AnimatedTypingDotsState();
}

class _AnimatedTypingDotsState extends State<AnimatedTypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final val = (_controller.value - delay) % 1.0;
            final scale = (val < 0.5 ? val * 2 : (1.0 - val) * 2).clamp(0.4, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFF10B981), const Color(0xFF047857), scale)!,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

