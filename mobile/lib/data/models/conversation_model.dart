import 'task_model.dart';

class ConversationParticipant {
  final String id;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final bool isIdentityVerified;

  ConversationParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl = '',
    this.rating = 4.9,
    this.reviewCount = 18,
    this.isIdentityVerified = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ConversationParticipant.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ConversationParticipant(
        id: 'user_1',
        firstName: 'Daniel',
        lastName: 'Kebede',
      );
    }
    return ConversationParticipant(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? 'User',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      rating: (json['rating'] != null) ? (json['rating'] as num).toDouble() : 4.9,
      reviewCount: json['reviewCount'] ?? 18,
      isIdentityVerified: json['isIdentityVerified'] ?? true,
    );
  }
}

class ConversationLastMessage {
  final String id;
  final String content;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  ConversationLastMessage({
    required this.id,
    required this.content,
    this.type = 'TEXT',
    required this.createdAt,
    this.isRead = true,
  });

  factory ConversationLastMessage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ConversationLastMessage(
        id: 'msg_0',
        content: 'Tap to start conversation.',
        createdAt: DateTime.now(),
      );
    }
    return ConversationLastMessage(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? true,
    );
  }
}

class ConversationModel {
  final String taskId;
  final TaskModel task;
  final ConversationParticipant participant;
  final ConversationLastMessage lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.taskId,
    required this.task,
    required this.participant,
    required this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final taskData = json['task'] is Map ? json['task'] as Map<String, dynamic> : <String, dynamic>{};
    return ConversationModel(
      taskId: json['taskId'] ?? taskData['_id'] ?? '',
      task: TaskModel.fromJson(taskData),
      participant: ConversationParticipant.fromJson(json['participant']),
      lastMessage: ConversationLastMessage.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
