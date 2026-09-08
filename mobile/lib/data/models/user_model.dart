class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String activeMode;
  final double rating;
  final int reviewCount;
  final int completedTasksCount;
  final String avatarUrl;
  final bool isIdentityVerified;
  final String verificationStatus; // 'NOT_SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED'
  final Map<String, dynamic>? verificationData;
  final bool isBlocked;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.activeMode,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.completedTasksCount = 0,
    this.avatarUrl = '',
    this.isIdentityVerified = false,
    this.verificationStatus = 'NOT_SUBMITTED',
    this.verificationData,
    this.isBlocked = false,
  });

  String get fullName => '$firstName $lastName';
  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer' || role == 'both' || role == 'admin';
  bool get isTasker => role == 'tasker' || role == 'both';
  bool get isNewTasker => rating == 0.0 || reviewCount == 0;
  String get ratingDisplay => isNewTasker ? '★ New' : '★ ${rating.toStringAsFixed(1)}';

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? activeMode,
    double? rating,
    int? reviewCount,
    int? completedTasksCount,
    String? avatarUrl,
    bool? isIdentityVerified,
    String? verificationStatus,
    Map<String, dynamic>? verificationData,
    bool? isBlocked,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      activeMode: activeMode ?? this.activeMode,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationData: verificationData ?? this.verificationData,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'both',
      activeMode: json['activeMode'] ?? 'customer',
      rating: (json['rating'] != null) ? (json['rating'] as num).toDouble() : 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      completedTasksCount: json['completedTasksCount'] ?? 0,
      avatarUrl: json['avatarUrl'] ?? '',
      isIdentityVerified: json['isIdentityVerified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'NOT_SUBMITTED',
      verificationData: json['verificationData'] is Map
          ? Map<String, dynamic>.from(json['verificationData'] as Map)
          : null,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'activeMode': activeMode,
      'rating': rating,
      'reviewCount': reviewCount,
      'completedTasksCount': completedTasksCount,
      'avatarUrl': avatarUrl,
      'isIdentityVerified': isIdentityVerified,
      'verificationStatus': verificationStatus,
      'verificationData': verificationData,
      'isBlocked': isBlocked,
    };
  }
}
