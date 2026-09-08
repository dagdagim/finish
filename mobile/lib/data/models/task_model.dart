class TaskLocation {
  final String address;
  final String instructions;
  final List<double> coordinates;

  TaskLocation({
    required this.address,
    this.instructions = '',
    this.coordinates = const [38.7891, 8.9953],
  });

  factory TaskLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TaskLocation(address: 'Addis Ababa');
    }
    List<double> coords = [38.7891, 8.9953];
    if (json['coordinates'] is List && (json['coordinates'] as List).length >= 2) {
      coords = (json['coordinates'] as List).map((e) => (e as num).toDouble()).toList();
    }
    return TaskLocation(
      address: json['address'] ?? 'Addis Ababa',
      instructions: json['instructions'] ?? '',
      coordinates: coords,
    );
  }
}

class TaskPricing {
  final int budget;
  final String currency;
  final String pricingType;
  final int suggestedPrice;
  final int platformFee;

  TaskPricing({
    required this.budget,
    this.currency = 'ETB',
    this.pricingType = 'fixed',
    required this.suggestedPrice,
    this.platformFee = 50,
  });

  factory TaskPricing.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TaskPricing(budget: 450, suggestedPrice: 450);
    }
    return TaskPricing(
      budget: json['budget'] ?? 450,
      currency: json['currency'] ?? 'ETB',
      pricingType: json['pricingType'] ?? 'fixed',
      suggestedPrice: json['suggestedPrice'] ?? 450,
      platformFee: json['platformFee'] ?? 50,
    );
  }
}

class AdminTaskRating {
  final int taskerRating;
  final String? taskerReview;
  final int customerRating;
  final String? customerReview;
  final DateTime? ratedAt;

  AdminTaskRating({
    required this.taskerRating,
    this.taskerReview,
    required this.customerRating,
    this.customerReview,
    this.ratedAt,
  });

  factory AdminTaskRating.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdminTaskRating(taskerRating: 5, customerRating: 5);
    return AdminTaskRating(
      taskerRating: json['taskerRating'] is num ? (json['taskerRating'] as num).toInt() : 5,
      taskerReview: json['taskerReview']?.toString(),
      customerRating: json['customerRating'] is num ? (json['customerRating'] as num).toInt() : 5,
      customerReview: json['customerReview']?.toString(),
      ratedAt: json['ratedAt'] != null ? DateTime.tryParse(json['ratedAt'].toString()) : null,
    );
  }
}

class CustomerTaskRating {
  final int rating;
  final String? review;
  final List<String> tags;
  final double tipAmount;
  final DateTime? ratedAt;

  CustomerTaskRating({
    required this.rating,
    this.review,
    this.tags = const [],
    this.tipAmount = 0,
    this.ratedAt,
  });

  factory CustomerTaskRating.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CustomerTaskRating(rating: 5);
    return CustomerTaskRating(
      rating: json['rating'] is num ? (json['rating'] as num).toInt() : 5,
      review: json['review']?.toString() ?? json['comment']?.toString(),
      tags: (json['tags'] is List) ? (json['tags'] as List).map((e) => e.toString()).toList() : [],
      tipAmount: json['tipAmount'] is num ? (json['tipAmount'] as num).toDouble() : 0,
      ratedAt: json['ratedAt'] != null ? DateTime.tryParse(json['ratedAt'].toString()) : null,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final int quantity;
  final String specialInstructions;
  final List<String> mediaUrls;
  final TaskLocation pickupLocation;
  final TaskLocation? dropoffLocation;
  final String scheduleText;
  final TaskPricing pricing;
  final String status;
  final double distanceKm;
  final int estimatedDurationMin;
  final int offersCount;
  final String customerId;
  final String customerName;
  final String customerAvatar;
  final double customerRating;
  final int customerReviewCount;
  final String? assignedTaskerId;
  final String? assignedTaskerName;
  final String? assignedTaskerAvatar;
  final List<String> proofPhotos;
  final String? proofNotes;
  final AdminTaskRating? adminRatings;
  final CustomerTaskRating? customerRatingToTasker;
  final DateTime? startedAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.quantity = 1,
    this.specialInstructions = '',
    this.mediaUrls = const [],
    required this.pickupLocation,
    this.dropoffLocation,
    this.scheduleText = 'Today · Before 5 PM',
    required this.pricing,
    required this.status,
    this.distanceKm = 2.4,
    this.estimatedDurationMin = 35,
    this.offersCount = 0,
    this.customerId = 'customer_sarah',
    this.customerName = 'Customer',
    this.customerAvatar = '',
    this.customerRating = 4.9,
    this.customerReviewCount = 12,
    this.assignedTaskerId,
    this.assignedTaskerName,
    this.assignedTaskerAvatar,
    this.proofPhotos = const [],
    this.proofNotes,
    this.adminRatings,
    this.customerRatingToTasker,
    this.startedAt,
    this.completedAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    int? quantity,
    String? specialInstructions,
    List<String>? mediaUrls,
    TaskLocation? pickupLocation,
    TaskLocation? dropoffLocation,
    String? scheduleText,
    TaskPricing? pricing,
    String? status,
    double? distanceKm,
    int? estimatedDurationMin,
    int? offersCount,
    String? customerId,
    String? customerName,
    String? customerAvatar,
    double? customerRating,
    int? customerReviewCount,
    String? assignedTaskerId,
    String? assignedTaskerName,
    String? assignedTaskerAvatar,
    List<String>? proofPhotos,
    String? proofNotes,
    AdminTaskRating? adminRatings,
    CustomerTaskRating? customerRatingToTasker,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      scheduleText: scheduleText ?? this.scheduleText,
      pricing: pricing ?? this.pricing,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      offersCount: offersCount ?? this.offersCount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      customerRating: customerRating ?? this.customerRating,
      customerReviewCount: customerReviewCount ?? this.customerReviewCount,
      assignedTaskerId: assignedTaskerId ?? this.assignedTaskerId,
      assignedTaskerName: assignedTaskerName ?? this.assignedTaskerName,
      assignedTaskerAvatar: assignedTaskerAvatar ?? this.assignedTaskerAvatar,
      proofPhotos: proofPhotos ?? this.proofPhotos,
      proofNotes: proofNotes ?? this.proofNotes,
      adminRatings: adminRatings ?? this.adminRatings,
      customerRatingToTasker: customerRatingToTasker ?? this.customerRatingToTasker,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get routeDisplay {
    if (dropoffLocation != null && dropoffLocation!.address.isNotEmpty) {
      final p = pickupLocation.address.split(',').first.trim();
      final d = dropoffLocation!.address.split(',').first.trim();
      return '$p → $d';
    }
    return pickupLocation.address;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    String custId = 'customer_sarah';
    String custName = 'Sarah M.';
    String custAvatar = '';
    double custRating = 4.9;
    int custReviews = 12;

    if (json['customerId'] is Map) {
      final c = json['customerId'];
      custId = c['_id'] ?? c['id'] ?? 'customer_sarah';
      custName = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
      custAvatar = c['avatarUrl'] ?? '';
      custRating = (c['rating'] != null) ? (c['rating'] as num).toDouble() : 4.9;
      custReviews = c['reviewCount'] ?? 12;
    } else if (json['customerId'] != null) {
      custId = json['customerId'].toString();
    }

    String? taskerId;
    String? taskerName;
    String? taskerAvatar;
    if (json['assignedTaskerId'] is Map) {
      final t = json['assignedTaskerId'];
      taskerId = t['_id'] ?? t['id'];
      taskerName = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
      taskerAvatar = t['avatarUrl'];
    } else if (json['assignedTaskerId'] != null) {
      taskerId = json['assignedTaskerId'].toString();
    }
    if (taskerName == null || taskerName.isEmpty) {
      taskerName = json['assignedTaskerName']?.toString();
    }

    List<String> proofPics = [];
    String? proofNotesText;
    if (json['proofOfWork'] is Map) {
      if (json['proofOfWork']['photos'] is List) {
        proofPics = (json['proofOfWork']['photos'] as List).map((e) => e.toString()).toList();
      }
      proofNotesText = json['proofOfWork']['notes'];
    }

    AdminTaskRating? adminRatingObj;
    if (json['adminRatings'] is Map) {
      adminRatingObj = AdminTaskRating.fromJson(Map<String, dynamic>.from(json['adminRatings']));
    }

    CustomerTaskRating? customerRatingObj;
    if (json['customerRatingToTasker'] is Map) {
      customerRatingObj = CustomerTaskRating.fromJson(Map<String, dynamic>.from(json['customerRatingToTasker']));
    } else if (json['rating'] is Map) {
      customerRatingObj = CustomerTaskRating.fromJson(Map<String, dynamic>.from(json['rating']));
    }

    DateTime? startedDate;
    if (json['startedAt'] != null) {
      startedDate = DateTime.tryParse(json['startedAt'].toString());
    } else if (json['workStartedAt'] != null) {
      startedDate = DateTime.tryParse(json['workStartedAt'].toString());
    }

    DateTime? completedDate;
    if (json['completedAt'] != null) {
      completedDate = DateTime.tryParse(json['completedAt'].toString());
    }

    return TaskModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Task',
      category: json['category'] ?? 'delivery',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      specialInstructions: json['specialInstructions'] ?? '',
      mediaUrls: (json['mediaUrls'] is List)
          ? (json['mediaUrls'] as List).map((e) => e.toString()).toList()
          : [],
      pickupLocation: TaskLocation.fromJson(json['pickupLocation']),
      dropoffLocation: json['dropoffLocation'] != null
          ? TaskLocation.fromJson(json['dropoffLocation'])
          : null,
      scheduleText: json['schedule']?['windowText'] ?? 'Today · Before 5 PM',
      pricing: TaskPricing.fromJson(json['pricing']),
      status: json['status'] ?? 'OPEN',
      distanceKm: (json['distanceKm'] != null) ? (json['distanceKm'] as num).toDouble() : 2.4,
      estimatedDurationMin: json['estimatedDurationMin'] ?? 35,
      offersCount: json['offersCount'] ?? 0,
      customerId: custId,
      customerName: custName.isNotEmpty ? custName : 'Customer',
      customerAvatar: custAvatar,
      customerRating: custRating,
      customerReviewCount: custReviews,
      assignedTaskerId: taskerId,
      assignedTaskerName: taskerName,
      assignedTaskerAvatar: taskerAvatar,
      proofPhotos: proofPics,
      proofNotes: proofNotesText,
      adminRatings: adminRatingObj,
      customerRatingToTasker: customerRatingObj,
      startedAt: startedDate,
      completedAt: completedDate,
    );
  }
}
