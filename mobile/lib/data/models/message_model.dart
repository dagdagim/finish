class MessageModel {
  final String id;
  final String taskId;
  final String senderId;
  final String recipientId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String type;
  final bool isMe;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.taskId,
    required this.senderId,
    this.recipientId = '',
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    this.type = 'TEXT',
    required this.isMe,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    String sId = '';
    String sName = 'User';
    String sAvatar = '';
    String rId = '';

    if (json['senderId'] is Map) {
      final s = json['senderId'];
      sId = s['_id'] ?? s['id'] ?? '';
      sName = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
      sAvatar = s['avatarUrl'] ?? '';
    } else if (json['senderId'] != null) {
      sId = json['senderId'].toString();
    }

    if (json['recipientId'] is Map) {
      final r = json['recipientId'];
      rId = r['_id'] ?? r['id'] ?? '';
    } else if (json['recipientId'] != null) {
      rId = json['recipientId'].toString();
    }

    if (json['senderName'] != null && json['senderName'].toString().isNotEmpty) {
      sName = json['senderName'].toString();
    }
    if (json['senderAvatar'] != null && json['senderAvatar'].toString().isNotEmpty) {
      sAvatar = json['senderAvatar'].toString();
    }

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      senderId: sId,
      recipientId: rId,
      senderName: sName,
      senderAvatar: sAvatar,
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      isMe: sId == currentUserId,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
