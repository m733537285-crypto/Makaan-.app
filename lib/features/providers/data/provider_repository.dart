import '../../../shared/models/provider_models.dart';
import '../../../shared/services/app_storage_service.dart';

class ProviderRepository {
  ProviderRepository(this._storage);

  final AppStorageService _storage;

  List<ProviderDetails> getAllProviderDetails() {
    return _storage
        .loadProviderProfiles()
        .map<ProviderDetails?>((ProviderProfile item) => getProviderDetailsByProviderId(item.providerId))
        .whereType<ProviderDetails>()
        .toList(growable: false);
  }

  ProviderDetails? getProviderDetailsByUserId(String userId) {
    final List<ProviderProfile> profiles = _storage.loadProviderProfiles();
    ProviderProfile? profile;
    for (final ProviderProfile item in profiles) {
      if (item.userId == userId) {
        profile = item;
        break;
      }
    }
    if (profile == null) {
      return null;
    }
    return getProviderDetailsByProviderId(profile.providerId);
  }

  ProviderDetails? getProviderDetailsByProviderId(String providerId) {
    final List<ProviderProfile> profiles = _storage.loadProviderProfiles();
    ProviderProfile? profile;
    for (final ProviderProfile item in profiles) {
      if (item.providerId == providerId) {
        profile = item;
        break;
      }
    }
    if (profile == null) {
      return null;
    }

    final List<ProviderService> services = _storage
        .loadProviderServices()
        .where((ProviderService item) => item.providerId == providerId)
        .toList(growable: false);
    final List<ProviderGalleryItem> gallery = _storage
        .loadProviderGalleryItems()
        .where((ProviderGalleryItem item) => item.providerId == providerId)
        .toList(growable: false);
    final List<ProviderServiceArea> serviceAreas = _storage
        .loadProviderServiceAreas()
        .where((ProviderServiceArea item) => item.providerId == providerId)
        .toList(growable: false);
    final List<ProviderReview> reviews = _storage
        .loadProviderReviews()
        .where((ProviderReview item) => item.providerId == providerId)
        .toList(growable: false);

    ProviderSubscription? subscription;
    for (final ProviderSubscription item in _storage.loadProviderSubscriptions()) {
      if (item.providerId == providerId) {
        subscription = item;
        break;
      }
    }

    return ProviderDetails(
      profile: profile,
      services: services,
      gallery: gallery,
      serviceAreas: serviceAreas,
      reviews: reviews,
      subscription: subscription,
    );
  }

  Future<ProviderDetails> upsertProviderDetails({
    required ProviderProfile profile,
    required List<ProviderService> services,
    required List<ProviderGalleryItem> gallery,
    required List<ProviderServiceArea> serviceAreas,
  }) async {
    final List<ProviderProfile> profiles = _storage.loadProviderProfiles();
    final String providerId = profile.providerId.isEmpty ? _generateId('provider') : profile.providerId;
    final DateTime now = DateTime.now();

    final ProviderProfile normalizedProfile = profile.copyWith(
      providerId: providerId,
      createdAt: profile.providerId.isEmpty ? now : profile.createdAt,
      updatedAt: now,
    );

    final int existingIndex = profiles.indexWhere((ProviderProfile item) => item.providerId == providerId);
    if (existingIndex == -1) {
      profiles.add(normalizedProfile);
    } else {
      profiles[existingIndex] = normalizedProfile;
    }

    final List<ProviderService> allServices = _storage
        .loadProviderServices()
        .where((ProviderService item) => item.providerId != providerId)
        .toList(growable: true);
    for (int index = 0; index < services.length; index++) {
      final ProviderService item = services[index];
      allServices.add(
        ProviderService(
          serviceId: item.serviceId.isEmpty ? _generateId('service_$index') : item.serviceId,
          providerId: providerId,
          title: item.title,
          description: item.description,
          approximatePrice: item.approximatePrice,
          isPrimary: item.isPrimary,
        ),
      );
    }

    final List<ProviderGalleryItem> allGallery = _storage
        .loadProviderGalleryItems()
        .where((ProviderGalleryItem item) => item.providerId != providerId)
        .toList(growable: true);
    for (int index = 0; index < gallery.length; index++) {
      final ProviderGalleryItem item = gallery[index];
      allGallery.add(
        ProviderGalleryItem(
          imageId: item.imageId.isEmpty ? _generateId('gallery_$index') : item.imageId,
          providerId: providerId,
          caption: item.caption,
          category: item.category,
          imageUrl: item.imageUrl,
        ),
      );
    }

    final List<ProviderServiceArea> allAreas = _storage
        .loadProviderServiceAreas()
        .where((ProviderServiceArea item) => item.providerId != providerId)
        .toList(growable: true);
    for (int index = 0; index < serviceAreas.length; index++) {
      final ProviderServiceArea item = serviceAreas[index];
      allAreas.add(
        ProviderServiceArea(
          areaId: item.areaId.isEmpty ? _generateId('area_$index') : item.areaId,
          providerId: providerId,
          governorate: item.governorate,
          district: item.district,
          neighborhood: item.neighborhood,
        ),
      );
    }

    await _storage.saveProviderProfiles(profiles);
    await _storage.saveProviderServices(allServices);
    await _storage.saveProviderGalleryItems(allGallery);
    await _storage.saveProviderServiceAreas(allAreas);

    final List<ProviderSubscription> subscriptions = _storage.loadProviderSubscriptions();
    final bool hasSubscription = subscriptions.any(
      (ProviderSubscription item) => item.providerId == providerId,
    );
    if (!hasSubscription) {
      subscriptions.add(
        ProviderSubscription(
          subscriptionId: _generateId('subscription'),
          providerId: providerId,
          planType: 'Basic',
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          status: SubscriptionStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
      );
      await _storage.saveProviderSubscriptions(subscriptions);
    }

    return getProviderDetailsByProviderId(providerId)!;
  }

  Future<ProviderDetails> saveSubscription(ProviderSubscription subscription) async {
    final List<ProviderSubscription> subscriptions = _storage.loadProviderSubscriptions();
    final int existingIndex = subscriptions.indexWhere(
      (ProviderSubscription item) => item.providerId == subscription.providerId,
    );
    final ProviderSubscription normalized = ProviderSubscription(
      subscriptionId: existingIndex == -1 || subscription.subscriptionId.isEmpty
          ? _generateId('subscription')
          : subscription.subscriptionId,
      providerId: subscription.providerId,
      planType: subscription.planType,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      status: subscription.status,
      paymentStatus: subscription.paymentStatus,
    );
    if (existingIndex == -1) {
      subscriptions.add(normalized);
    } else {
      subscriptions[existingIndex] = normalized;
    }
    await _storage.saveProviderSubscriptions(subscriptions);
    await _syncProviderStatus(subscription.providerId, normalized.status);
    return getProviderDetailsByProviderId(subscription.providerId)!;
  }

  Future<ProviderDetails> addReview({
    required String providerId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    final List<ProviderReview> reviews = _storage.loadProviderReviews().toList(growable: true);
    reviews.add(
      ProviderReview(
        reviewId: _generateId('review'),
        providerId: providerId,
        customerName: customerName,
        rating: rating < 1 ? 1 : (rating > 5 ? 5 : rating),
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
    await _storage.saveProviderReviews(reviews);

    final List<ProviderProfile> profiles = _storage.loadProviderProfiles().toList(growable: true);
    final int index = profiles.indexWhere((ProviderProfile item) => item.providerId == providerId);
    if (index != -1) {
      final ProviderProfile profile = profiles[index];
      final int nextCustomers = profile.customerCount < reviews.where((ProviderReview item) => item.providerId == providerId).length
          ? reviews.where((ProviderReview item) => item.providerId == providerId).length
          : profile.customerCount;
      profiles[index] = profile.copyWith(customerCount: nextCustomers, updatedAt: DateTime.now());
      await _storage.saveProviderProfiles(profiles);
    }

    return getProviderDetailsByProviderId(providerId)!;
  }

  Future<ProviderDetails> saveProviderStatus({
    required String providerId,
    required ProviderAccountStatus status,
  }) async {
    final List<ProviderProfile> profiles = _storage.loadProviderProfiles().toList(growable: true);
    final int index = profiles.indexWhere((ProviderProfile item) => item.providerId == providerId);
    if (index == -1) {
      return getProviderDetailsByProviderId(providerId)!;
    }
    profiles[index] = profiles[index].copyWith(status: status, updatedAt: DateTime.now());
    await _storage.saveProviderProfiles(profiles);
    return getProviderDetailsByProviderId(providerId)!;
  }

  Future<void> _syncProviderStatus(String providerId, SubscriptionStatus status) async {
    final List<ProviderProfile> profiles = _storage.loadProviderProfiles().toList(growable: true);
    final int index = profiles.indexWhere((ProviderProfile item) => item.providerId == providerId);
    if (index == -1) {
      return;
    }
    final ProviderProfile current = profiles[index];
    if (current.status == ProviderAccountStatus.suspended) {
      return;
    }
    ProviderAccountStatus nextStatus;
    switch (status) {
      case SubscriptionStatus.active:
        nextStatus = ProviderAccountStatus.active;
        break;
      case SubscriptionStatus.expired:
        nextStatus = ProviderAccountStatus.expired;
        break;
      case SubscriptionStatus.pending:
        nextStatus = ProviderAccountStatus.pending;
        break;
    }
    profiles[index] = current.copyWith(status: nextStatus, updatedAt: DateTime.now());
    await _storage.saveProviderProfiles(profiles);
  }

  String _generateId(String prefix) {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }
}
