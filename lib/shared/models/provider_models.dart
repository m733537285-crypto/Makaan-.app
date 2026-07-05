enum ProviderAccountStatus { active, pending, suspended, expired }

enum SubscriptionStatus { active, pending, expired }

enum PaymentStatus { paid, pending, unpaid }

ProviderAccountStatus providerAccountStatusFromValue(String? value) {
  switch (value) {
    case 'active':
      return ProviderAccountStatus.active;
    case 'suspended':
      return ProviderAccountStatus.suspended;
    case 'expired':
      return ProviderAccountStatus.expired;
    case 'pending':
    default:
      return ProviderAccountStatus.pending;
  }
}

SubscriptionStatus subscriptionStatusFromValue(String? value) {
  switch (value) {
    case 'active':
      return SubscriptionStatus.active;
    case 'expired':
      return SubscriptionStatus.expired;
    case 'pending':
    default:
      return SubscriptionStatus.pending;
  }
}

PaymentStatus paymentStatusFromValue(String? value) {
  switch (value) {
    case 'paid':
      return PaymentStatus.paid;
    case 'pending':
      return PaymentStatus.pending;
    case 'unpaid':
    default:
      return PaymentStatus.unpaid;
  }
}

extension ProviderAccountStatusX on ProviderAccountStatus {
  String get value {
    switch (this) {
      case ProviderAccountStatus.active:
        return 'active';
      case ProviderAccountStatus.pending:
        return 'pending';
      case ProviderAccountStatus.suspended:
        return 'suspended';
      case ProviderAccountStatus.expired:
        return 'expired';
    }
  }

  String get arabicLabel {
    switch (this) {
      case ProviderAccountStatus.active:
        return 'نشط';
      case ProviderAccountStatus.pending:
        return 'بانتظار التفعيل';
      case ProviderAccountStatus.suspended:
        return 'موقوف';
      case ProviderAccountStatus.expired:
        return 'منتهي';
    }
  }
}

extension SubscriptionStatusX on SubscriptionStatus {
  String get value {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.pending:
        return 'pending';
      case SubscriptionStatus.expired:
        return 'expired';
    }
  }

  String get arabicLabel {
    switch (this) {
      case SubscriptionStatus.active:
        return 'نشط';
      case SubscriptionStatus.pending:
        return 'قيد المراجعة';
      case SubscriptionStatus.expired:
        return 'منتهي';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.unpaid:
        return 'unpaid';
    }
  }

  String get arabicLabel {
    switch (this) {
      case PaymentStatus.paid:
        return 'مدفوع';
      case PaymentStatus.pending:
        return 'بانتظار الدفع';
      case PaymentStatus.unpaid:
        return 'غير مدفوع';
    }
  }
}

class ProviderProfile {
  const ProviderProfile({
    required this.providerId,
    required this.userId,
    required this.businessName,
    required this.phoneNumber,
    required this.description,
    required this.mainServiceType,
    required this.governorate,
    required this.district,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl,
    this.logoImageUrl,
    this.workingHours,
    this.whatsAppNumber,
    this.customerCount = 0,
  });

  final String providerId;
  final String userId;
  final String businessName;
  final String phoneNumber;
  final String description;
  final String mainServiceType;
  final String governorate;
  final String district;
  final ProviderAccountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImageUrl;
  final String? logoImageUrl;
  final String? workingHours;
  final String? whatsAppNumber;
  final int customerCount;

  ProviderProfile copyWith({
    String? providerId,
    String? userId,
    String? businessName,
    String? phoneNumber,
    String? description,
    String? mainServiceType,
    String? governorate,
    String? district,
    ProviderAccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    String? logoImageUrl,
    bool clearLogoImageUrl = false,
    String? workingHours,
    bool clearWorkingHours = false,
    String? whatsAppNumber,
    bool clearWhatsAppNumber = false,
    int? customerCount,
  }) {
    return ProviderProfile(
      providerId: providerId ?? this.providerId,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      mainServiceType: mainServiceType ?? this.mainServiceType,
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImageUrl: clearCoverImageUrl ? null : (coverImageUrl ?? this.coverImageUrl),
      logoImageUrl: clearLogoImageUrl ? null : (logoImageUrl ?? this.logoImageUrl),
      workingHours: clearWorkingHours ? null : (workingHours ?? this.workingHours),
      whatsAppNumber: clearWhatsAppNumber ? null : (whatsAppNumber ?? this.whatsAppNumber),
      customerCount: customerCount ?? this.customerCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'providerId': providerId,
      'userId': userId,
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'description': description,
      'mainServiceType': mainServiceType,
      'governorate': governorate,
      'district': district,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'logoImageUrl': logoImageUrl,
      'workingHours': workingHours,
      'whatsAppNumber': whatsAppNumber,
      'customerCount': customerCount,
    };
  }

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      providerId: json['providerId'] as String,
      userId: json['userId'] as String,
      businessName: json['businessName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainServiceType: json['mainServiceType'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      district: json['district'] as String? ?? '',
      status: providerAccountStatusFromValue(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      coverImageUrl: json['coverImageUrl'] as String?,
      logoImageUrl: json['logoImageUrl'] as String?,
      workingHours: json['workingHours'] as String?,
      whatsAppNumber: json['whatsAppNumber'] as String?,
      customerCount: json['customerCount'] as int? ?? 0,
    );
  }
}

class ProviderService {
  const ProviderService({
    required this.serviceId,
    required this.providerId,
    required this.title,
    required this.description,
    this.approximatePrice,
    this.isPrimary = false,
  });

  final String serviceId;
  final String providerId;
  final String title;
  final String description;
  final double? approximatePrice;
  final bool isPrimary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'serviceId': serviceId,
      'providerId': providerId,
      'title': title,
      'description': description,
      'approximatePrice': approximatePrice,
      'isPrimary': isPrimary,
    };
  }

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    return ProviderService(
      serviceId: json['serviceId'] as String,
      providerId: json['providerId'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      approximatePrice: (json['approximatePrice'] as num?)?.toDouble(),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class ProviderGalleryItem {
  const ProviderGalleryItem({
    required this.imageId,
    required this.providerId,
    required this.caption,
    required this.category,
    this.imageUrl,
  });

  final String imageId;
  final String providerId;
  final String caption;
  final String category;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'imageId': imageId,
      'providerId': providerId,
      'caption': caption,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  factory ProviderGalleryItem.fromJson(Map<String, dynamic> json) {
    return ProviderGalleryItem(
      imageId: json['imageId'] as String,
      providerId: json['providerId'] as String,
      caption: json['caption'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class ProviderServiceArea {
  const ProviderServiceArea({
    required this.areaId,
    required this.providerId,
    required this.governorate,
    required this.district,
    this.neighborhood,
  });

  final String areaId;
  final String providerId;
  final String governorate;
  final String district;
  final String? neighborhood;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'areaId': areaId,
      'providerId': providerId,
      'governorate': governorate,
      'district': district,
      'neighborhood': neighborhood,
    };
  }

  factory ProviderServiceArea.fromJson(Map<String, dynamic> json) {
    return ProviderServiceArea(
      areaId: json['areaId'] as String,
      providerId: json['providerId'] as String,
      governorate: json['governorate'] as String? ?? '',
      district: json['district'] as String? ?? '',
      neighborhood: json['neighborhood'] as String?,
    );
  }
}

class ProviderSubscription {
  const ProviderSubscription({
    required this.subscriptionId,
    required this.providerId,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentStatus,
  });

  final String subscriptionId;
  final String providerId;
  final String planType;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final PaymentStatus paymentStatus;

  bool get isActive =>
      status == SubscriptionStatus.active &&
      paymentStatus == PaymentStatus.paid &&
      endDate.isAfter(DateTime.now());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subscriptionId': subscriptionId,
      'providerId': providerId,
      'planType': planType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.value,
      'paymentStatus': paymentStatus.value,
    };
  }

  factory ProviderSubscription.fromJson(Map<String, dynamic> json) {
    return ProviderSubscription(
      subscriptionId: json['subscriptionId'] as String,
      providerId: json['providerId'] as String,
      planType: json['planType'] as String? ?? 'Basic',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: subscriptionStatusFromValue(json['status'] as String?),
      paymentStatus: paymentStatusFromValue(json['paymentStatus'] as String?),
    );
  }
}

class ProviderReview {
  const ProviderReview({
    required this.reviewId,
    required this.providerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String reviewId;
  final String providerId;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reviewId': reviewId,
      'providerId': providerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProviderReview.fromJson(Map<String, dynamic> json) {
    return ProviderReview(
      reviewId: json['reviewId'] as String,
      providerId: json['providerId'] as String,
      customerName: json['customerName'] as String? ?? 'عميل',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ProviderDetails {
  const ProviderDetails({
    required this.profile,
    required this.services,
    required this.gallery,
    required this.serviceAreas,
    required this.reviews,
    this.subscription,
  });

  final ProviderProfile profile;
  final List<ProviderService> services;
  final List<ProviderGalleryItem> gallery;
  final List<ProviderServiceArea> serviceAreas;
  final List<ProviderReview> reviews;
  final ProviderSubscription? subscription;

  double get averageRating {
    if (reviews.isEmpty) {
      return 0;
    }
    final int total = reviews.fold<int>(0, (int sum, ProviderReview item) => sum + item.rating);
    return total / reviews.length;
  }

  int get reviewCount => reviews.length;

  List<ProviderReview> get latestReviews {
    final List<ProviderReview> sorted = List<ProviderReview>.from(reviews);
    sorted.sort((ProviderReview a, ProviderReview b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  bool get isVisibleInApp =>
      profile.status == ProviderAccountStatus.active &&
      (subscription?.isActive ?? false);
}
