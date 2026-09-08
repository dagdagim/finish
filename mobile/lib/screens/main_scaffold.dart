import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/task_provider.dart';
import 'customer/customer_home_screen.dart';
import 'customer/customer_tasks_screen.dart';
import 'customer/post_task/post_task_wizard_screen.dart';
import 'tasker/tasker_home_screen.dart';
import 'tasker/tasker_ongoing_tasks_screen.dart';
import 'tasker/nearby_tasks_screen.dart';
import 'chat/messages_inbox_screen.dart';
import 'profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  StreamSubscription<InAppMessageNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      final taskProvider = context.read<TaskProvider>();
      final role = auth.isCustomerMode ? 'customer' : 'tasker';
      final userId = auth.currentUser?.id ?? (auth.isCustomerMode ? 'customer_sarah' : 'tasker_daniel');
      final userName = auth.currentUser?.fullName ?? (auth.isCustomerMode ? 'Sarah Mamo' : 'Daniel Kebede');
      chat.setCurrentUser(userId, role: role);
      chat.fetchConversations(role: role);
      taskProvider.setCurrentUser(userId, userName);

      _notificationSubscription = chat.notificationStream.listen((notification) {
        if (!mounted) return;
        final isHired = notification.taskTitle.contains('HIRED');
        if (isHired) {
          taskProvider.fetchTasks(roleMode: 'tasker');
        }

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isHired ? const Color(0xFF065F44) : AppColors.primaryDark,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHired ? const Color(0xFF10B981) : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHired ? Icons.stars_rounded : Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHired ? '🎉 CONGRATULATIONS · YOU ARE HIRED!' : '${notification.senderName} · ${notification.taskTitle}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.content,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: isHired ? 'View Job' : 'View',
              textColor: const Color(0xFF6EE7B7),
              onPressed: () {
                setState(() {
                  _currentIndex = isHired ? 1 : 3; // Ongoing tasks tab or Messages tab
                });
                if (isHired) {
                  taskProvider.fetchTasks(roleMode: 'tasker');
                }
              },
            ),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final isCustomer = auth.isCustomerMode;
    final unreadCount = chatProvider.totalUnreadCount;
    final ongoingCount = taskProvider.ongoingTasksCount;

    final List<Widget> customerScreens = [
      CustomerHomeScreen(onTabChange: (index) => setState(() => _currentIndex = index)),
      const CustomerTasksScreen(),
      const SizedBox.shrink(), // Center + action
      const MessagesInboxScreen(),
      const ProfileScreen(),
    ];

    final List<Widget> taskerScreens = [
      TaskerHomeScreen(onTabChange: (index) => setState(() => _currentIndex = index)),
      TaskerOngoingTasksScreen(onExploreNearby: () => setState(() => _currentIndex = 2)),
      const NearbyTasksScreen(),
      const MessagesInboxScreen(),
      const ProfileScreen(),
    ];

    final currentScreens = isCustomer ? customerScreens : taskerScreens;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: currentScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (isCustomer && index == 2) {
            // Prominent Post a Task CTA
            taskProvider.resetWizard();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostTaskWizardScreen()),
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
          if (index == 0 || index == 1) {
            taskProvider.fetchTasks(roleMode: isCustomer ? 'customer' : 'tasker');
          } else if (index == 3) {
            chatProvider.fetchConversations(role: isCustomer ? 'customer' : 'tasker');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        backgroundColor: Colors.white,
        elevation: 8,
        items: isCustomer
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment),
                  label: 'My Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                  label: 'Post',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: ongoingCount > 0,
                    label: Text(
                      '$ongoingCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF087F5B),
                    child: const Icon(Icons.assignment_turned_in_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: ongoingCount > 0,
                    label: Text(
                      '$ongoingCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF087F5B),
                    child: const Icon(Icons.assignment_turned_in_rounded),
                  ),
                  label: 'Ongoing',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Nearby',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}

