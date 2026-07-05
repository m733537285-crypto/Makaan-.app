import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend_config.dart';
import '../backend/firebase_backend_client.dart';
import '../backend/cloud_storage_service.dart';
import '../backend/push_notification_service.dart';
import '../backend/remote_backend_client.dart';
import '../backend/supabase_backend_client.dart';
import '../models/ad_models.dart';
import '../models/admin_models.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../models/favorite_models.dart';
import '../models/order_models.dart';
import '../models/otp_challenge.dart';
import '../models/provider_models.dart';

class AppStorageService {
  AppStorageService._(
    this._preferences,
    this._secureStorage,
    this._backend,
    this._cloudStorage,
    this._pushNotifications,
  );

  static const String _usersKey = 'auth.users';
  static const String _otpKey = 'auth.otp.active';
  static const String _sessionUserIdKey = 'auth.session.userId';
  static const String _sessionMirrorTokenKey = 'auth.session.tokenMirror';
  static const String _sessionCreatedAtKey = 'auth.session.createdAt';
  static const String _secureSessionTokenKey = 'auth.session.token';
  static const String _onboardingKey = 'app.onboardingCompleted';
  static const String _providerProfilesKey = 'providers.profiles';
  static const String _providerServicesKey = 'providers.services';
  static const String _providerGalleryKey = 'providers.gallery';
  static const String _providerAreasKey = 'providers.areas';
  static const String _providerSubscriptionsKey = 'providers.subscriptions';
  static const String _providerReviewsKey = 'providers.reviews';
  static const String _ordersKey = 'orders.records';
  static const String _notificationsKey = 'notifications.records';
  static const String _adsKey = 'ads.records';
  static const String _favoritesKey = 'favorites.records';
  static const String _adminLogsKey = 'admin.logs';
  static const String _adminReportsKey = 'admin.reports';
  static const String _adminLocationsKey = 'admin.locations';
  static const String _adminCategoriesKey = 'admin.categories';
  static const String _appSettingsKey = 'app.settings.phase10';

  static const List<RemoteCollectionSpec> _remoteCollections = <RemoteCollectionSpec>[
    RemoteCollectionSpec(localKey: _usersKey, table: 'app_users', idField: 'userId'),
    RemoteCollectionSpec(localKey: _providerProfilesKey, table: 'provider_profiles', idField: 'providerId', ownerField: 'userId'),
    RemoteCollectionSpec(localKey: _providerServicesKey, table: 'provider_services', idField: 'serviceId', ownerField: 'providerId'),
    RemoteCollectionSpec(localKey: _providerGalleryKey, table: 'provider_gallery', idField: 'imageId', ownerField: 'providerId'),
    RemoteCollectionSpec(localKey: _providerAreasKey, table: 'provider_service_areas', idField: 'areaId', ownerField: 'providerId'),
    RemoteCollectionSpec(localKey: _providerSubscriptionsKey, table: 'provider_subscriptions', idField: 'subscriptionId', ownerField: 'providerId'),
    RemoteCollectionSpec(localKey: _providerReviewsKey, table: 'provider_reviews', idField: 'reviewId', ownerField: 'providerId'),
    RemoteCollectionSpec(localKey: _ordersKey, table: 'service_orders', idField: 'orderId', ownerField: 'userId'),
    RemoteCollectionSpec(localKey: _notificationsKey, table: 'in_app_notifications', idField: 'notificationId', ownerField: 'userId'),
    RemoteCollectionSpec(localKey: _adsKey, table: 'ad_listings', idField: 'adId', ownerField: 'userId'),
    RemoteCollectionSpec(localKey: _favoritesKey, table: 'favorite_items', idField: 'favoriteId', ownerField: 'userId'),
    RemoteCollectionSpec(localKey: _adminLogsKey, table: 'admin_system_logs', idField: 'logId'),
    RemoteCollectionSpec(localKey: _adminReportsKey, table: 'admin_report_tickets', idField: 'reportId'),
    RemoteCollectionSpec(localKey: _adminLocationsKey, table: 'managed_locations', idField: 'governorate'),
    RemoteCollectionSpec(localKey: _adminCategoriesKey, table: 'managed_categories', idField: 'categoryId'),
  ];

  final SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage;
  final RemoteBackendClient? _backend;
  final CloudStorageService _cloudStorage;
  final PushNotificationService _pushNotifications;
  String? _lastBackendError;

  static Future<AppStorageService> create() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    const FlutterSecureStorage secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final BackendConfig config = BackendConfig.fromEnvironment();
    final RemoteBackendClient? backend = Firebase.apps.isNotEmpty
        ? FirebaseBackendClient()
        : (config.isConfigured ? SupabaseBackendClient(config) : null);
    final AppStorageService service = AppStorageService._(
      preferences,
      secureStorage,
      backend,
      CloudStorageService(backend),
      PushNotificationService(backend),
    );
    await service.loadSession();
    await service.syncFromBackend();
    return service;
  }

  bool get onboardingCompleted => _preferences.getBool(_onboardingKey) ?? false;
  bool get isRemoteBackendEnabled => _backend?.isEnabled ?? false;
  String? get lastBackendError => _lastBackendError;

  Future<void> syncFromBackend() async {
    if (!isRemoteBackendEnabled) {
      return;
    }
    try {
      for (final RemoteCollectionSpec spec in _remoteCollections) {
        final List<Map<String, dynamic>> items = await _backend!.listCollection(spec);
        await _preferences.setString(spec.localKey, jsonEncode(items));
      }
      _lastBackendError = null;
    } catch (error) {
      _lastBackendError = error.toString();
    }
  }

  Future<void> requestRemoteOtp(String phoneNumber) async {
    await _backend!.requestPhoneOtp(phoneNumber);
  }

  Future<RemoteOtpVerificationResult> verifyRemoteOtp({
    required String phoneNumber,
    required String code,
  }) {
    return _backend!.verifyPhoneOtp(phoneNumber: phoneNumber, token: code);
  }

  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String ownerUserId,
    required String folder,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    return _cloudStorage.uploadImageBytes(
      bytes: bytes,
      ownerUserId: ownerUserId,
      folder: folder,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _pushNotifications.registerDeviceToken(userId: userId, token: token, platform: platform);
  }

  Future<void> registerCurrentPushDevice(String userId) {
    return _pushNotifications.registerCurrentDevice(userId: userId);
  }

  Future<void> enqueuePushNotification({
    required String userId,
    required String title,
    required String body,
    required String eventType,
    String? targetId,
  }) {
    return _pushNotifications.enqueueNotification(
      userId: userId,
      title: title,
      body: body,
      eventType: eventType,
      targetId: targetId,
    );
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _preferences.setBool(_onboardingKey, value);
  }

  List<AppUser> loadUsers() {
    return _readList<AppUser>(
      _usersKey,
      (Map<String, dynamic> json) => AppUser.fromJson(json),
    );
  }

  Future<void> saveUsers(List<AppUser> users) async {
    await _writeList<AppUser>(_usersKey, users, (AppUser item) => item.toJson());
  }

  OtpChallenge? loadActiveOtpChallenge() {
    final String? raw = _preferences.getString(_otpKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return OtpChallenge.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _preferences.remove(_otpKey);
      return null;
    }
  }

  Future<void> saveActiveOtpChallenge(OtpChallenge challenge) async {
    await _preferences.setString(_otpKey, jsonEncode(challenge.toJson()));
  }

  Future<void> clearActiveOtpChallenge() async {
    await _preferences.remove(_otpKey);
  }

  Future<void> saveSession(AuthSession session) async {
    await _preferences.setString(_sessionUserIdKey, session.userId);
    await _preferences.setString(_sessionMirrorTokenKey, session.token);
    await _preferences.setString(
      _sessionCreatedAtKey,
      session.createdAt.toIso8601String(),
    );
    await _secureStorage.write(key: _secureSessionTokenKey, value: session.token);
    _backend?.setAccessToken(session.token);
  }

  Future<AuthSession?> loadSession() async {
    final String? userId = _preferences.getString(_sessionUserIdKey);
    final String? mirrorToken = _preferences.getString(_sessionMirrorTokenKey);
    final String? createdAt = _preferences.getString(_sessionCreatedAtKey);
    final String? secureToken = await _secureStorage.read(key: _secureSessionTokenKey);
    if (userId == null ||
        mirrorToken == null ||
        secureToken == null ||
        createdAt == null ||
        mirrorToken != secureToken) {
      return null;
    }
    try {
      final AuthSession session = AuthSession(
        userId: userId,
        token: secureToken,
        createdAt: DateTime.parse(createdAt),
      );
      _backend?.setAccessToken(secureToken);
      return session;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    await _preferences.remove(_sessionUserIdKey);
    await _preferences.remove(_sessionMirrorTokenKey);
    await _preferences.remove(_sessionCreatedAtKey);
    await _secureStorage.delete(key: _secureSessionTokenKey);
    _backend?.setAccessToken(null);
  }

  List<ProviderProfile> loadProviderProfiles() {
    return _readList<ProviderProfile>(
      _providerProfilesKey,
      (Map<String, dynamic> json) => ProviderProfile.fromJson(json),
    );
  }

  Future<void> saveProviderProfiles(List<ProviderProfile> items) async {
    await _writeList<ProviderProfile>(
      _providerProfilesKey,
      items,
      (ProviderProfile item) => item.toJson(),
    );
  }

  List<ProviderService> loadProviderServices() {
    return _readList<ProviderService>(
      _providerServicesKey,
      (Map<String, dynamic> json) => ProviderService.fromJson(json),
    );
  }

  Future<void> saveProviderServices(List<ProviderService> items) async {
    await _writeList<ProviderService>(
      _providerServicesKey,
      items,
      (ProviderService item) => item.toJson(),
    );
  }

  List<ProviderGalleryItem> loadProviderGalleryItems() {
    return _readList<ProviderGalleryItem>(
      _providerGalleryKey,
      (Map<String, dynamic> json) => ProviderGalleryItem.fromJson(json),
    );
  }

  Future<void> saveProviderGalleryItems(List<ProviderGalleryItem> items) async {
    await _writeList<ProviderGalleryItem>(
      _providerGalleryKey,
      items,
      (ProviderGalleryItem item) => item.toJson(),
    );
  }

  List<ProviderServiceArea> loadProviderServiceAreas() {
    return _readList<ProviderServiceArea>(
      _providerAreasKey,
      (Map<String, dynamic> json) => ProviderServiceArea.fromJson(json),
    );
  }

  Future<void> saveProviderServiceAreas(List<ProviderServiceArea> items) async {
    await _writeList<ProviderServiceArea>(
      _providerAreasKey,
      items,
      (ProviderServiceArea item) => item.toJson(),
    );
  }

  List<ProviderSubscription> loadProviderSubscriptions() {
    return _readList<ProviderSubscription>(
      _providerSubscriptionsKey,
      (Map<String, dynamic> json) => ProviderSubscription.fromJson(json),
    );
  }

  Future<void> saveProviderSubscriptions(List<ProviderSubscription> items) async {
    await _writeList<ProviderSubscription>(
      _providerSubscriptionsKey,
      items,
      (ProviderSubscription item) => item.toJson(),
    );
  }

  List<ProviderReview> loadProviderReviews() {
    return _readList<ProviderReview>(
      _providerReviewsKey,
      (Map<String, dynamic> json) => ProviderReview.fromJson(json),
    );
  }

  Future<void> saveProviderReviews(List<ProviderReview> items) async {
    await _writeList<ProviderReview>(
      _providerReviewsKey,
      items,
      (ProviderReview item) => item.toJson(),
    );
  }

  List<ServiceOrder> loadOrders() {
    return _readList<ServiceOrder>(
      _ordersKey,
      (Map<String, dynamic> json) => ServiceOrder.fromJson(json),
    );
  }

  Future<void> saveOrders(List<ServiceOrder> items) async {
    await _writeList<ServiceOrder>(
      _ordersKey,
      items,
      (ServiceOrder item) => item.toJson(),
    );
  }

  List<InAppNotification> loadNotifications() {
    return _readList<InAppNotification>(
      _notificationsKey,
      (Map<String, dynamic> json) => InAppNotification.fromJson(json),
    );
  }

  Future<void> saveNotifications(List<InAppNotification> items) async {
    await _writeList<InAppNotification>(
      _notificationsKey,
      items,
      (InAppNotification item) => item.toJson(),
    );
  }

  List<AdListing> loadAds() {
    return _readList<AdListing>(
      _adsKey,
      (Map<String, dynamic> json) => AdListing.fromJson(json),
    );
  }

  Future<void> saveAds(List<AdListing> items) async {
    await _writeList<AdListing>(
      _adsKey,
      items,
      (AdListing item) => item.toJson(),
    );
  }

  List<FavoriteItem> loadFavorites() {
    return _readList<FavoriteItem>(
      _favoritesKey,
      (Map<String, dynamic> json) => FavoriteItem.fromJson(json),
    );
  }

  Future<void> saveFavorites(List<FavoriteItem> items) async {
    await _writeList<FavoriteItem>(
      _favoritesKey,
      items,
      (FavoriteItem item) => item.toJson(),
    );
  }

  List<AdminSystemLog> loadAdminLogs() {
    return _readList<AdminSystemLog>(
      _adminLogsKey,
      (Map<String, dynamic> json) => AdminSystemLog.fromJson(json),
    );
  }

  Future<void> saveAdminLogs(List<AdminSystemLog> items) async {
    await _writeList<AdminSystemLog>(
      _adminLogsKey,
      items,
      (AdminSystemLog item) => item.toJson(),
    );
  }

  List<AdminReportTicket> loadAdminReports() {
    return _readList<AdminReportTicket>(
      _adminReportsKey,
      (Map<String, dynamic> json) => AdminReportTicket.fromJson(json),
    );
  }

  Future<void> saveAdminReports(List<AdminReportTicket> items) async {
    await _writeList<AdminReportTicket>(
      _adminReportsKey,
      items,
      (AdminReportTicket item) => item.toJson(),
    );
  }

  List<AdminManagedLocation> loadAdminLocations() {
    return _readList<AdminManagedLocation>(
      _adminLocationsKey,
      (Map<String, dynamic> json) => AdminManagedLocation.fromJson(json),
    );
  }

  Future<void> saveAdminLocations(List<AdminManagedLocation> items) async {
    await _writeList<AdminManagedLocation>(
      _adminLocationsKey,
      items,
      (AdminManagedLocation item) => item.toJson(),
    );
  }

  List<AdminManagedCategory> loadAdminCategories() {
    return _readList<AdminManagedCategory>(
      _adminCategoriesKey,
      (Map<String, dynamic> json) => AdminManagedCategory.fromJson(json),
    );
  }

  Future<void> saveAdminCategories(List<AdminManagedCategory> items) async {
    await _writeList<AdminManagedCategory>(
      _adminCategoriesKey,
      items,
      (AdminManagedCategory item) => item.toJson(),
    );
  }


  AppSettings loadAppSettings() {
    final String? raw = _preferences.getString(_appSettingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings.defaults();
    }
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    await _preferences.setString(_appSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> deleteBackendRecord({required String table, required String id}) async {
    if (!isRemoteBackendEnabled) {
      return;
    }
    final RemoteCollectionSpec? spec = _specForTable(table);
    if (spec == null) {
      return;
    }
    try {
      await _backend!.deleteCollectionRow(spec: spec, id: id);
      _lastBackendError = null;
    } catch (error) {
      _lastBackendError = error.toString();
    }
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final String? raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        _preferences.remove(key);
        return <T>[];
      }
      final List<T> result = <T>[];
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          result.add(fromJson(item));
        } else if (item is Map) {
          result.add(fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return result;
    } catch (_) {
      _preferences.remove(key);
      return <T>[];
    }
  }

  Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) async {
    final List<Map<String, dynamic>> encodedItems = items.map<Map<String, dynamic>>(toJson).toList(growable: false);
    await _preferences.setString(key, jsonEncode(encodedItems));
    await _mirrorListToBackend(key, encodedItems);
  }

  Future<void> _mirrorListToBackend(String key, List<Map<String, dynamic>> encodedItems) async {
    if (!isRemoteBackendEnabled) {
      return;
    }
    final RemoteCollectionSpec? spec = _specForLocalKey(key);
    if (spec == null) {
      return;
    }
    try {
      await _backend!.replaceCollection(spec: spec, items: encodedItems);
      _lastBackendError = null;
    } catch (error) {
      _lastBackendError = error.toString();
    }
  }

  RemoteCollectionSpec? _specForTable(String table) {
    for (final RemoteCollectionSpec spec in _remoteCollections) {
      if (spec.table == table) {
        return spec;
      }
    }
    return null;
  }

  RemoteCollectionSpec? _specForLocalKey(String key) {
    for (final RemoteCollectionSpec spec in _remoteCollections) {
      if (spec.localKey == key) {
        return spec;
      }
    }
    return null;
  }
}
