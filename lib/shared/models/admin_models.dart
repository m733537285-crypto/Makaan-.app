import 'app_user.dart';
import 'provider_models.dart';
import 'ad_models.dart';
import 'order_models.dart';

enum AdminRole { superAdmin, contentManager, subscriptionsManager, supportManager }

enum AdminReportStatus { pending, accepted, rejected }

AdminRole adminRoleFromValue(String? value) {
  switch (value) {
    case 'content_manager':
      return AdminRole.contentManager;
    case 'subscriptions_manager':
      return AdminRole.subscriptionsManager;
    case 'support_manager':
      return AdminRole.supportManager;
    case 'super_admin':
    default:
      return AdminRole.superAdmin;
  }
}

AdminReportStatus adminReportStatusFromValue(String? value) {
  switch (value) {
    case 'accepted':
      return AdminReportStatus.accepted;
    case 'rejected':
      return AdminReportStatus.rejected;
    case 'pending':
    default:
      return AdminReportStatus.pending;
  }
}

extension AdminRoleX on AdminRole {
  String get value {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.contentManager:
        return 'content_manager';
      case AdminRole.subscriptionsManager:
        return 'subscriptions_manager';
      case AdminRole.supportManager:
        return 'support_manager';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AdminRole.superAdmin:
        return 'مدير رئيسي';
      case AdminRole.contentManager:
        return 'مدير محتوى';
      case AdminRole.subscriptionsManager:
        return 'مدير اشتراكات';
      case AdminRole.supportManager:
        return 'مدير دعم';
    }
  }
}

extension AdminReportStatusX on AdminReportStatus {
  String get value {
    switch (this) {
      case AdminReportStatus.pending:
        return 'pending';
      case AdminReportStatus.accepted:
        return 'accepted';
      case AdminReportStatus.rejected:
        return 'rejected';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AdminReportStatus.pending:
        return 'قيد المراجعة';
      case AdminReportStatus.accepted:
        return 'مقبول';
      case AdminReportStatus.rejected:
        return 'مرفوض';
    }
  }
}

class AdminSystemLog {
  const AdminSystemLog({
    required this.logId,
    required this.actorName,
    required this.role,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.createdAt,
  });

  final String logId;
  final String actorName;
  final AdminRole role;
  final String action;
  final String targetType;
  final String targetId;
  final String details;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'logId': logId,
      'actorName': actorName,
      'role': role.value,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdminSystemLog.fromJson(Map<String, dynamic> json) {
    return AdminSystemLog(
      logId: json['logId'] as String,
      actorName: json['actorName'] as String? ?? 'مدير النظام',
      role: adminRoleFromValue(json['role'] as String?),
      action: json['action'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      details: json['details'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminReportTicket {
  const AdminReportTicket({
    required this.reportId,
    required this.reporterName,
    required this.reportedName,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.actionNote,
  });

  final String reportId;
  final String reporterName;
  final String reportedName;
  final String targetType;
  final String targetId;
  final String reason;
  final AdminReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? actionNote;

  AdminReportTicket copyWith({
    String? reportId,
    String? reporterName,
    String? reportedName,
    String? targetType,
    String? targetId,
    String? reason,
    AdminReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
    String? actionNote,
    bool clearActionNote = false,
  }) {
    return AdminReportTicket(
      reportId: reportId ?? this.reportId,
      reporterName: reporterName ?? this.reporterName,
      reportedName: reportedName ?? this.reportedName,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      actionNote: clearActionNote ? null : (actionNote ?? this.actionNote),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reportId': reportId,
      'reporterName': reporterName,
      'reportedName': reportedName,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'actionNote': actionNote,
    };
  }

  factory AdminReportTicket.fromJson(Map<String, dynamic> json) {
    return AdminReportTicket(
      reportId: json['reportId'] as String,
      reporterName: json['reporterName'] as String? ?? 'مستخدم',
      reportedName: json['reportedName'] as String? ?? 'حساب',
      targetType: json['targetType'] as String? ?? 'user',
      targetId: json['targetId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: adminReportStatusFromValue(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'] as String),
      actionNote: json['actionNote'] as String?,
    );
  }
}

class AdminManagedLocation {
  const AdminManagedLocation({required this.governorate, required this.districts});

  final String governorate;
  final List<String> districts;

  AdminManagedLocation copyWith({String? governorate, List<String>? districts}) {
    return AdminManagedLocation(
      governorate: governorate ?? this.governorate,
      districts: districts ?? this.districts,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'governorate': governorate,
      'districts': districts,
    };
  }

  factory AdminManagedLocation.fromJson(Map<String, dynamic> json) {
    return AdminManagedLocation(
      governorate: json['governorate'] as String? ?? '',
      districts: ((json['districts'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }
}

class AdminManagedCategory {
  const AdminManagedCategory({
    required this.categoryId,
    required this.title,
    required this.emoji,
    required this.services,
    this.isActive = true,
  });

  final String categoryId;
  final String title;
  final String emoji;
  final List<String> services;
  final bool isActive;

  AdminManagedCategory copyWith({
    String? categoryId,
    String? title,
    String? emoji,
    List<String>? services,
    bool? isActive,
  }) {
    return AdminManagedCategory(
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      services: services ?? this.services,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'categoryId': categoryId,
      'title': title,
      'emoji': emoji,
      'services': services,
      'isActive': isActive,
    };
  }

  factory AdminManagedCategory.fromJson(Map<String, dynamic> json) {
    return AdminManagedCategory(
      categoryId: json['categoryId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📦',
      services: ((json['services'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalUsers,
    required this.totalProviders,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.activeAds,
    required this.expiredAds,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.reportsCount,
    required this.reviewsCount,
    required this.mostRequestedServices,
  });

  final int totalUsers;
  final int totalProviders;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int activeAds;
  final int expiredAds;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final int reportsCount;
  final int reviewsCount;
  final List<String> mostRequestedServices;
}

class AdminExportBundle {
  const AdminExportBundle({required this.fileName, required this.csvContent});

  final String fileName;
  final String csvContent;
}
