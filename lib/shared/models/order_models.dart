enum OrderStatus { pending, accepted, rejected, onTheWay, completed, cancelled }

enum NotificationType {
  orderCreated,
  orderAccepted,
  orderRejected,
  orderStatusChanged,
  orderCancelled,
  general,
}

OrderStatus orderStatusFromValue(String? value) {
  switch (value) {
    case 'accepted':
      return OrderStatus.accepted;
    case 'rejected':
      return OrderStatus.rejected;
    case 'on_the_way':
      return OrderStatus.onTheWay;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

NotificationType notificationTypeFromValue(String? value) {
  switch (value) {
    case 'order_created':
      return NotificationType.orderCreated;
    case 'order_accepted':
      return NotificationType.orderAccepted;
    case 'order_rejected':
      return NotificationType.orderRejected;
    case 'order_status_changed':
      return NotificationType.orderStatusChanged;
    case 'order_cancelled':
      return NotificationType.orderCancelled;
    case 'general':
    default:
      return NotificationType.general;
  }
}

extension OrderStatusX on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.rejected:
        return 'rejected';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get arabicLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.accepted:
        return 'تم القبول';
      case OrderStatus.rejected:
        return 'مرفوض';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.completed:
        return 'تم الإنجاز';
      case OrderStatus.cancelled:
        return 'تم الإلغاء';
    }
  }

  bool get isClosed =>
      this == OrderStatus.rejected ||
      this == OrderStatus.completed ||
      this == OrderStatus.cancelled;
}

extension NotificationTypeX on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.orderCreated:
        return 'order_created';
      case NotificationType.orderAccepted:
        return 'order_accepted';
      case NotificationType.orderRejected:
        return 'order_rejected';
      case NotificationType.orderStatusChanged:
        return 'order_status_changed';
      case NotificationType.orderCancelled:
        return 'order_cancelled';
      case NotificationType.general:
        return 'general';
    }
  }
}

class OrderLocation {
  const OrderLocation({
    required this.governorate,
    required this.district,
    required this.neighborhood,
    required this.landmark,
  });

  final String governorate;
  final String district;
  final String neighborhood;
  final String landmark;

  String get text {
    final List<String> segments = <String>[
      governorate.trim(),
      district.trim(),
      neighborhood.trim(),
      landmark.trim(),
    ].where((String item) => item.isNotEmpty).toList(growable: false);
    return segments.join(' - ');
  }

  OrderLocation copyWith({
    String? governorate,
    String? district,
    String? neighborhood,
    String? landmark,
  }) {
    return OrderLocation(
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      landmark: landmark ?? this.landmark,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'governorate': governorate,
      'district': district,
      'neighborhood': neighborhood,
      'landmark': landmark,
    };
  }

  factory OrderLocation.fromJson(Map<String, dynamic> json) {
    return OrderLocation(
      governorate: json['governorate'] as String? ?? '',
      district: json['district'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
    );
  }
}

class ServiceOrder {
  const ServiceOrder({
    required this.orderId,
    required this.userId,
    required this.serviceType,
    required this.description,
    required this.location,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.targetedProviderIds = const <String>[],
    this.rejectedProviderIds = const <String>[],
    this.acceptedProviderId,
  });

  final String orderId;
  final String userId;
  final String serviceType;
  final String description;
  final OrderLocation location;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderStatus status;
  final List<String> targetedProviderIds;
  final List<String> rejectedProviderIds;
  final String? acceptedProviderId;

  String get locationText => location.text;

  bool get canClientCancel => status == OrderStatus.pending && acceptedProviderId == null;

  bool get hasAssignedProvider => acceptedProviderId != null && acceptedProviderId!.trim().isNotEmpty;

  bool matchesProviderInbox(String providerId) {
    if (!targetedProviderIds.contains(providerId)) {
      return false;
    }
    if (acceptedProviderId == providerId) {
      return status == OrderStatus.accepted || status == OrderStatus.onTheWay;
    }
    return status == OrderStatus.pending && !rejectedProviderIds.contains(providerId);
  }

  bool belongsToProviderHistory(String providerId) {
    return acceptedProviderId == providerId || rejectedProviderIds.contains(providerId);
  }

  ServiceOrder copyWith({
    String? orderId,
    String? userId,
    String? serviceType,
    String? description,
    OrderLocation? location,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrderStatus? status,
    List<String>? targetedProviderIds,
    List<String>? rejectedProviderIds,
    String? acceptedProviderId,
    bool clearAcceptedProviderId = false,
  }) {
    return ServiceOrder(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      targetedProviderIds: targetedProviderIds ?? this.targetedProviderIds,
      rejectedProviderIds: rejectedProviderIds ?? this.rejectedProviderIds,
      acceptedProviderId: clearAcceptedProviderId
          ? null
          : (acceptedProviderId ?? this.acceptedProviderId),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'userId': userId,
      'serviceType': serviceType,
      'description': description,
      'location': location.toJson(),
      'locationText': locationText,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.value,
      'targetedProviderIds': targetedProviderIds,
      'rejectedProviderIds': rejectedProviderIds,
      'acceptedProviderId': acceptedProviderId,
    };
  }

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      serviceType: json['serviceType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: OrderLocation.fromJson(
        (json['location'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      phoneNumber: json['phoneNumber'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? (json['createdAt'] as String),
      ),
      status: orderStatusFromValue(json['status'] as String?),
      targetedProviderIds: ((json['targetedProviderIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      rejectedProviderIds: ((json['rejectedProviderIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      acceptedProviderId: json['acceptedProviderId'] as String?,
    );
  }
}

class InAppNotification {
  const InAppNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.orderId,
    this.isRead = false,
  });

  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;
  final String? orderId;
  final bool isRead;

  InAppNotification copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? body,
    DateTime? createdAt,
    NotificationType? type,
    String? orderId,
    bool clearOrderId = false,
    bool? isRead,
  }) {
    return InAppNotification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'type': type.value,
      'orderId': orderId,
      'isRead': isRead,
    };
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      notificationId: json['notificationId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: notificationTypeFromValue(json['type'] as String?),
      orderId: json['orderId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
