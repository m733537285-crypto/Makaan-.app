import '../../../features/auth/data/auth_repository.dart';
import '../../../features/providers/data/provider_repository.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/order_models.dart';
import '../../../shared/models/provider_models.dart';
import '../../../shared/services/app_storage_service.dart';

class OrderCreationResult {
  const OrderCreationResult({required this.order, required this.matchedProvidersCount});

  final ServiceOrder order;
  final int matchedProvidersCount;
}

class OrderRepository {
  OrderRepository(this._storage, this._providerRepository);

  final AppStorageService _storage;
  final ProviderRepository _providerRepository;

  static const List<String> defaultServiceTypes = <String>[
    'سباكة',
    'كهرباء',
    'نجارة',
    'تكييف',
    'تنظيف',
    'دهان',
    'صيانة عامة',
    'نقل',
  ];

  List<ServiceOrder> getOrdersForClient(String userId) {
    final List<ServiceOrder> items = _storage
        .loadOrders()
        .where((ServiceOrder item) => item.userId == userId)
        .toList(growable: false);
    return _sortOrders(items);
  }

  List<ServiceOrder> getPendingInboxOrdersForProvider(String providerId) {
    final List<ServiceOrder> items = _storage
        .loadOrders()
        .where((ServiceOrder item) =>
            item.status == OrderStatus.pending &&
            item.targetedProviderIds.contains(providerId) &&
            !item.rejectedProviderIds.contains(providerId))
        .toList(growable: false);
    return _sortOrders(items);
  }

  List<ServiceOrder> getActiveOrdersForProvider(String providerId) {
    final List<ServiceOrder> items = _storage
        .loadOrders()
        .where((ServiceOrder item) =>
            item.acceptedProviderId == providerId &&
            (item.status == OrderStatus.accepted || item.status == OrderStatus.onTheWay))
        .toList(growable: false);
    return _sortOrders(items);
  }

  List<ServiceOrder> getCompletedOrdersForProvider(String providerId) {
    final List<ServiceOrder> items = _storage
        .loadOrders()
        .where((ServiceOrder item) =>
            item.acceptedProviderId == providerId && item.status == OrderStatus.completed)
        .toList(growable: false);
    return _sortOrders(items);
  }

  List<ServiceOrder> getRejectedOrdersForProvider(String providerId) {
    final List<ServiceOrder> items = _storage
        .loadOrders()
        .where((ServiceOrder item) => item.rejectedProviderIds.contains(providerId))
        .toList(growable: false);
    return _sortOrders(items);
  }

  List<InAppNotification> getNotificationsForUser(String userId) {
    final List<InAppNotification> notifications = _storage
        .loadNotifications()
        .where((InAppNotification item) => item.userId == userId)
        .toList(growable: false);
    notifications.sort(
      (InAppNotification a, InAppNotification b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    return notifications;
  }

  List<String> getAvailableServiceTypes() {
    final Set<String> types = <String>{...defaultServiceTypes};
    for (final ProviderDetails details in _providerRepository.getAllProviderDetails()) {
      final String mainType = details.profile.mainServiceType.trim();
      if (mainType.isNotEmpty) {
        types.add(mainType);
      }
      for (final ProviderService service in details.services) {
        final String title = service.title.trim();
        if (title.isNotEmpty) {
          types.add(title);
        }
      }
    }
    final List<String> result = types.toList(growable: false);
    result.sort((String a, String b) => a.compareTo(b));
    return result;
  }

  AppUser? getUserById(String userId) {
    for (final AppUser user in _storage.loadUsers()) {
      if (user.userId == userId) {
        return user;
      }
    }
    return null;
  }

  ProviderDetails? getProviderById(String providerId) {
    return _providerRepository.getProviderDetailsByProviderId(providerId);
  }

  Future<OrderCreationResult> createOrder({
    required AppUser user,
    required String serviceType,
    required String description,
    required OrderLocation location,
    required String phoneNumber,
  }) async {
    final String cleanedPhone = _normalizePhone(phoneNumber);
    if (!_isValidPhone(cleanedPhone)) {
      throw const AuthException('رقم الهاتف غير صحيح. استخدم أرقاماً فقط بطول من 9 إلى 15 رقم.');
    }
    final String cleanedServiceType = serviceType.trim();
    final String cleanedDescription = description.trim();
    if (cleanedServiceType.isEmpty) {
      throw const AuthException('اختر نوع الخدمة أولاً.');
    }
    if (cleanedDescription.length < 10) {
      throw const AuthException('اكتب وصفاً أوضح للطلب بما لا يقل عن 10 أحرف.');
    }
    if (location.governorate.trim().isEmpty ||
        location.district.trim().isEmpty ||
        location.neighborhood.trim().isEmpty ||
        location.landmark.trim().isEmpty) {
      throw const AuthException('أكمل بيانات الموقع النصي بالكامل.');
    }

    final DateTime now = DateTime.now();
    final List<ProviderDetails> matchingProviders = _findMatchingProviders(
      serviceType: cleanedServiceType,
      location: location,
    );
    final ServiceOrder order = ServiceOrder(
      orderId: _generateId('order'),
      userId: user.userId,
      serviceType: cleanedServiceType,
      description: cleanedDescription,
      location: location,
      phoneNumber: cleanedPhone,
      createdAt: now,
      updatedAt: now,
      status: OrderStatus.pending,
      targetedProviderIds: matchingProviders
          .map((ProviderDetails item) => item.profile.providerId)
          .toList(growable: false),
    );

    final List<ServiceOrder> orders = _storage.loadOrders().toList(growable: true);
    orders.add(order);
    await _storage.saveOrders(orders);

    final List<InAppNotification> notifications = _storage
        .loadNotifications()
        .toList(growable: true);
    notifications.add(
      InAppNotification(
        notificationId: _generateId('notification'),
        userId: user.userId,
        title: 'تم إنشاء الطلب',
        body: matchingProviders.isEmpty
            ? 'تم حفظ طلب ${order.serviceType}، وسيظهر لمقدمين مناسبين عند توفرهم.'
            : 'تم إرسال طلب ${order.serviceType} إلى ${matchingProviders.length} مقدم خدمة مناسب.',
        createdAt: now,
        type: NotificationType.orderCreated,
        orderId: order.orderId,
      ),
    );

    for (final ProviderDetails provider in matchingProviders) {
      notifications.add(
        InAppNotification(
          notificationId: _generateId('notification'),
          userId: provider.profile.userId,
          title: 'طلب جديد متاح',
          body:
              '${user.displayName} طلب خدمة ${order.serviceType} في ${location.district} - ${location.neighborhood}.',
          createdAt: now,
          type: NotificationType.orderCreated,
          orderId: order.orderId,
        ),
      );
    }

    await _storage.saveNotifications(notifications);
    return OrderCreationResult(
      order: order,
      matchedProvidersCount: matchingProviders.length,
    );
  }

  Future<ServiceOrder> acceptOrder({
    required String providerId,
    required String orderId,
  }) async {
    final List<ServiceOrder> orders = _storage.loadOrders().toList(growable: true);
    final int index = orders.indexWhere((ServiceOrder item) => item.orderId == orderId);
    if (index == -1) {
      throw const AuthException('الطلب غير موجود.');
    }
    final ServiceOrder order = orders[index];
    if (!order.targetedProviderIds.contains(providerId)) {
      throw const AuthException('هذا الطلب غير مخصص لك.');
    }
    if (order.rejectedProviderIds.contains(providerId)) {
      throw const AuthException('لقد تم رفض هذا الطلب مسبقاً من حسابك.');
    }
    if (order.status != OrderStatus.pending) {
      throw const AuthException('لا يمكن قبول الطلب بعد الآن لأن حالته تغيرت.');
    }

    final DateTime now = DateTime.now();
    final ServiceOrder updated = order.copyWith(
      status: OrderStatus.accepted,
      acceptedProviderId: providerId,
      updatedAt: now,
    );
    orders[index] = updated;
    await _storage.saveOrders(orders);

    final ProviderDetails? provider = getProviderById(providerId);
    await _appendNotifications(
      <InAppNotification>[
        InAppNotification(
          notificationId: _generateId('notification'),
          userId: order.userId,
          title: 'تم قبول طلبك',
          body:
              '${provider?.profile.businessName ?? 'مقدم الخدمة'} قبل طلب ${order.serviceType}، ويمكنك متابعة الحالة من سجل الطلبات.',
          createdAt: now,
          type: NotificationType.orderAccepted,
          orderId: order.orderId,
        ),
        if (provider != null)
          InAppNotification(
            notificationId: _generateId('notification'),
            userId: provider.profile.userId,
            title: 'تم تثبيت الطلب',
            body: 'أصبحت الآن مسؤولاً عن تنفيذ طلب ${order.serviceType}.',
            createdAt: now,
            type: NotificationType.orderAccepted,
            orderId: order.orderId,
          ),
      ],
    );
    return updated;
  }

  Future<ServiceOrder> rejectOrder({
    required String providerId,
    required String orderId,
  }) async {
    final List<ServiceOrder> orders = _storage.loadOrders().toList(growable: true);
    final int index = orders.indexWhere((ServiceOrder item) => item.orderId == orderId);
    if (index == -1) {
      throw const AuthException('الطلب غير موجود.');
    }
    final ServiceOrder order = orders[index];
    if (!order.targetedProviderIds.contains(providerId)) {
      throw const AuthException('هذا الطلب غير مخصص لك.');
    }
    if (order.status != OrderStatus.pending) {
      throw const AuthException('لا يمكن رفض الطلب بعد الآن لأن حالته تغيرت.');
    }
    if (order.rejectedProviderIds.contains(providerId)) {
      throw const AuthException('تم رفض هذا الطلب مسبقاً من حسابك.');
    }

    final DateTime now = DateTime.now();
    final List<String> rejectedIds = <String>{
      ...order.rejectedProviderIds,
      providerId,
    }.toList(growable: false);
    final int remainingProviders = order.targetedProviderIds
        .where((String item) => !rejectedIds.contains(item))
        .length;
    final ServiceOrder updated = order.copyWith(
      status: remainingProviders == 0 ? OrderStatus.rejected : OrderStatus.pending,
      rejectedProviderIds: rejectedIds,
      updatedAt: now,
    );
    orders[index] = updated;
    await _storage.saveOrders(orders);

    final ProviderDetails? provider = getProviderById(providerId);
    await _appendNotifications(
      <InAppNotification>[
        InAppNotification(
          notificationId: _generateId('notification'),
          userId: order.userId,
          title: 'تحديث على الطلب',
          body: remainingProviders == 0
              ? 'تم رفض طلب ${order.serviceType} من كل مقدمي الخدمة المتاحين حالياً.'
              : '${provider?.profile.businessName ?? 'أحد مقدمي الخدمة'} اعتذر عن الطلب، وما زال الطلب بانتظار مزود آخر.',
          createdAt: now,
          type: NotificationType.orderRejected,
          orderId: order.orderId,
        ),
        if (provider != null)
          InAppNotification(
            notificationId: _generateId('notification'),
            userId: provider.profile.userId,
            title: 'تم رفض الطلب',
            body: 'تم تسجيل اعتذارك عن طلب ${order.serviceType}.',
            createdAt: now,
            type: NotificationType.orderRejected,
            orderId: order.orderId,
          ),
      ],
    );
    return updated;
  }

  Future<ServiceOrder> cancelOrder({
    required String userId,
    required String orderId,
  }) async {
    final List<ServiceOrder> orders = _storage.loadOrders().toList(growable: true);
    final int index = orders.indexWhere((ServiceOrder item) => item.orderId == orderId);
    if (index == -1) {
      throw const AuthException('الطلب غير موجود.');
    }
    final ServiceOrder order = orders[index];
    if (order.userId != userId) {
      throw const AuthException('لا يمكنك إلغاء طلب لا يخص حسابك.');
    }
    if (!order.canClientCancel) {
      throw const AuthException('يمكن الإلغاء قبل قبول الطلب فقط.');
    }

    final DateTime now = DateTime.now();
    final ServiceOrder updated = order.copyWith(
      status: OrderStatus.cancelled,
      updatedAt: now,
    );
    orders[index] = updated;
    await _storage.saveOrders(orders);

    final List<InAppNotification> notifications = <InAppNotification>[
      InAppNotification(
        notificationId: _generateId('notification'),
        userId: order.userId,
        title: 'تم إلغاء الطلب',
        body: 'تم إلغاء طلب ${order.serviceType} بنجاح.',
        createdAt: now,
        type: NotificationType.orderCancelled,
        orderId: order.orderId,
      ),
    ];
    for (final String providerId in order.targetedProviderIds) {
      final ProviderDetails? provider = getProviderById(providerId);
      if (provider == null) {
        continue;
      }
      notifications.add(
        InAppNotification(
          notificationId: _generateId('notification'),
          userId: provider.profile.userId,
          title: 'تم إلغاء الطلب',
          body: 'العميل ألغى طلب ${order.serviceType} قبل القبول.',
          createdAt: now,
          type: NotificationType.orderCancelled,
          orderId: order.orderId,
        ),
      );
    }
    await _appendNotifications(notifications);
    return updated;
  }

  Future<ServiceOrder> updateOrderStatus({
    required String providerId,
    required String orderId,
    required OrderStatus status,
  }) async {
    final List<ServiceOrder> orders = _storage.loadOrders().toList(growable: true);
    final int index = orders.indexWhere((ServiceOrder item) => item.orderId == orderId);
    if (index == -1) {
      throw const AuthException('الطلب غير موجود.');
    }
    final ServiceOrder order = orders[index];
    if (order.acceptedProviderId != providerId) {
      throw const AuthException('فقط مقدم الخدمة المقبول يمكنه تغيير الحالة.');
    }

    final bool validTransition =
        (order.status == OrderStatus.accepted && status == OrderStatus.onTheWay) ||
        ((order.status == OrderStatus.accepted || order.status == OrderStatus.onTheWay) &&
            status == OrderStatus.completed);
    if (!validTransition) {
      throw const AuthException('الانتقال المطلوب غير مسموح لهذه الحالة.');
    }

    final DateTime now = DateTime.now();
    final ServiceOrder updated = order.copyWith(status: status, updatedAt: now);
    orders[index] = updated;
    await _storage.saveOrders(orders);

    final ProviderDetails? provider = getProviderById(providerId);
    await _appendNotifications(
      <InAppNotification>[
        InAppNotification(
          notificationId: _generateId('notification'),
          userId: order.userId,
          title: 'تم تحديث حالة الطلب',
          body:
              'حالة طلب ${order.serviceType} أصبحت ${status.arabicLabel}${provider == null ? '' : ' بواسطة ${provider.profile.businessName}'}.',
          createdAt: now,
          type: NotificationType.orderStatusChanged,
          orderId: order.orderId,
        ),
        if (provider != null)
          InAppNotification(
            notificationId: _generateId('notification'),
            userId: provider.profile.userId,
            title: 'تم تحديث الحالة',
            body: 'تم تسجيل حالة ${status.arabicLabel} لطلب ${order.serviceType}.',
            createdAt: now,
            type: NotificationType.orderStatusChanged,
            orderId: order.orderId,
          ),
      ],
    );
    return updated;
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final List<InAppNotification> notifications = _storage
        .loadNotifications()
        .toList(growable: true);
    bool changed = false;
    for (int index = 0; index < notifications.length; index++) {
      final InAppNotification item = notifications[index];
      if (item.userId == userId && !item.isRead) {
        notifications[index] = item.copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _storage.saveNotifications(notifications);
    }
  }

  Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final List<InAppNotification> notifications = _storage
        .loadNotifications()
        .toList(growable: true);
    final int index = notifications.indexWhere(
      (InAppNotification item) =>
          item.notificationId == notificationId && item.userId == userId,
    );
    if (index == -1 || notifications[index].isRead) {
      return;
    }
    notifications[index] = notifications[index].copyWith(isRead: true);
    await _storage.saveNotifications(notifications);
  }

  List<ProviderDetails> _findMatchingProviders({
    required String serviceType,
    required OrderLocation location,
  }) {
    return _providerRepository
        .getAllProviderDetails()
        .where((ProviderDetails provider) => provider.isVisibleInApp)
        .where((ProviderDetails provider) => _matchesService(provider, serviceType))
        .where((ProviderDetails provider) => _matchesLocation(provider, location))
        .toList(growable: false);
  }

  bool _matchesService(ProviderDetails provider, String serviceType) {
    final String requested = _normalize(serviceType);
    final Set<String> candidates = <String>{
      _normalize(provider.profile.mainServiceType),
      ...provider.services.map((ProviderService item) => _normalize(item.title)),
      ...provider.services.map((ProviderService item) => _normalize(item.description)),
    }.where((String item) => item.isNotEmpty).toSet();
    for (final String candidate in candidates) {
      if (candidate == requested || candidate.contains(requested) || requested.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesLocation(ProviderDetails provider, OrderLocation location) {
    final String requestedGovernorate = _normalize(location.governorate);
    final String requestedDistrict = _normalize(location.district);
    final String requestedNeighborhood = _normalize(location.neighborhood);

    if (_normalize(provider.profile.governorate) == requestedGovernorate &&
        _normalize(provider.profile.district) == requestedDistrict) {
      return true;
    }

    for (final ProviderServiceArea area in provider.serviceAreas) {
      if (_normalize(area.governorate) != requestedGovernorate ||
          _normalize(area.district) != requestedDistrict) {
        continue;
      }
      final String areaNeighborhood = _normalize(area.neighborhood ?? '');
      if (areaNeighborhood.isEmpty ||
          requestedNeighborhood.isEmpty ||
          areaNeighborhood == requestedNeighborhood ||
          areaNeighborhood.contains(requestedNeighborhood) ||
          requestedNeighborhood.contains(areaNeighborhood)) {
        return true;
      }
    }
    return false;
  }

  List<ServiceOrder> _sortOrders(List<ServiceOrder> items) {
    final List<ServiceOrder> sorted = List<ServiceOrder>.from(items);
    sorted.sort((ServiceOrder a, ServiceOrder b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> _appendNotifications(List<InAppNotification> items) async {
    final List<InAppNotification> notifications = _storage
        .loadNotifications()
        .toList(growable: true);
    notifications.addAll(items);
    await _storage.saveNotifications(notifications);
  }

  bool _isValidPhone(String phoneNumber) {
    final RegExp expression = RegExp(r'^\+?[0-9]{9,15}$');
    return expression.hasMatch(phoneNumber);
  }

  String _normalizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _generateId(String prefix) {
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }
}
