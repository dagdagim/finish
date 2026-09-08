import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'task_chat_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'unread', 'active', 'inquiries'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final role = auth.isCustomerMode ? 'customer' : 'tasker';
      final userId = auth.currentUser?.id ?? (auth.isCustomerMode ? 'customer_sarah' : 'tasker_daniel');
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setCurrentUser(userId, role: role);
      chatProvider.fetchConversations(role: role, userId: userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && now.day == date.day) {
      return DateFormat('h:mm a').format(date);
    } else if (diff.inDays == 1 || (diff.inHours < 48 && now.day != date.day)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final isCustomer = auth.isCustomerMode;
    final role = isCustomer ? 'customer' : 'tasker';

    List<ConversationModel> filtered = chatProvider.conversations;

    // Search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.participant.fullName.toLowerCase().contains(query) ||
            c.task.title.toLowerCase().contains(query) ||
            c.lastMessage.content.toLowerCase().contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedFilter == 'unread') {
      filtered = filtered.where((c) => c.unreadCount > 0).toList();
    } else if (_selectedFilter == 'active') {
      filtered = filtered.where((c) => c.task.status == 'IN_PROGRESS' || c.task.status == 'ACCEPTED').toList();
    } else if (_selectedFilter == 'inquiries') {
      filtered = filtered.where((c) => c.task.status == 'OPEN' || c.task.status == 'OFFERING').toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages & Chat',
              style: AppTypography.titleMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              isCustomer ? 'Coordinate with verified Taskers' : 'Chat with task Customers',
              style: AppTypography.labelMedium.copyWith(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
            onPressed: () => context.read<ChatProvider>().fetchConversations(role: role),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<ChatProvider>().fetchConversations(role: role),
        child: Column(
          children: [
            // End-to-End Task Protected Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                border: Border(bottom: BorderSide(color: Color(0xFFDCFCE7))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All chats are direct, private, and encrypted under FINISH Escrow protection.',
                      style: AppTypography.labelMedium.copyWith(
                        color: const Color(0xFF15803D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'Search people or tasks...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),

            // Filter Tabs Strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterTab('all', 'All Chats'),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      'unread',
                      chatProvider.totalUnreadCount > 0
                          ? 'Unread (${chatProvider.totalUnreadCount})'
                          : 'Unread',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab('active', 'Active Jobs'),
                    const SizedBox(width: 8),
                    _buildFilterTab('inquiries', 'Open & Inquiries'),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Conversations List
            Expanded(
              child: chatProvider.isConversationsLoading && chatProvider.conversations.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            return _buildConversationCard(conv, isCustomer);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String id, String label) {
    final isSelected = _selectedFilter == id;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(ConversationModel conv, bool isCustomer) {
    final participant = conv.participant;
    final task = conv.task;
    final lastMsg = conv.lastMessage;
    final timeStr = _formatTime(lastMsg.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final auth = context.read<AuthProvider>();
        final currentUserId = auth.currentUser?.id ?? (isCustomer ? 'customer_sarah' : 'tasker_daniel');
        context.read<ChatProvider>().markAsRead(task.id, currentUserId);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskChatScreen(
              task: task,
              otherUserId: participant.id,
              otherUserName: participant.fullName,
              otherUserRating: '${participant.rating} ★',
            ),
          ),
        ).then((_) {
          // Refresh inbox when coming back from chat
          final role = isCustomer ? 'customer' : 'tasker';
          context.read<ChatProvider>().fetchConversations(role: role, userId: currentUserId);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: conv.unreadCount > 0 ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
            width: conv.unreadCount > 0 ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(conv.unreadCount > 0 ? 0.05 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with Online Badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    participant.firstName.isNotEmpty ? participant.firstName[0].toUpperCase() : 'U',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name, Rating & Time
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          participant.fullName,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${participant.rating} ★',
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                          color: conv.unreadCount > 0 ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Row 2: Task Context Tag & Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 11, color: AppColors.textDark),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${task.title} · ${task.pricing.budget} ETB',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Row 3: Last Message snippet + Unread Counter
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg.content,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 12.5,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                            color: conv.unreadCount > 0 ? AppColors.textDark : AppColors.textMuted,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'No Conversations Yet',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              'When you post a task or apply for a job, you can chat directly and coordinate with verified counterparties.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<ChatProvider>().fetchConversations(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh Messages', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
