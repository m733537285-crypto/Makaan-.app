import 'package:flutter/material.dart';

import '../shared/security/security_guard_service.dart';

import '../features/admin/data/admin_repository.dart';
import '../features/ads/data/ad_repository.dart';
import '../features/favorites/data/favorite_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/orders/data/order_repository.dart';
import '../features/search/data/search_repository.dart';
import '../features/providers/data/provider_repository.dart';
import 'router/app_routes.dart';
import '../shared/models/ad_models.dart';
import '../shared/models/admin_models.dart';
import '../shared/models/app_settings.dart';
import '../shared/models/app_user.dart';
import '../shared/models/favorite_models.dart';
import '../shared/models/order_models.dart';
import '../shared/models/otp_challenge.dart';
import '../shared/models/search_models.dart';
import '../shared/models/provider_models.dart';
import '../shared/services/app_storage_service.dart';
import '../shared/services/runtime_diagnostics_service.dart';

class AppController extends ChangeNotifier {
  AppController._(
    this._storage,
    this._authRepository,
    this._providerRepository,
    this._orderRepository,
    this._adRepository,
    this._favoriteRepository,
    this._searchRepository,
    this._adminRepository,
  ) {
    _onboardingCompleted = _authRepository.onboardingCompleted;
  }

  final AppStorageService _storage;
  final AuthRepository _authRepository;
  final ProviderRepository _providerRepository;
  final OrderRepository _orderRepository;
  final AdRepository _adRepository;
  final FavoriteRepository _favoriteRepository;
  final SearchRepository _searchRepository;
  final AdminRepository _adminRepository;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');
  AppSettings _settings = AppSettings.defaults();
  bool _onboardingCompleted = false;
  bool _isReady = false;
  AppUser? _currentUser;
  OtpChallenge? _activeOtpChallenge;
  ProviderDetails? _currentProviderDetails;
  AdminRole _activeAdminRole = AdminRole.superAdmin;

  static Future<AppController> bootstrap() async {
    final AppStorageService storage = await AppStorageService.create();
    final ProviderRepository providerRepository = ProviderRepository(storage);
    final AdRepository adRepository = AdRepository(storage);
    final SearchRepository searchRepository = SearchRepository(providerRepository, adRepository);
    final AppController controller = AppController._(
      storage,
      AuthRepository(storage),
      providerRepository,
      OrderRepository(storage, providerRepository),
      adRepository,
      FavoriteRepository(storage),
      searchRepository,
      AdminRepository(storage),
    );
    await controller.initialize();
    return controller;
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  AppSettings get appSettings => _settings;
  bool get pushNotificationsEnabled => _settings.pushNotificationsEnabled;
  List<PerformanceSample> get performanceSamples => RuntimeDiagnosticsService.instance.recentPerformanceSamples;
  List<RuntimeErrorEntry> get runtimeErrors => RuntimeDiagnosticsService.instance.recentErrors;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isReady => _isReady;
  AppUser? get currentUser => _currentUser;
  OtpChallenge? get activeOtpChallenge => _activeOtpChallenge;
  ProviderDetails? get currentProviderDetails => _currentProviderDetails;
  AdminRole get activeAdminRole => _activeAdminRole;
  bool get isAuthenticated => _currentUser != null;
  bool get isRemoteBackendEnabled => _authRepository.isRemoteBackendEnabled;
  String? get backendStatusMessage => _authRepository.lastBackendError;
  bool get canAccessAdminPanel {
    final AppUser? user = _currentUser;
    if (user == null || user.isBlocked || !user.isVerified) {
      return false;
    }
    if (!isRemoteBackendEnabled) {
      return true;
    }
    const String configuredAdminPhone = String.fromEnvironment('MAKAAN_SUPER_ADMIN_PHONE');
    return configuredAdminPhone.trim().isNotEmpty && user.phoneNumber.trim() == configuredAdminPhone.trim();
  }
  bool get needsUserTypeSelection => _currentUser != null && _currentUser!.userType == null;
  bool get needsProfileCompletion => _currentUser != null && !_currentUser!.hasCompletedProfile;
  bool get needsProviderSetup =>
      _currentUser != null &&
      _currentUser!.isProvider &&
      _currentUser!.hasCompletedProfile &&
      _currentProviderDetails == null;
  List<String> get availableServiceTypes => _orderRepository.getAvailableServiceTypes();
  List<ServiceOrder> get clientOrders => _currentUser == null
      ? const <ServiceOrder>[]
      : _orderRepository.getOrdersForClient(_currentUser!.userId);
  List<ServiceOrder> get providerInboxOrders => _currentProviderDetails == null
      ? const <ServiceOrder>[]
      : _orderRepository.getPendingInboxOrdersForProvider(
          _currentProviderDetails!.profile.providerId,
        );
  List<ServiceOrder> get providerActiveOrders => _currentProviderDetails == null
      ? const <ServiceOrder>[]
      : _orderRepository.getActiveOrdersForProvider(
          _currentProviderDetails!.profile.providerId,
        );
  List<ServiceOrder> get providerCompletedOrders => _currentProviderDetails == null
      ? const <ServiceOrder>[]
      : _orderRepository.getCompletedOrdersForProvider(
          _currentProviderDetails!.profile.providerId,
        );
  List<ServiceOrder> get providerRejectedOrders => _currentProviderDetails == null
      ? const <ServiceOrder>[]
      : _orderRepository.getRejectedOrdersForProvider(
          _currentProviderDetails!.profile.providerId,
        );
  List<InAppNotification> get currentNotifications => _currentUser == null
      ? const <InAppNotification>[]
      : _orderRepository.getNotificationsForUser(_currentUser!.userId);
  int get unreadNotificationsCount =>
      currentNotifications.where((InAppNotification item) => !item.isRead).length;
  List<AdListing> get allAds => _adRepository.getAllAds(includeInactive: true);
  List<AdListing> get activeAds => _adRepository.getAllAds();
  List<AdListing> get bannerAds => _adRepository.getBannerAds();
  List<AdListing> get todayDeals => _adRepository.getTodayDeals();
  List<AdListing> get halfPriceDeals => _adRepository.getHalfPriceDeals();
  List<AdListing> get featuredAds => _adRepository.getFeaturedAds();
  List<AdListing> get productAds => _adRepository.getProductAds();
  List<AdListing> get discountedServiceAds => _adRepository.getDiscountedServiceAds();
  List<AdListing> get myAds => _currentUser == null
      ? const <AdListing>[]
      : _adRepository.getAdsForUser(_currentUser!.userId);
  List<ProviderDetails> get allProviderDetails => _providerRepository.getAllProviderDetails();
  List<ProviderDetails> get visibleProviderDetails => allProviderDetails
      .where((ProviderDetails item) => item.isVisibleInApp)
      .toList(growable: false);
  List<ProviderDetails> get topRatedProviders => _searchRepository.topRatedProviders();
  List<ProviderDetails> get newProviderDetails => _searchRepository.newProviders();
  List<String> get mostRequestedServices => _searchRepository.mostRequestedServices();
  List<DiscoveryCategory> get discoveryCategories => SearchRepository.categories;
  List<AdCategory> get availableAdCategories => AdRepository.supportedCategories;
  List<DealType> get availableDealTypes => AdRepository.supportedDealTypes;
  List<FavoriteItem> get currentFavorites => _currentUser == null
      ? const <FavoriteItem>[]
      : _favoriteRepository.getFavoritesForUser(_currentUser!.userId);
  List<AdListing> get favoriteAds => currentFavorites
      .where((FavoriteItem item) => item.type == FavoriteItemType.ad)
      .map((FavoriteItem item) => findAdById(item.itemId))
      .whereType<AdListing>()
      .toList(growable: false);
  List<ProviderDetails> get favoriteProviders => currentFavorites
      .where((FavoriteItem item) => item.type == FavoriteItemType.provider)
      .map((FavoriteItem item) => findProviderById(item.itemId))
      .whereType<ProviderDetails>()
      .toList(growable: false);


  List<AppUser> get adminUsers => _adminRepository.getUsers();
  List<ProviderDetails> get adminProviders => _adminRepository.getProviders();
  List<ServiceOrder> get adminOrders => _adminRepository.getOrders();
  List<AdListing> get adminAds => _adminRepository.getAds();
  List<ProviderSubscription> get adminSubscriptions => _adminRepository.getSubscriptions();
  List<ProviderReview> get adminReviews => _adminRepository.getReviews();
  List<AdminReportTicket> get adminReports => _adminRepository.getReports();
  List<AdminSystemLog> get adminLogs => _adminRepository.getLogs();
  List<AdminManagedLocation> get adminManagedLocations => _adminRepository.getLocations();
  List<AdminManagedCategory> get adminManagedCategories => _adminRepository.getCategories();
  AdminDashboardMetrics get adminDashboardMetrics => _adminRepository.getDashboardMetrics();

  List<String> get visibleAdminSectionIds {
    switch (_activeAdminRole) {
      case AdminRole.superAdmin:
        return const <String>['dashboard', 'users', 'providers', 'subscriptions', 'ads', 'orders', 'reports', 'reviews', 'taxonomy', 'logs', 'permissions'];
      case AdminRole.contentManager:
        return const <String>['dashboard', 'providers', 'ads', 'reports', 'reviews', 'taxonomy', 'logs'];
      case AdminRole.subscriptionsManager:
        return const <String>['dashboard', 'providers', 'subscriptions', 'logs'];
      case AdminRole.supportManager:
        return const <String>['dashboard', 'users', 'orders', 'reports', 'reviews', 'logs'];
    }
  }

  void setActiveAdminRole(AdminRole role) {
    if (_activeAdminRole == role) {
      return;
    }
    _activeAdminRole = role;
    notifyListeners();
  }

  Future<void> adminSaveUser(AppUser user) async {
    await _adminRepository.saveUser(user, actorName: _adminActorName, role: _activeAdminRole);
    if (_currentUser?.userId == user.userId) {
      _currentUser = user;
    }
    notifyListeners();
  }

  Future<void> adminDeleteUser(String userId) async {
    await _adminRepository.deleteUser(userId, actorName: _adminActorName, role: _activeAdminRole);
    if (_currentUser?.userId == userId) {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> adminUpdateProviderStatus(String providerId, ProviderAccountStatus status) async {
    await _adminRepository.updateProviderStatus(providerId, status, actorName: _adminActorName, role: _activeAdminRole);
    await _refreshProviderDetails(silent: true);
    notifyListeners();
  }

  Future<void> adminSaveSubscription(ProviderSubscription subscription) async {
    await _adminRepository.saveSubscription(subscription, actorName: _adminActorName, role: _activeAdminRole);
    await _refreshProviderDetails(silent: true);
    notifyListeners();
  }

  Future<void> adminUpdateAd(AdListing ad) async {
    await _adminRepository.updateAd(ad, actorName: _adminActorName, role: _activeAdminRole);
    notifyListeners();
  }

  Future<void> adminDeleteAd(String adId) async {
    await _adminRepository.deleteAd(adId, actorName: _adminActorName, role: _activeAdminRole);
    notifyListeners();
  }

  Future<void> adminUpdateOrder(ServiceOrder order) async {
    await _adminRepository.updateOrder(order, actorName: _adminActorName, role: _activeAdminRole);
    notifyListeners();
  }

  Future<void> adminResolveReport(String reportId, AdminReportStatus status, {String? note}) async {
    await _adminRepository.resolveReport(reportId, status, actorName: _adminActorName, role: _activeAdminRole, note: note);
    notifyListeners();
  }

  Future<void> adminDeleteReview(String reviewId) async {
    await _adminRepository.deleteReview(reviewId, actorName: _adminActorName, role: _activeAdminRole);
    notifyListeners();
  }

  Future<void> adminSaveLocations(List<AdminManagedLocation> locations) async {
    await _adminRepository.saveLocations(locations, actorName: _adminActorName, role: _activeAdminRole);
    notifyListeners();
  }

  Future<void> adminSaveCategories(List<AdminManagedCategory> categories) async {
    await _adminRepository.saveCategories(categories, actorName: _adminActorName, role: _activeAdminRole);
    notifyListeners();
  }

  AdminExportBundle adminExportCsv(String section) => _adminRepository.exportCsv(section);

  String get _adminActorName => _currentUser?.displayName ?? 'مدير النظام';

  Future<void> initialize() async {
    await RuntimeDiagnosticsService.instance.trackAsync('app_initialize', () async {
      _settings = _storage.loadAppSettings();
      _themeMode = _settings.themeMode;
      _locale = _settings.locale;
      if (isRemoteBackendEnabled) {
        await _authRepository.refreshRemoteCache();
      } else {
        await _adRepository.ensureSeedData();
        await _adminRepository.ensureSeedData();
      }
      _currentUser = await _authRepository.restoreSession();
      if (_currentUser != null && isRemoteBackendEnabled) {
        await _storage.registerCurrentPushDevice(_currentUser!.userId);
      }
      _activeOtpChallenge = _authRepository.loadActiveChallenge();
      await _refreshProviderDetails(silent: true);
      _isReady = true;
    });
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_onboardingCompleted) {
      return;
    }
    _onboardingCompleted = true;
    notifyListeners();
    await _authRepository.setOnboardingCompleted(true);
  }

  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    bool forceResend = false,
  }) async {
    SecurityGuardService.instance.validatePhoneNumber(phoneNumber);
    SecurityGuardService.instance.checkRateLimit(
      key: 'otp:$phoneNumber',
      maxAttempts: forceResend ? 3 : 5,
      window: const Duration(minutes: 15),
      message: 'تم طلب رمز التحقق عدة مرات. حاول بعد قليل.',
    );
    final OtpRequestResult result = await _authRepository.requestOtp(
      phoneNumber: phoneNumber,
      forceResend: forceResend,
    );
    _activeOtpChallenge = result.challenge;
    notifyListeners();
    return result;
  }

  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final OtpVerificationResult result = await _authRepository.verifyOtp(
        phoneNumber: phoneNumber,
        code: code,
      );
      _currentUser = result.user;
      _activeOtpChallenge = null;
      if (isRemoteBackendEnabled) {
        await _storage.registerCurrentPushDevice(result.user.userId);
      }
      await _refreshProviderDetails(silent: true);
      await _adminRepository.addLog(
        actorName: result.user.displayName,
        role: AdminRole.supportManager,
        action: 'تسجيل الدخول',
        targetType: 'auth',
        targetId: result.user.userId,
        details: 'تم تسجيل الدخول أو إنشاء جلسة باستخدام رمز OTP.',
      );
      notifyListeners();
      return result;
    } catch (error, stackTrace) {
      await _adminRepository.addLog(
        actorName: 'النظام',
        role: AdminRole.supportManager,
        action: 'فشل تسجيل الدخول',
        targetType: 'auth',
        targetId: phoneNumber,
        details: error.toString(),
      );
      RuntimeDiagnosticsService.instance.recordError(error, stackTrace, source: 'auth_verify_otp');
      rethrow;
    }
  }

  Future<void> chooseUserType(UserType userType) async {
    final AppUser currentUser = _requireUser();
    _currentUser = await _authRepository.saveUser(
      currentUser.copyWith(userType: userType),
    );
    await _refreshProviderDetails(silent: true);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    required String governorate,
    required String district,
  }) async {
    final AppUser currentUser = _requireUser();
    final String cleanedName = name?.trim() ?? '';
    if (cleanedName.isNotEmpty) {
      SecurityGuardService.instance.validateSafeText(cleanedName, fieldName: 'الاسم', minLength: 2, maxLength: 80);
    }
    _currentUser = await _authRepository.saveUser(
      currentUser.copyWith(
        name: cleanedName.isEmpty ? null : cleanedName,
        governorate: governorate,
        district: district,
      ),
    );
    await _refreshProviderDetails(silent: true);
    notifyListeners();
  }

  Future<void> saveProviderBusinessProfile({
    required String businessName,
    required String phoneNumber,
    required String description,
    required String mainServiceType,
    required String governorate,
    required String district,
    String? coverImageUrl,
    String? logoImageUrl,
    String? workingHours,
    String? whatsAppNumber,
    int customerCount = 0,
    required List<ProviderService> services,
    required List<ProviderGalleryItem> gallery,
    required List<ProviderServiceArea> serviceAreas,
  }) async {
    final AppUser user = _requireUser();
    if (!user.isProvider) {
      throw const AuthException('هذه الميزة متاحة فقط لمقدمي الخدمات.');
    }
    SecurityGuardService.instance.validateSafeText(businessName, fieldName: 'اسم النشاط', minLength: 2, maxLength: 120);
    SecurityGuardService.instance.validateSafeText(description, fieldName: 'وصف النشاط', minLength: 10, maxLength: 1200);
    SecurityGuardService.instance.validateSafeText(mainServiceType, fieldName: 'نوع الخدمة', minLength: 2, maxLength: 80);
    SecurityGuardService.instance.validatePhoneNumber(phoneNumber);
    for (final String image in <String>[coverImageUrl ?? '', logoImageUrl ?? '']) {
      SecurityGuardService.instance.validateImageReference(image);
    }
    final ProviderProfile base = _currentProviderDetails?.profile ??
        ProviderProfile(
          providerId: '',
          userId: user.userId,
          businessName: '',
          phoneNumber: user.phoneNumber,
          description: '',
          mainServiceType: '',
          governorate: governorate,
          district: district,
          status: ProviderAccountStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          customerCount: 0,
        );

    _currentProviderDetails = await _providerRepository.upsertProviderDetails(
      profile: base.copyWith(
        businessName: businessName.trim(),
        phoneNumber: phoneNumber.trim(),
        description: description.trim(),
        mainServiceType: mainServiceType.trim(),
        governorate: governorate,
        district: district,
        coverImageUrl: (coverImageUrl ?? '').trim().isEmpty ? null : coverImageUrl!.trim(),
        clearCoverImageUrl: (coverImageUrl ?? '').trim().isEmpty,
        logoImageUrl: (logoImageUrl ?? '').trim().isEmpty ? null : logoImageUrl!.trim(),
        clearLogoImageUrl: (logoImageUrl ?? '').trim().isEmpty,
        workingHours: (workingHours ?? '').trim().isEmpty ? null : workingHours!.trim(),
        clearWorkingHours: (workingHours ?? '').trim().isEmpty,
        whatsAppNumber: (whatsAppNumber ?? '').trim().isEmpty ? null : whatsAppNumber!.trim(),
        clearWhatsAppNumber: (whatsAppNumber ?? '').trim().isEmpty,
        customerCount: customerCount,
      ),
      services: services,
      gallery: gallery,
      serviceAreas: serviceAreas,
    );
    notifyListeners();
  }

  Future<void> saveProviderAccountStatus(ProviderAccountStatus status) async {
    final ProviderDetails provider = _requireProviderDetails();
    _currentProviderDetails = await _providerRepository.saveProviderStatus(
      providerId: provider.profile.providerId,
      status: status,
    );
    notifyListeners();
  }

  Future<void> saveProviderSubscription({
    required String planType,
    required DateTime startDate,
    required DateTime endDate,
    required SubscriptionStatus status,
    required PaymentStatus paymentStatus,
  }) async {
    final ProviderDetails provider = _requireProviderDetails();
    _currentProviderDetails = await _providerRepository.saveSubscription(
      ProviderSubscription(
        subscriptionId: provider.subscription?.subscriptionId ?? '',
        providerId: provider.profile.providerId,
        planType: planType,
        startDate: startDate,
        endDate: endDate,
        status: status,
        paymentStatus: paymentStatus,
      ),
    );
    await _adminRepository.addLog(
      actorName: _adminActorName,
      role: AdminRole.subscriptionsManager,
      action: 'تفعيل الاشتراك',
      targetType: 'subscription',
      targetId: _currentProviderDetails?.subscription?.subscriptionId ?? provider.profile.providerId,
      details: 'تم حفظ اشتراك مقدم الخدمة ${provider.profile.businessName}.',
    );
    notifyListeners();
  }

  Future<void> addProviderReview({
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    final ProviderDetails provider = _requireProviderDetails();
    _currentProviderDetails = await _providerRepository.addReview(
      providerId: provider.profile.providerId,
      customerName: customerName.trim(),
      rating: rating,
      comment: comment.trim(),
    );
    notifyListeners();
  }

  Future<OrderCreationResult> createServiceOrder({
    required String serviceType,
    required String description,
    required OrderLocation location,
    required String phoneNumber,
  }) async {
    final AppUser user = _requireUser();
    SecurityGuardService.instance.checkRateLimit(
      key: 'order:${user.userId}',
      maxAttempts: 6,
      window: const Duration(minutes: 5),
      message: 'تم إنشاء عدة طلبات بسرعة. انتظر قليلاً قبل إرسال طلب جديد.',
    );
    SecurityGuardService.instance.validateSafeText(serviceType, fieldName: 'نوع الخدمة', minLength: 2, maxLength: 80);
    SecurityGuardService.instance.validateSafeText(description, fieldName: 'وصف الطلب', minLength: 8, maxLength: 1200);
    SecurityGuardService.instance.validatePhoneNumber(phoneNumber);
    final OrderCreationResult result = await _orderRepository.createOrder(
      user: user,
      serviceType: serviceType,
      description: description,
      location: location,
      phoneNumber: phoneNumber,
    );
    await _adminRepository.addLog(
      actorName: user.displayName,
      role: AdminRole.supportManager,
      action: 'إنشاء طلب',
      targetType: 'order',
      targetId: result.order.orderId,
      details: 'تم إنشاء طلب ${result.order.serviceType} في ${result.order.locationText}.',
    );
    notifyListeners();
    return result;
  }

  Future<ServiceOrder> acceptProviderOrder(String orderId) async {
    final ProviderDetails provider = _requireProviderDetails();
    final ServiceOrder order = await _orderRepository.acceptOrder(
      providerId: provider.profile.providerId,
      orderId: orderId,
    );
    notifyListeners();
    return order;
  }

  Future<ServiceOrder> rejectProviderOrder(String orderId) async {
    final ProviderDetails provider = _requireProviderDetails();
    final ServiceOrder order = await _orderRepository.rejectOrder(
      providerId: provider.profile.providerId,
      orderId: orderId,
    );
    notifyListeners();
    return order;
  }

  Future<ServiceOrder> cancelClientOrder(String orderId) async {
    final AppUser user = _requireUser();
    final ServiceOrder order = await _orderRepository.cancelOrder(
      userId: user.userId,
      orderId: orderId,
    );
    notifyListeners();
    return order;
  }

  Future<ServiceOrder> updateProviderOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final ProviderDetails provider = _requireProviderDetails();
    final ServiceOrder order = await _orderRepository.updateOrderStatus(
      providerId: provider.profile.providerId,
      orderId: orderId,
      status: status,
    );
    notifyListeners();
    return order;
  }

  Future<void> markAllNotificationsAsRead() async {
    final AppUser user = _requireUser();
    await _orderRepository.markAllNotificationsAsRead(user.userId);
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final AppUser user = _requireUser();
    await _orderRepository.markNotificationAsRead(
      userId: user.userId,
      notificationId: notificationId,
    );
    notifyListeners();
  }

  Future<AdListing> createAdListing({
    required String title,
    required String description,
    required double priceBefore,
    required double priceAfter,
    required List<String> images,
    required AdCategory category,
    required String phoneNumber,
    required String locationText,
    required DealType dealType,
    DateTime? expiresAt,
  }) async {
    final AppUser user = _requireUser();
    SecurityGuardService.instance.checkRateLimit(
      key: 'ad:${user.userId}',
      maxAttempts: 5,
      window: const Duration(hours: 1),
      message: 'تم إنشاء إعلانات كثيرة خلال وقت قصير. حاول لاحقاً.',
    );
    SecurityGuardService.instance.validateSafeText(title, fieldName: 'عنوان الإعلان', minLength: 3, maxLength: 120);
    SecurityGuardService.instance.validateSafeText(description, fieldName: 'وصف الإعلان', minLength: 10, maxLength: 1500);
    SecurityGuardService.instance.validatePrice(priceBefore, fieldName: 'السعر قبل الخصم');
    SecurityGuardService.instance.validatePrice(priceAfter, fieldName: 'السعر بعد الخصم');
    SecurityGuardService.instance.validatePhoneNumber(phoneNumber);
    for (final String image in images) {
      SecurityGuardService.instance.validateImageReference(image);
    }
    final bool hasRecentDuplicate = myAds.any((AdListing item) =>
        item.title.trim() == title.trim() &&
        item.description.trim() == description.trim() &&
        DateTime.now().difference(item.createdAt) < const Duration(hours: 24));
    if (hasRecentDuplicate) {
      throw const AuthException('يوجد إعلان مشابه تم إنشاؤه خلال آخر 24 ساعة.');
    }
    final AdListing ad = await _adRepository.createAd(
      user: user,
      title: title,
      description: description,
      priceBefore: priceBefore,
      priceAfter: priceAfter,
      images: images,
      category: category,
      phoneNumber: phoneNumber,
      locationText: locationText,
      dealType: dealType,
      expiresAt: expiresAt,
    );
    await _adminRepository.addLog(
      actorName: user.displayName,
      role: AdminRole.contentManager,
      action: 'إنشاء إعلان',
      targetType: 'ad',
      targetId: ad.adId,
      details: 'تم إنشاء إعلان ${ad.title}.',
    );
    notifyListeners();
    return ad;
  }

  AdListing? findAdById(String adId) => _adRepository.getAdById(adId);

  List<AdListing> adsByCategory(AdCategory category) => _adRepository.getAdsByCategory(category);

  AppUser? findUserById(String userId) => _orderRepository.getUserById(userId);

  ProviderDetails? findProviderById(String providerId) => _orderRepository.getProviderById(providerId);

  List<SmartSearchResult> smartSearch({
    required String query,
    required SmartSearchFilters filters,
    int limit = 80,
  }) {
    return _searchRepository.search(
      query: query,
      filters: filters,
      currentUser: _currentUser,
      limit: limit,
    );
  }

  List<String> smartSearchSuggestions({
    required String query,
    required SmartSearchFilters filters,
    int limit = 8,
  }) {
    return _searchRepository.suggestions(query: query, filters: filters, limit: limit);
  }

  List<String> searchableServiceTypes() => _searchRepository.serviceTypes();

  bool isFavoriteAd(String adId) => _currentUser != null && _favoriteRepository.isFavorite(
        userId: _currentUser!.userId,
        itemId: adId,
        type: FavoriteItemType.ad,
      );

  bool isFavoriteProvider(String providerId) => _currentUser != null && _favoriteRepository.isFavorite(
        userId: _currentUser!.userId,
        itemId: providerId,
        type: FavoriteItemType.provider,
      );

  Future<bool> toggleFavoriteAd(String adId) async {
    final AppUser user = _requireUser();
    final bool isAdded = await _favoriteRepository.toggleFavorite(
      userId: user.userId,
      itemId: adId,
      type: FavoriteItemType.ad,
    );
    notifyListeners();
    return isAdded;
  }

  Future<bool> toggleFavoriteProvider(String providerId) async {
    final AppUser user = _requireUser();
    final bool isAdded = await _favoriteRepository.toggleFavorite(
      userId: user.userId,
      itemId: providerId,
      type: FavoriteItemType.provider,
    );
    notifyListeners();
    return isAdded;
  }

  Future<void> removeFavorite({
    required String itemId,
    required FavoriteItemType type,
  }) async {
    final AppUser user = _requireUser();
    await _favoriteRepository.removeFavorite(userId: user.userId, itemId: itemId, type: type);
    notifyListeners();
  }

  String resolveUserDisplayName(String userId) =>
      _orderRepository.getUserById(userId)?.displayName ?? 'عميل مكان';

  String resolveProviderName(String providerId) =>
      _orderRepository.getProviderById(providerId)?.profile.businessName ?? 'مقدم خدمة';

  Future<void> refreshProviderDetails() async {
    await _refreshProviderDetails();
  }

  Future<void> refreshBackendData() async {
    await RuntimeDiagnosticsService.instance.trackAsync('backend_refresh', () async {
      await _authRepository.refreshRemoteCache();
      await _refreshProviderDetails(silent: true);
    });
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _activeOtpChallenge = null;
    _currentProviderDetails = null;
    notifyListeners();
  }

  String resolveAuthenticatedHomeRoute() {
    if (!isAuthenticated) {
      return AppRoutes.login;
    }
    if (needsUserTypeSelection) {
      return AppRoutes.accountType;
    }
    if (needsProfileCompletion) {
      return AppRoutes.editProfile;
    }
    if (needsProviderSetup) {
      return AppRoutes.providerSetup;
    }
    return AppRoutes.home;
  }

  Future<void> _refreshProviderDetails({bool silent = false}) async {
    if (_currentUser == null || !_currentUser!.isProvider) {
      _currentProviderDetails = null;
      if (!silent) {
        notifyListeners();
      }
      return;
    }
    _currentProviderDetails = _providerRepository.getProviderDetailsByUserId(_currentUser!.userId);
    if (!silent) {
      notifyListeners();
    }
  }

  ProviderDetails _requireProviderDetails() {
    final ProviderDetails? details = _currentProviderDetails;
    if (details == null) {
      throw const AuthException('أكمل ملف مقدم الخدمة أولاً.');
    }
    return details;
  }

  AppUser _requireUser() {
    final AppUser? user = _currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم حالية.');
    }
    return user;
  }


  List<AdListing> pagedActiveAds({int page = 0, int pageSize = 20}) {
    return _paginate(activeAds, page: page, pageSize: pageSize);
  }

  List<ProviderDetails> pagedVisibleProviders({int page = 0, int pageSize = 20}) {
    return _paginate(visibleProviderDetails, page: page, pageSize: pageSize);
  }

  List<T> _paginate<T>(List<T> items, {required int page, required int pageSize}) {
    final int safePage = page < 0 ? 0 : page;
    final int safePageSize = pageSize < 1 ? 1 : (pageSize > 100 ? 100 : pageSize);
    final int start = safePage * safePageSize;
    if (start >= items.length) {
      return <T>[];
    }
    final int end = (start + safePageSize) > items.length ? items.length : start + safePageSize;
    return items.sublist(start, end);
  }

  Future<void> updateAdvancedSettings({
    ThemeMode? themeMode,
    Locale? locale,
    bool? pushNotificationsEnabled,
    bool? marketingNotificationsEnabled,
    bool? performanceDiagnosticsEnabled,
  }) async {
    final AppLanguage language = locale == null
        ? _settings.language
        : appLanguageFromValue(locale.languageCode);
    _settings = _settings.copyWith(
      themeMode: themeMode,
      language: language,
      pushNotificationsEnabled: pushNotificationsEnabled,
      marketingNotificationsEnabled: marketingNotificationsEnabled,
      performanceDiagnosticsEnabled: performanceDiagnosticsEnabled,
      updatedAt: DateTime.now(),
    );
    _themeMode = _settings.themeMode;
    _locale = _settings.locale;
    await _storage.saveAppSettings(_settings);
    notifyListeners();
  }

  Future<void> recordRuntimeError(Object error, StackTrace? stackTrace, {String source = 'runtime'}) async {
    RuntimeDiagnosticsService.instance.recordError(error, stackTrace, source: source);
    await _adminRepository.addLog(
      actorName: 'النظام',
      role: AdminRole.supportManager,
      action: 'خطأ تطبيق',
      targetType: 'runtime_error',
      targetId: source,
      details: error.toString(),
    );
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    _settings = _settings.copyWith(language: appLanguageFromValue(locale.languageCode), updatedAt: DateTime.now());
    _storage.saveAppSettings(_settings);
    notifyListeners();
  }

  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode == themeMode) {
      return;
    }
    _themeMode = themeMode;
    _settings = _settings.copyWith(themeMode: themeMode, updatedAt: DateTime.now());
    _storage.saveAppSettings(_settings);
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({required this.controller, required super.child, super.key})
    : super(notifier: controller);

  final AppController controller;

  static AppController of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing in the widget tree.');
    return scope!.controller;
  }
}
