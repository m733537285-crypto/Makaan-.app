import '../../../shared/constants/yemen_locations.dart';
import '../../../shared/models/ad_models.dart';
import '../../../shared/models/admin_models.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/order_models.dart';
import '../../../shared/models/provider_models.dart';
import '../../../shared/services/app_storage_service.dart';

class AdminRepository {
  AdminRepository(this._storage);

  final AppStorageService _storage;

  Future<void> ensureSeedData() async {
    if (_storage.loadAdminLocations().isEmpty) {
      await _storage.saveAdminLocations(
        YemenLocations.governorates.entries
            .map(
              (MapEntry<String, List<String>> item) => AdminManagedLocation(
                governorate: item.key,
                districts: item.value,
              ),
            )
            .toList(growable: false),
      );
    }
    if (_storage.loadAdminCategories().isEmpty) {
      await _storage.saveAdminCategories(_defaultCategories());
    }
    if (_storage.loadAdminReports().isEmpty) {
      final DateTime now = DateTime.now();
      await _storage.saveAdminReports(<AdminReportTicket>[
        AdminReportTicket(
          reportId: 'report-seed-1',
          reporterName: 'عميل مكان',
          reportedName: 'إعلان غير موثق',
          targetType: 'ad',
          targetId: 'ad-seed-7',
          reason: 'الصورة لا تطابق وصف الإعلان ويحتاج إلى مراجعة قبل النشر.',
          status: AdminReportStatus.pending,
          createdAt: now.subtract(const Duration(hours: 8)),
        ),
        AdminReportTicket(
          reportId: 'report-seed-2',
          reporterName: 'مقدم خدمة',
          reportedName: 'تعليق مخالف',
          targetType: 'review',
          targetId: 'review-seed-1',
          reason: 'تعليق يتضمن ألفاظ غير مناسبة ويحتاج إلى إخفاء أو حذف.',
          status: AdminReportStatus.pending,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ]);
    }
    if (_storage.loadAdminLogs().isEmpty) {
      await addLog(
        actorName: 'النظام',
        role: AdminRole.superAdmin,
        action: 'تهيئة لوحة الإدارة',
        targetType: 'system',
        targetId: 'bootstrap',
        details: 'تم إنشاء بيانات أولية للوحة الإدارة والتقارير والتصنيفات.',
      );
    }
  }

  List<AppUser> getUsers() {
    final List<AppUser> items = _storage.loadUsers();
    items.sort((AppUser a, AppUser b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<ProviderDetails> getProviders() {
    final List<ProviderProfile> profiles = _storage.loadProviderProfiles();
    final List<ProviderService> services = _storage.loadProviderServices();
    final List<ProviderGalleryItem> gallery = _storage.loadProviderGalleryItems();
    final List<ProviderServiceArea> areas = _storage.loadProviderServiceAreas();
    final List<ProviderReview> reviews = _storage.loadProviderReviews();
    final List<ProviderSubscription> subscriptions = _storage.loadProviderSubscriptions();
    final List<ProviderDetails> result = profiles.map((ProviderProfile profile) {
      ProviderSubscription? subscription;
      for (final ProviderSubscription item in subscriptions) {
        if (item.providerId == profile.providerId) {
          subscription = item;
          break;
        }
      }
      return ProviderDetails(
        profile: profile,
        services: services.where((ProviderService item) => item.providerId == profile.providerId).toList(growable: false),
        gallery: gallery.where((ProviderGalleryItem item) => item.providerId == profile.providerId).toList(growable: false),
        serviceAreas: areas.where((ProviderServiceArea item) => item.providerId == profile.providerId).toList(growable: false),
        reviews: reviews.where((ProviderReview item) => item.providerId == profile.providerId).toList(growable: false),
        subscription: subscription,
      );
    }).toList(growable: false);
    result.sort((ProviderDetails a, ProviderDetails b) => b.profile.createdAt.compareTo(a.profile.createdAt));
    return result;
  }

  List<ServiceOrder> getOrders() {
    final List<ServiceOrder> items = _storage.loadOrders();
    items.sort((ServiceOrder a, ServiceOrder b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<AdListing> getAds() {
    final List<AdListing> items = _storage.loadAds();
    items.sort((AdListing a, AdListing b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<ProviderSubscription> getSubscriptions() {
    final List<ProviderSubscription> items = _storage.loadProviderSubscriptions();
    items.sort((ProviderSubscription a, ProviderSubscription b) => b.endDate.compareTo(a.endDate));
    return items;
  }

  List<ProviderReview> getReviews() {
    final List<ProviderReview> items = _storage.loadProviderReviews();
    items.sort((ProviderReview a, ProviderReview b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<AdminReportTicket> getReports() {
    final List<AdminReportTicket> items = _storage.loadAdminReports();
    items.sort((AdminReportTicket a, AdminReportTicket b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<AdminSystemLog> getLogs() {
    final List<AdminSystemLog> items = _storage.loadAdminLogs();
    items.sort((AdminSystemLog a, AdminSystemLog b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<AdminManagedLocation> getLocations() => _storage.loadAdminLocations();

  List<AdminManagedCategory> getCategories() => _storage.loadAdminCategories();

  AdminDashboardMetrics getDashboardMetrics() {
    final List<AppUser> users = _storage.loadUsers();
    final List<ProviderDetails> providers = getProviders();
    final List<ServiceOrder> orders = _storage.loadOrders();
    final List<AdListing> ads = _storage.loadAds();
    final List<ProviderSubscription> subscriptions = _storage.loadProviderSubscriptions();
    final List<AdminReportTicket> reports = _storage.loadAdminReports();
    final List<ProviderReview> reviews = _storage.loadProviderReviews();
    final Map<String, int> serviceCounts = <String, int>{};
    for (final ServiceOrder order in orders) {
      serviceCounts[order.serviceType] = (serviceCounts[order.serviceType] ?? 0) + 1;
    }
    final List<MapEntry<String, int>> services = serviceCounts.entries.toList(growable: false)
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    return AdminDashboardMetrics(
      totalUsers: users.length,
      totalProviders: providers.length,
      totalOrders: orders.length,
      completedOrders: orders.where((ServiceOrder item) => item.status == OrderStatus.completed).length,
      cancelledOrders: orders.where((ServiceOrder item) => item.status == OrderStatus.cancelled).length,
      activeAds: ads.where((AdListing item) => item.effectiveStatus == AdStatus.active).length,
      expiredAds: ads.where((AdListing item) => item.effectiveStatus == AdStatus.expired).length,
      activeSubscriptions: subscriptions.where((ProviderSubscription item) => item.isActive).length,
      expiredSubscriptions: subscriptions.where((ProviderSubscription item) => item.status == SubscriptionStatus.expired || item.endDate.isBefore(DateTime.now())).length,
      reportsCount: reports.length,
      reviewsCount: reviews.length,
      mostRequestedServices: services.take(5).map((MapEntry<String, int> item) => '${item.key} (${item.value})').toList(growable: false),
    );
  }

  Future<void> saveUser(AppUser user, {required String actorName, required AdminRole role}) async {
    final List<AppUser> users = _storage.loadUsers();
    final int index = users.indexWhere((AppUser item) => item.userId == user.userId);
    if (index == -1) {
      users.add(user);
    } else {
      users[index] = user;
    }
    await _storage.saveUsers(users);
    await addLog(actorName: actorName, role: role, action: 'تعديل مستخدم', targetType: 'user', targetId: user.userId, details: 'تم تعديل بيانات ${user.displayName}.');
  }

  Future<void> deleteUser(String userId, {required String actorName, required AdminRole role}) async {
    final List<AppUser> users = _storage.loadUsers().where((AppUser item) => item.userId != userId).toList(growable: false);
    await _storage.saveUsers(users);
    await _storage.deleteBackendRecord(table: 'app_users', id: userId);
    await addLog(actorName: actorName, role: role, action: 'حذف حساب', targetType: 'user', targetId: userId, details: 'تم حذف حساب مستخدم من لوحة الإدارة.');
  }

  Future<void> updateProviderStatus(String providerId, ProviderAccountStatus status, {required String actorName, required AdminRole role}) async {
    final List<ProviderProfile> providers = _storage.loadProviderProfiles();
    final int index = providers.indexWhere((ProviderProfile item) => item.providerId == providerId);
    if (index == -1) {
      return;
    }
    providers[index] = providers[index].copyWith(status: status, updatedAt: DateTime.now());
    await _storage.saveProviderProfiles(providers);
    await addLog(actorName: actorName, role: role, action: 'تغيير حالة مقدم خدمة', targetType: 'provider', targetId: providerId, details: 'الحالة الجديدة: ${status.arabicLabel}.');
  }

  Future<void> saveSubscription(ProviderSubscription subscription, {required String actorName, required AdminRole role}) async {
    final List<ProviderSubscription> items = _storage.loadProviderSubscriptions();
    final int index = items.indexWhere((ProviderSubscription item) => item.providerId == subscription.providerId);
    if (index == -1) {
      items.add(subscription);
    } else {
      items[index] = subscription;
    }
    await _storage.saveProviderSubscriptions(items);
    await updateProviderStatus(
      subscription.providerId,
      subscription.status == SubscriptionStatus.active ? ProviderAccountStatus.active : subscription.status == SubscriptionStatus.expired ? ProviderAccountStatus.expired : ProviderAccountStatus.pending,
      actorName: actorName,
      role: role,
    );
    await addLog(actorName: actorName, role: role, action: 'تعديل اشتراك', targetType: 'subscription', targetId: subscription.subscriptionId, details: '${subscription.planType} حتى ${subscription.endDate.toIso8601String().split('T').first}.');
  }

  Future<void> updateAd(AdListing ad, {required String actorName, required AdminRole role}) async {
    final List<AdListing> ads = _storage.loadAds();
    final int index = ads.indexWhere((AdListing item) => item.adId == ad.adId);
    if (index == -1) {
      return;
    }
    ads[index] = ad;
    await _storage.saveAds(ads);
    await addLog(actorName: actorName, role: role, action: 'تعديل إعلان', targetType: 'ad', targetId: ad.adId, details: '${ad.title} - ${ad.status.arabicLabel}.');
  }

  Future<void> deleteAd(String adId, {required String actorName, required AdminRole role}) async {
    await _storage.saveAds(_storage.loadAds().where((AdListing item) => item.adId != adId).toList(growable: false));
    await _storage.deleteBackendRecord(table: 'ad_listings', id: adId);
    await addLog(actorName: actorName, role: role, action: 'حذف إعلان', targetType: 'ad', targetId: adId, details: 'تم حذف الإعلان من النظام.');
  }

  Future<void> updateOrder(ServiceOrder order, {required String actorName, required AdminRole role}) async {
    final List<ServiceOrder> orders = _storage.loadOrders();
    final int index = orders.indexWhere((ServiceOrder item) => item.orderId == order.orderId);
    if (index == -1) {
      return;
    }
    orders[index] = order.copyWith(updatedAt: DateTime.now());
    await _storage.saveOrders(orders);
    await addLog(actorName: actorName, role: role, action: 'متابعة طلب', targetType: 'order', targetId: order.orderId, details: 'تم تحديث الحالة إلى ${order.status.arabicLabel}.');
  }

  Future<void> resolveReport(String reportId, AdminReportStatus status, {required String actorName, required AdminRole role, String? note}) async {
    final List<AdminReportTicket> reports = _storage.loadAdminReports();
    final int index = reports.indexWhere((AdminReportTicket item) => item.reportId == reportId);
    if (index == -1) {
      return;
    }
    reports[index] = reports[index].copyWith(status: status, resolvedAt: DateTime.now(), actionNote: note ?? status.arabicLabel);
    await _storage.saveAdminReports(reports);
    await addLog(actorName: actorName, role: role, action: status == AdminReportStatus.accepted ? 'قبول بلاغ' : 'رفض بلاغ', targetType: 'report', targetId: reportId, details: reports[index].actionNote ?? 'تمت مراجعة البلاغ.');
  }

  Future<void> deleteReview(String reviewId, {required String actorName, required AdminRole role}) async {
    await _storage.saveProviderReviews(_storage.loadProviderReviews().where((ProviderReview item) => item.reviewId != reviewId).toList(growable: false));
    await _storage.deleteBackendRecord(table: 'provider_reviews', id: reviewId);
    await addLog(actorName: actorName, role: role, action: 'حذف تقييم', targetType: 'review', targetId: reviewId, details: 'تم حذف تقييم مخالف من لوحة الإدارة.');
  }

  Future<void> saveLocations(List<AdminManagedLocation> locations, {required String actorName, required AdminRole role}) async {
    await _storage.saveAdminLocations(locations);
    await addLog(actorName: actorName, role: role, action: 'تحديث المحافظات والمديريات', targetType: 'taxonomy', targetId: 'locations', details: 'تم حفظ ${locations.length} محافظة.');
  }

  Future<void> saveCategories(List<AdminManagedCategory> categories, {required String actorName, required AdminRole role}) async {
    await _storage.saveAdminCategories(categories);
    await addLog(actorName: actorName, role: role, action: 'تحديث التصنيفات والخدمات', targetType: 'taxonomy', targetId: 'categories', details: 'تم حفظ ${categories.length} تصنيف.');
  }

  AdminExportBundle exportCsv(String section) {
    switch (section) {
      case 'users':
        return AdminExportBundle(fileName: 'makaan_users.csv', csvContent: _rowsToCsv(<List<String>>[
          <String>['id', 'name', 'phone', 'type', 'governorate', 'district', 'blocked'],
          ...getUsers().map((AppUser item) => <String>[item.userId, item.displayName, item.phoneNumber, item.userType?.arabicLabel ?? '', item.governorate ?? '', item.district ?? '', item.isBlocked ? 'yes' : 'no']),
        ]));
      case 'providers':
        return AdminExportBundle(fileName: 'makaan_providers.csv', csvContent: _rowsToCsv(<List<String>>[
          <String>['id', 'business', 'service', 'status', 'governorate', 'district', 'rating'],
          ...getProviders().map((ProviderDetails item) => <String>[item.profile.providerId, item.profile.businessName, item.profile.mainServiceType, item.profile.status.arabicLabel, item.profile.governorate, item.profile.district, item.averageRating.toStringAsFixed(1)]),
        ]));
      case 'orders':
        return AdminExportBundle(fileName: 'makaan_orders.csv', csvContent: _rowsToCsv(<List<String>>[
          <String>['id', 'service', 'status', 'location', 'phone', 'created_at'],
          ...getOrders().map((ServiceOrder item) => <String>[item.orderId, item.serviceType, item.status.arabicLabel, item.locationText, item.phoneNumber, item.createdAt.toIso8601String()]),
        ]));
      case 'ads':
      default:
        return AdminExportBundle(fileName: 'makaan_ads.csv', csvContent: _rowsToCsv(<List<String>>[
          <String>['id', 'title', 'category', 'status', 'price', 'banner', 'featured'],
          ...getAds().map((AdListing item) => <String>[item.adId, item.title, item.category.arabicLabel, item.effectiveStatus.arabicLabel, item.priceAfter.toStringAsFixed(0), item.isBanner ? 'yes' : 'no', item.isFeatured ? 'yes' : 'no']),
        ]));
    }
  }

  Future<void> addLog({
    required String actorName,
    required AdminRole role,
    required String action,
    required String targetType,
    required String targetId,
    required String details,
  }) async {
    final List<AdminSystemLog> logs = _storage.loadAdminLogs().toList(growable: true);
    logs.add(AdminSystemLog(
      logId: 'log_${DateTime.now().microsecondsSinceEpoch}',
      actorName: actorName,
      role: role,
      action: action,
      targetType: targetType,
      targetId: targetId,
      details: details,
      createdAt: DateTime.now(),
    ));
    if (logs.length > 400) {
      logs.removeRange(0, logs.length - 400);
    }
    await _storage.saveAdminLogs(logs);
  }

  List<AdminManagedCategory> _defaultCategories() {
    return const <AdminManagedCategory>[
      AdminManagedCategory(categoryId: 'water', title: 'المياه', emoji: '🚰', services: <String>['وايت ماء', 'توصيل مياه', 'خزانات']),
      AdminManagedCategory(categoryId: 'taxi', title: 'التكاسي', emoji: '🚖', services: <String>['مشاوير داخلية', 'مشاوير خارجية', 'توصيل خاص']),
      AdminManagedCategory(categoryId: 'tires', title: 'البنشري', emoji: '🔧', services: <String>['تغيير كفر', 'بنشر متنقل', 'وزن أذرعة']),
      AdminManagedCategory(categoryId: 'mechanic', title: 'الميكانيكي', emoji: '🛠', services: <String>['فحص سيارة', 'صيانة محرك', 'كهرباء سيارات']),
      AdminManagedCategory(categoryId: 'restaurants', title: 'المطاعم', emoji: '🍽', services: <String>['وجبات', 'توصيل', 'طلبات عائلية']),
      AdminManagedCategory(categoryId: 'groceries', title: 'البقالات', emoji: '🛒', services: <String>['مواد غذائية', 'توصيل بقالة', 'سلة أسبوعية']),
      AdminManagedCategory(categoryId: 'pharmacies', title: 'الصيدليات', emoji: '💊', services: <String>['أدوية', 'مستلزمات طبية', 'توصيل']),
      AdminManagedCategory(categoryId: 'real_estate', title: 'العقارات', emoji: '🏠', services: <String>['إيجار', 'بيع', 'أراضي']),
      AdminManagedCategory(categoryId: 'cars', title: 'السيارات', emoji: '🚗', services: <String>['بيع سيارات', 'تأجير', 'معارض']),
      AdminManagedCategory(categoryId: 'crafts', title: 'الحرفيون', emoji: '🔨', services: <String>['نجار', 'سباك', 'كهربائي']),
      AdminManagedCategory(categoryId: 'other', title: 'خدمات أخرى', emoji: '📦', services: <String>['خدمات عامة', 'نقل', 'تنظيف']),
    ];
  }

  String _rowsToCsv(List<List<String>> rows) {
    String escape(String value) => '"${value.replaceAll('"', '""')}"';
    return rows.map((List<String> row) => row.map(escape).join(',')).join('\n');
  }
}
