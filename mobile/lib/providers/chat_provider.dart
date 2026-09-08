import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../core/constants/api_constants.dart';
import '../data/models/message_model.dart';
import '../data/models/conversation_model.dart';
import '../data/models/task_model.dart';
import '../data/services/api_service.dart';

class InAppMessageNotification {
  final String taskId;
  final String senderName;
  final String content;
  final String taskTitle;
  final DateTime timestamp;

  InAppMessageNotification({
    required this.taskId,
    required this.senderName,
    required this.content,
    required this.taskTitle,
    required this.timestamp,
  });
}

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<MessageModel> _messages = [];
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  bool _isConversationsLoading = false;
  bool _isOtherUserTyping = false;
  String _typingUserName = '';
  socket_io.Socket? _socket;
  Timer? _pollTimer;
  Timer? _typingTimeoutTimer;
  String? _activeTaskId;
  String? _activeOtherUserId;
  String? _currentUserId;
  String _currentRole = 'customer';

  final StreamController<InAppMessageNotification> _notificationController =
      StreamController<InAppMessageNotification>.broadcast();

  final StreamController<Map<String, dynamic>> _taskerLocationController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _taskStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<InAppMessageNotification> get notificationStream => _notificationController.stream;
  Stream<Map<String, dynamic>> get taskerLocationStream => _taskerLocationController.stream;
  Stream<Map<String, dynamic>> get taskStatusStream => _taskStatusController.stream;

  List<MessageModel> get messages => _messages;
  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  bool get isConversationsLoading => _isConversationsLoading;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String get typingUserName => _typingUserName;
  String? get activeTaskId => _activeTaskId;
  String? get activeOtherUserId => _activeOtherUserId;

  int get totalUnreadCount {
    return _conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
  }

  ChatProvider() {
    _ensureGlobalSocket();
  }

  void setCurrentUser(String userId, {String role = 'customer'}) {
    _currentUserId = userId;
    _currentRole = role;
    _ensureGlobalSocket();
  }

  Future<void> fetchConversations({String? role, String? userId}) async {
    _isConversationsLoading = true;
    notifyListeners();

    final targetRole = role ?? _currentRole;
    final targetUser = userId ?? _currentUserId;
    final fetched = await _api.getConversations(role: targetRole, userId: targetUser);

    _conversations = fetched;
    _isConversationsLoading = false;
    notifyListeners();
  }

  void initializeChat(String taskId, String currentUserId, {String? otherUserId}) {
    _activeTaskId = taskId;
    _activeOtherUserId = otherUserId;
    _currentUserId = currentUserId;
    _messages = [];
    _isOtherUserTyping = false;
    _ensureGlobalSocket();
    fetchMessages(taskId, currentUserId, otherUserId: otherUserId);
    markAsRead(taskId, currentUserId);
    _joinTaskRoom(taskId);
    _joinUserRoom(currentUserId);
    if (otherUserId != null && otherUserId.isNotEmpty) {
      _joinThreadRoom(taskId, currentUserId, otherUserId);
    }
    _startAutoPolling(taskId, currentUserId, otherUserId: otherUserId);
  }

  void _ensureGlobalSocket() {
    if (_socket != null && _socket!.connected) return;

    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

      _socket?.dispose();
      _socket = socket_io.io(
        socketUrl,
        socket_io.OptionBuilder()
            .setTransports(['polling', 'websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket?.onConnect((_) {
        if (_activeTaskId != null) {
          _joinTaskRoom(_activeTaskId!);
        }
      });

      _socket?.onConnectError((_) {});
      _socket?.onError((_) {});

      _socket?.on('new_message', (data) => _handleIncomingMessage(data));
      _socket?.on('new_global_message', (data) => _handleIncomingMessage(data));


      _socket?.on('messages_read', (data) {
        if (data is Map && data['taskId'] != null) {
          final taskId = data['taskId'].toString();
          if (_activeTaskId == taskId) {
            for (var i = 0; i < _messages.length; i++) {
              _messages[i] = MessageModel(
                id: _messages[i].id,
                taskId: _messages[i].taskId,
                senderId: _messages[i].senderId,
                senderName: _messages[i].senderName,
                senderAvatar: _messages[i].senderAvatar,
                content: _messages[i].content,
                type: _messages[i].type,
                isMe: _messages[i].isMe,
                createdAt: _messages[i].createdAt,
              );
            }
            notifyListeners();
          }
        }
      });

      _socket?.on('user_typing', (data) {
        if (data is Map) {
          final mapTaskId = data['taskId']?.toString() ?? '';
          final incomingSenderId = data['userId']?.toString();
          if (incomingSenderId != null && incomingSenderId.isNotEmpty && incomingSenderId == _currentUserId) {
            return;
          }
          final cleanActive = _activeTaskId?.replaceFirst('task_', '');
          final cleanMap = mapTaskId.replaceFirst('task_', '');
          if (cleanActive != null && (cleanActive == cleanMap || _activeTaskId == mapTaskId)) {
            _isOtherUserTyping = true;
            _typingUserName = (data['userName']?.toString() ?? '').trim();
            if (_typingUserName.isEmpty) {
              _typingUserName = _currentRole == 'customer' ? 'Tasker' : 'Customer';
            }
            notifyListeners();

            // Auto-clear typing indicator after 4 seconds if no stop_typing arrives
            _typingTimeoutTimer?.cancel();
            _typingTimeoutTimer = Timer(const Duration(milliseconds: 4000), () {
              _isOtherUserTyping = false;
              notifyListeners();
            });
          }
        }
      });

      _socket?.on('user_stop_typing', (data) {
        if (data is Map) {
          final mapTaskId = data['taskId']?.toString() ?? '';
          final cleanActive = _activeTaskId?.replaceFirst('task_', '');
          final cleanMap = mapTaskId.replaceFirst('task_', '');
          if (cleanActive != null && (cleanActive == cleanMap || _activeTaskId == mapTaskId)) {
            _typingTimeoutTimer?.cancel();
            _isOtherUserTyping = false;
            notifyListeners();
          }
        }
      });

      _socket?.on('task_hired_notification', (data) {
        if (data is Map) {
          final hiredTaskerId = data['hiredTaskerId']?.toString();
          final taskTitle = data['taskTitle']?.toString() ?? 'Task';
          final customerName = data['customerName']?.toString() ?? 'Customer';
          final amount = data['offeredAmount']?.toString() ?? '';

          if (hiredTaskerId == null || hiredTaskerId == _currentUserId || _currentRole == 'tasker') {
            _notificationController.add(
              InAppMessageNotification(
                taskId: data['taskId']?.toString() ?? '',
                taskTitle: '🎉 YOU ARE HIRED!',
                senderName: customerName,
                content: '$customerName accepted your application for "$taskTitle" ($amount ETB). Tap to start working!',
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      });

      _socket?.on('in_app_notification', (data) {
        if (data is Map) {
          final targetUserId = data['targetUserId']?.toString();
          if (targetUserId == null || targetUserId == _currentUserId || _currentRole == 'tasker') {
            _notificationController.add(
              InAppMessageNotification(
                taskId: data['taskId']?.toString() ?? '',
                taskTitle: data['title']?.toString() ?? 'Notification',
                senderName: 'FINISH Marketplace',
                content: data['message']?.toString() ?? '',
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      });
      _socket?.on('tasker_location_update', (data) {
        if (data is Map) {
          _taskerLocationController.add(Map<String, dynamic>.from(data));
        }
      });
      _socket?.on('status_changed', (data) {
        if (data is Map) {
          _taskStatusController.add(Map<String, dynamic>.from(data));
        }
      });
      _socket?.on('task_completed', (data) {
        if (data is Map) {
          _taskStatusController.add(Map<String, dynamic>.from(data));
        }
      });
      _socket?.on('task_started', (data) {
        if (data is Map) {
          _taskStatusController.add(Map<String, dynamic>.from(data));
        }
      });
    } catch (_) {}
  }

  void _joinTaskRoom(String taskId) {
    _socket?.emit('join_task', taskId);
  }

  void _joinUserRoom(String userId) {
    _socket?.emit('join_user', userId);
  }

  void _joinThreadRoom(String taskId, String userA, String userB) {
    _socket?.emit('join_thread', {
      'taskId': taskId,
      'userA': userA,
      'userB': userB,
    });
  }

  void _handleIncomingMessage(dynamic data) {
    if (data is! Map) return;

    try {
      final map = Map<String, dynamic>.from(data);
      final userId = _currentUserId ?? 'customer_sarah';
      final msg = MessageModel.fromJson(map, userId);
      final msgTaskId = msg.taskId.isNotEmpty ? msg.taskId : (_activeTaskId ?? '');

      final isSentByMe = msg.isMe || (msg.senderId == userId);
      final recipientId = msg.recipientId.isNotEmpty ? msg.recipientId : map['recipientId']?.toString();

      // Privacy Check: Discard message if it is strictly addressed to someone else
      if (recipientId != null && recipientId.isNotEmpty && recipientId != userId && !isSentByMe) {
        return; // Private message for someone else
      }

      if (_activeTaskId == msgTaskId && _activeTaskId != null) {
        // If 1-on-1 active thread is open, only display messages between current user and activeOtherUser
        if (_activeOtherUserId != null && _activeOtherUserId!.isNotEmpty) {
          final isForThisThread = (msg.senderId == _activeOtherUserId || msg.recipientId == _activeOtherUserId) ||
              (isSentByMe && (recipientId == _activeOtherUserId || recipientId == null || recipientId.isEmpty));
          if (!isForThisThread) {
            return; // Belongs to a different applicant thread on the same task
          }
        }

        final existingIndex = _messages.indexWhere((m) {
          if (m.id == msg.id) return true;
          if (m.content.trim() == msg.content.trim()) {
            final diff = m.createdAt.difference(msg.createdAt).inSeconds.abs();
            if (diff < 30) return true;
          }
          return false;
        });

        if (existingIndex != -1) {
          _messages[existingIndex] = msg;
        } else {
          _messages.add(msg);
        }
        notifyListeners();

        // Mark as read immediately since user is actively viewing
        _api.markMessagesAsRead(msgTaskId);
      } else {
        // User is NOT on this chat screen -> Trigger notification & update unread badge!
        if (!isSentByMe) {
          final convIndex = _conversations.indexWhere(
            (c) => c.taskId == msgTaskId && (c.participant.id == msg.senderId || c.participant.id.isEmpty),
          );
          String taskTitle = 'Task Coordination';

          if (convIndex != -1) {
            final oldConv = _conversations[convIndex];
            taskTitle = oldConv.task.title;
            _conversations[convIndex] = ConversationModel(
              taskId: oldConv.taskId,
              task: oldConv.task,
              participant: oldConv.participant,
              lastMessage: ConversationLastMessage(
                id: msg.id,
                content: msg.content,
                createdAt: msg.createdAt,
                isRead: false,
              ),
              unreadCount: oldConv.unreadCount + 1,
            );
          } else {
            final localTask = _api.findLocalTask(msgTaskId);
            final isCustomer = _currentRole == 'customer';
            final senderName = msg.senderName.isNotEmpty
                ? msg.senderName
                : (localTask != null
                    ? (isCustomer ? (localTask.assignedTaskerName ?? 'Tasker') : localTask.customerName)
                    : (isCustomer ? 'Tasker Partner' : 'Customer'));
            final nameParts = senderName.trim().split(' ');
            taskTitle = localTask?.title ?? 'Task Direct Chat';

            _conversations.insert(
              0,
              ConversationModel(
                taskId: msgTaskId,
                task: localTask ??
                    TaskModel(
                      id: msgTaskId,
                      title: 'Task Direct Chat',
                      category: 'delivery',
                      description: 'Direct task coordination',
                      pickupLocation: TaskLocation(address: 'Addis Ababa'),
                      pricing: TaskPricing(budget: 450, suggestedPrice: 450),
                      status: 'IN_PROGRESS',
                    ),
                participant: ConversationParticipant(
                  id: msg.senderId.isNotEmpty ? msg.senderId : (isCustomer ? 'tasker_partner' : 'customer_user'),
                  firstName: nameParts.first,
                  lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
                  rating: 5.0,
                  reviewCount: 12,
                ),
                lastMessage: ConversationLastMessage(
                  id: msg.id,
                  content: msg.content,
                  createdAt: msg.createdAt,
                  isRead: false,
                ),
                unreadCount: 1,
              ),
            );
            fetchConversations(role: _currentRole, userId: _currentUserId);
          }

          notifyListeners();

          // Dispatch in-app notification
          _notificationController.add(
            InAppMessageNotification(
              taskId: msgTaskId,
              senderName: msg.senderName.isNotEmpty ? msg.senderName : 'Counterparty',
              content: msg.content,
              taskTitle: taskTitle,
              timestamp: msg.createdAt,
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _startAutoPolling(String taskId, String currentUserId, {String? otherUserId}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_activeTaskId == taskId) {
        try {
          final serverMsgs = await _api.getTaskMessages(taskId, currentUserId, otherUserId: otherUserId);
          if (serverMsgs.isNotEmpty) {
            bool hasNew = false;
            for (final sm in serverMsgs) {
              final existingIndex = _messages.indexWhere((m) {
                if (m.id == sm.id) return true;
                if (m.content.trim() == sm.content.trim()) {
                  final diff = m.createdAt.difference(sm.createdAt).inSeconds.abs();
                  if (diff < 30) return true;
                }
                return false;
              });

              if (existingIndex == -1) {
                _messages.add(sm);
                hasNew = true;
              } else if (_messages[existingIndex].id.startsWith('msg_')) {
                _messages[existingIndex] = sm;
                hasNew = true;
              }
            }
            if (hasNew) {
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              notifyListeners();
            }
          }
        } catch (_) {}
      }
    });
  }

  Future<void> fetchMessages(String taskId, String currentUserId, {String? otherUserId}) async {
    _isLoading = true;
    notifyListeners();

    _messages = await _api.getTaskMessages(taskId, currentUserId, otherUserId: otherUserId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String taskId, String currentUserId) async {
    // 1. Update local conversation unread count
    final convIndex = _conversations.indexWhere((c) => c.taskId == taskId);
    if (convIndex != -1) {
      final old = _conversations[convIndex];
      _conversations[convIndex] = ConversationModel(
        taskId: old.taskId,
        task: old.task,
        participant: old.participant,
        lastMessage: ConversationLastMessage(
          id: old.lastMessage.id,
          content: old.lastMessage.content,
          createdAt: old.lastMessage.createdAt,
          isRead: true,
        ),
        unreadCount: 0,
      );
      notifyListeners();
    }

    // 2. Call backend API
    await _api.markMessagesAsRead(taskId);
  }

  Future<void> sendMessage(
    String taskId,
    String content,
    String senderId,
    String senderName, {
    String? recipientId,
  }) async {
    if (content.trim().isEmpty) return;

    final targetRecipient = recipientId ?? _activeOtherUserId ?? '';
    final tempId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = MessageModel(
      id: tempId,
      taskId: taskId,
      senderId: senderId,
      recipientId: targetRecipient,
      senderName: senderName,
      senderAvatar: '',
      content: content.trim(),
      type: 'TEXT',
      isMe: true,
      createdAt: DateTime.now(),
    );

    _messages.add(newMsg);

    // Update conversation preview locally
    final convIndex = _conversations.indexWhere((c) => c.taskId == taskId);
    if (convIndex != -1) {
      final old = _conversations[convIndex];
      _conversations[convIndex] = ConversationModel(
        taskId: old.taskId,
        task: old.task,
        participant: old.participant,
        lastMessage: ConversationLastMessage(
          id: tempId,
          content: content.trim(),
          createdAt: DateTime.now(),
          isRead: true,
        ),
        unreadCount: 0,
      );
    } else {
      final localTask = _api.findLocalTask(taskId);
      final isCustomer = _currentRole == 'customer';
      final otherName = localTask != null
          ? (isCustomer ? (localTask.assignedTaskerName ?? 'Tasker') : localTask.customerName)
          : (isCustomer ? 'Tasker Partner' : 'Customer');
      final nameParts = otherName.trim().split(' ');

      _conversations.insert(
        0,
        ConversationModel(
          taskId: taskId,
          task: localTask ??
              TaskModel(
                id: taskId,
                title: 'Task Direct Chat',
                category: 'delivery',
                description: 'Direct task coordination',
                pickupLocation: TaskLocation(address: 'Addis Ababa'),
                pricing: TaskPricing(budget: 450, suggestedPrice: 450),
                status: 'IN_PROGRESS',
              ),
          participant: ConversationParticipant(
            id: isCustomer ? 'tasker_partner' : 'customer_user',
            firstName: nameParts.first,
            lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            rating: 5.0,
            reviewCount: 12,
          ),
          lastMessage: ConversationLastMessage(
            id: tempId,
            content: content.trim(),
            createdAt: DateTime.now(),
            isRead: true,
          ),
          unreadCount: 0,
        ),
      );
    }

    notifyListeners();

    // Persist to MongoDB database via HTTP API with target recipient
    await _api.sendMessage(
      taskId,
      content.trim(),
      senderId: senderId,
      senderName: senderName,
      recipientId: targetRecipient,
    );
  }

  void sendTyping(String taskId, String userName, {String? userId, String? recipientId}) {
    _socket?.emit('typing', {
      'taskId': taskId,
      'userName': userName,
      'userId': userId ?? _currentUserId,
      'recipientId': recipientId ?? _activeOtherUserId,
    });
  }

  void sendStopTyping(String taskId, String userName, {String? userId, String? recipientId}) {
    _socket?.emit('stop_typing', {
      'taskId': taskId,
      'userName': userName,
      'userId': userId ?? _currentUserId,
      'recipientId': recipientId ?? _activeOtherUserId,
    });
  }

  void emitTaskerLocation(String taskId, double lat, double lng, {double? heading, double? speed}) {
    _socket?.emit('tasker_location_update', {
      'taskId': taskId,
      'latitude': lat,
      'longitude': lng,
      'heading': heading ?? 0.0,
      'speed': speed ?? 0.0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void leaveChat() {
    _pollTimer?.cancel();
    _typingTimeoutTimer?.cancel();
    _isOtherUserTyping = false;
    _activeTaskId = null;
    _activeOtherUserId = null;
  }

  @override
  void dispose() {
    leaveChat();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _notificationController.close();
    _taskerLocationController.close();
    _taskStatusController.close();
    super.dispose();
  }
}

