enum UserType { client, provider }

extension UserTypeX on UserType {
  String get value {
    switch (this) {
      case UserType.client:
        return 'client';
      case UserType.provider:
        return 'provider';
    }
  }

  String get arabicLabel {
    switch (this) {
      case UserType.client:
        return 'عميل';
      case UserType.provider:
        return 'مقدم خدمة';
    }
  }

  String get englishLabel {
    switch (this) {
      case UserType.client:
        return 'Client';
      case UserType.provider:
        return 'Service Provider';
    }
  }
}

UserType? userTypeFromValue(String? value) {
  switch (value) {
    case 'client':
      return UserType.client;
    case 'provider':
      return UserType.provider;
    default:
      return null;
  }
}

class AppUser {
  const AppUser({
    required this.userId,
    required this.phoneNumber,
    required this.createdAt,
    required this.isVerified,
    required this.isBlocked,
    this.userType,
    this.name,
    this.governorate,
    this.district,
    this.avatarUrl,
  });

  final String userId;
  final String phoneNumber;
  final DateTime createdAt;
  final UserType? userType;
  final bool isVerified;
  final bool isBlocked;
  final String? name;
  final String? governorate;
  final String? district;
  final String? avatarUrl;

  String get displayName {
    final String trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? 'مستخدم مكان' : trimmed;
  }

  bool get isProvider => userType == UserType.provider;

  bool get hasCompletedProfile {
    final String cleanedGovernorate = governorate?.trim() ?? '';
    final String cleanedDistrict = district?.trim() ?? '';
    return userType != null &&
        cleanedGovernorate.isNotEmpty &&
        cleanedDistrict.isNotEmpty;
  }

  AppUser copyWith({
    String? userId,
    String? phoneNumber,
    DateTime? createdAt,
    UserType? userType,
    bool clearUserType = false,
    bool? isVerified,
    bool? isBlocked,
    String? name,
    bool clearName = false,
    String? governorate,
    bool clearGovernorate = false,
    String? district,
    bool clearDistrict = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      userType: clearUserType ? null : (userType ?? this.userType),
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      name: clearName ? null : (name ?? this.name),
      governorate: clearGovernorate
          ? null
          : (governorate ?? this.governorate),
      district: clearDistrict ? null : (district ?? this.district),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'userType': userType?.value,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'name': name,
      'governorate': governorate,
      'district': district,
      'avatarUrl': avatarUrl,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['userId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userType: userTypeFromValue(json['userType'] as String?),
      isVerified: json['isVerified'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      name: json['name'] as String?,
      governorate: json['governorate'] as String?,
      district: json['district'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
