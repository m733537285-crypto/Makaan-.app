enum AdStatus { active, pending, expired, rejected }

enum AdCategory {
  cars,
  realEstate,
  restaurants,
  services,
  electronics,
  groceries,
  other,
}

enum DealType {
  standard,
  todayDeal,
  halfPrice,
  limitedTime,
  discountedService,
}

AdStatus adStatusFromValue(String? value) {
  switch (value) {
    case 'active':
      return AdStatus.active;
    case 'pending':
      return AdStatus.pending;
    case 'expired':
      return AdStatus.expired;
    case 'rejected':
      return AdStatus.rejected;
    default:
      return AdStatus.active;
  }
}

AdCategory adCategoryFromValue(String? value) {
  switch (value) {
    case 'cars':
      return AdCategory.cars;
    case 'real_estate':
      return AdCategory.realEstate;
    case 'restaurants':
      return AdCategory.restaurants;
    case 'services':
      return AdCategory.services;
    case 'electronics':
      return AdCategory.electronics;
    case 'groceries':
      return AdCategory.groceries;
    case 'other':
    default:
      return AdCategory.other;
  }
}

DealType dealTypeFromValue(String? value) {
  switch (value) {
    case 'today_deal':
      return DealType.todayDeal;
    case 'half_price':
      return DealType.halfPrice;
    case 'limited_time':
      return DealType.limitedTime;
    case 'discounted_service':
      return DealType.discountedService;
    case 'standard':
    default:
      return DealType.standard;
  }
}

extension AdStatusX on AdStatus {
  String get value {
    switch (this) {
      case AdStatus.active:
        return 'active';
      case AdStatus.pending:
        return 'pending';
      case AdStatus.expired:
        return 'expired';
      case AdStatus.rejected:
        return 'rejected';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AdStatus.active:
        return 'نشط';
      case AdStatus.pending:
        return 'بانتظار المراجعة';
      case AdStatus.expired:
        return 'منتهي';
      case AdStatus.rejected:
        return 'مرفوض';
    }
  }
}

extension AdCategoryX on AdCategory {
  String get value {
    switch (this) {
      case AdCategory.cars:
        return 'cars';
      case AdCategory.realEstate:
        return 'real_estate';
      case AdCategory.restaurants:
        return 'restaurants';
      case AdCategory.services:
        return 'services';
      case AdCategory.electronics:
        return 'electronics';
      case AdCategory.groceries:
        return 'groceries';
      case AdCategory.other:
        return 'other';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AdCategory.cars:
        return 'سيارات';
      case AdCategory.realEstate:
        return 'عقارات';
      case AdCategory.restaurants:
        return 'مطاعم';
      case AdCategory.services:
        return 'خدمات';
      case AdCategory.electronics:
        return 'أجهزة إلكترونية';
      case AdCategory.groceries:
        return 'بقالات';
      case AdCategory.other:
        return 'أخرى';
    }
  }
}

extension DealTypeX on DealType {
  String get value {
    switch (this) {
      case DealType.standard:
        return 'standard';
      case DealType.todayDeal:
        return 'today_deal';
      case DealType.halfPrice:
        return 'half_price';
      case DealType.limitedTime:
        return 'limited_time';
      case DealType.discountedService:
        return 'discounted_service';
    }
  }

  String get arabicLabel {
    switch (this) {
      case DealType.standard:
        return 'إعلان عادي';
      case DealType.todayDeal:
        return 'عرض اليوم';
      case DealType.halfPrice:
        return 'نصف السعر';
      case DealType.limitedTime:
        return 'لفترة محدودة';
      case DealType.discountedService:
        return 'خدمة مخفضة';
    }
  }
}

class AdListing {
  const AdListing({
    required this.adId,
    required this.userId,
    required this.title,
    required this.description,
    required this.priceBefore,
    required this.priceAfter,
    required this.images,
    required this.category,
    required this.phoneNumber,
    required this.locationText,
    required this.createdAt,
    required this.status,
    required this.dealType,
    this.expiresAt,
    this.ownerName,
    this.isBanner = false,
    this.isFeatured = false,
  });

  final String adId;
  final String userId;
  final String title;
  final String description;
  final double priceBefore;
  final double priceAfter;
  final List<String> images;
  final AdCategory category;
  final String phoneNumber;
  final String locationText;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final AdStatus status;
  final DealType dealType;
  final String? ownerName;
  final bool isBanner;
  final bool isFeatured;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  bool get hasDiscount => priceBefore > 0 && priceAfter > 0 && priceAfter < priceBefore;

  int get discountPercent {
    if (!hasDiscount) {
      return 0;
    }
    return (((priceBefore - priceAfter) / priceBefore) * 100).round();
  }

  bool get isExpiredByTime => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isDeal =>
      dealType != DealType.standard || hasDiscount || isFeatured || isBanner;

  AdStatus get effectiveStatus {
    if (status == AdStatus.active && isExpiredByTime) {
      return AdStatus.expired;
    }
    return status;
  }

  AdListing copyWith({
    String? adId,
    String? userId,
    String? title,
    String? description,
    double? priceBefore,
    double? priceAfter,
    List<String>? images,
    AdCategory? category,
    String? phoneNumber,
    String? locationText,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    AdStatus? status,
    DealType? dealType,
    String? ownerName,
    bool clearOwnerName = false,
    bool? isBanner,
    bool? isFeatured,
  }) {
    return AdListing(
      adId: adId ?? this.adId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priceBefore: priceBefore ?? this.priceBefore,
      priceAfter: priceAfter ?? this.priceAfter,
      images: images ?? this.images,
      category: category ?? this.category,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      locationText: locationText ?? this.locationText,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      status: status ?? this.status,
      dealType: dealType ?? this.dealType,
      ownerName: clearOwnerName ? null : (ownerName ?? this.ownerName),
      isBanner: isBanner ?? this.isBanner,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'adId': adId,
      'userId': userId,
      'title': title,
      'description': description,
      'priceBefore': priceBefore,
      'priceAfter': priceAfter,
      'images': images,
      'category': category.value,
      'phoneNumber': phoneNumber,
      'locationText': locationText,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status.value,
      'dealType': dealType.value,
      'ownerName': ownerName,
      'isBanner': isBanner,
      'isFeatured': isFeatured,
    };
  }

  factory AdListing.fromJson(Map<String, dynamic> json) {
    return AdListing(
      adId: json['adId'] as String,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceBefore: (json['priceBefore'] as num?)?.toDouble() ?? 0,
      priceAfter: (json['priceAfter'] as num?)?.toDouble() ?? 0,
      images: ((json['images'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      category: adCategoryFromValue(json['category'] as String?),
      phoneNumber: json['phoneNumber'] as String? ?? '',
      locationText: json['locationText'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      status: adStatusFromValue(json['status'] as String?),
      dealType: dealTypeFromValue(json['dealType'] as String?),
      ownerName: json['ownerName'] as String?,
      isBanner: json['isBanner'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }
}
