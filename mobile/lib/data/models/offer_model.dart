class OfferModel {
  final String id;
  final String taskId;
  final String taskerId;
  final String taskerName;
  final String taskerAvatar;
  final double taskerRating;
  final bool isVerified;
  final int offeredAmount;
  final String note;
  final String status;

  OfferModel({
    required this.id,
    required this.taskId,
    required this.taskerId,
    required this.taskerName,
    required this.taskerAvatar,
    required this.taskerRating,
    this.isVerified = false,
    required this.offeredAmount,
    required this.note,
    required this.status,
  });

  bool get isNewTasker => taskerRating == 0.0;
  String get ratingDisplay => isNewTasker ? '★ New Tasker' : '★ ${taskerRating.toStringAsFixed(1)}';

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    String tId = '';
    String tName = 'Tasker';
    String tAvatar = '';
    double tRating = 0.0;
    bool tVerified = false;

    if (json['taskerId'] is Map) {
      final t = json['taskerId'];
      tId = t['_id'] ?? t['id'] ?? '';
      tName = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
      tAvatar = t['avatarUrl'] ?? '';
      tRating = (t['rating'] != null) ? (t['rating'] as num).toDouble() : 0.0;
      tVerified = t['isIdentityVerified'] ?? false;
    }

    return OfferModel(
      id: json['_id'] ?? json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      taskerId: tId,
      taskerName: tName.isNotEmpty ? tName : 'Tasker',
      taskerAvatar: tAvatar,
      taskerRating: tRating,
      isVerified: tVerified,
      offeredAmount: json['offeredAmount'] ?? 500,
      note: json['note'] ?? '',
      status: json['status'] ?? 'PENDING',
    );
  }
}
