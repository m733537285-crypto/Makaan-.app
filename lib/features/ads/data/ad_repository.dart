import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/models/ad_models.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/order_models.dart';
import '../../../shared/services/app_storage_service.dart';

class AdRepository {
  AdRepository(this._storage);

  final AppStorageService _storage;

  static const List<AdCategory> supportedCategories = <AdCategory>[
    AdCategory.cars,
    AdCategory.realEstate,
    AdCategory.restaurants,
    AdCategory.services,
    AdCategory.electronics,
    AdCategory.groceries,
    AdCategory.other,
  ];

  static const List<DealType> supportedDealTypes = <DealType>[
    DealType.standard,
    DealType.todayDeal,
    DealType.halfPrice,
    DealType.limitedTime,
    DealType.discountedService,
  ];

  Future<void> ensureSeedData() async {
    final List<AdListing> existing = _storage.loadAds();
    if (existing.isNotEmpty) {
      await _syncExpiredAds(existing);
      return;
    }
    await _storage.saveAds(_seedAds());
  }

  List<AdListing> getAllAds({bool includeInactive = false}) {
    final List<AdListing> items = _normalizeStatuses(_storage.loadAds());
    final Iterable<AdListing> filtered = includeInactive
        ? items
        : items.where((AdListing item) => item.effectiveStatus == AdStatus.active);
    final List<AdListing> result = filtered.toList(growable: false);
    result.sort((AdListing a, AdListing b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<AdListing> getBannerAds() {
    final List<AdListing> items = getAllAds()
        .where((AdListing item) => item.isBanner)
        .toList(growable: false);
    if (items.isNotEmpty) {
      return items;
    }
    return getFeaturedAds().take(4).toList(growable: false);
  }

  List<AdListing> getFeaturedAds() {
    final List<AdListing> items = getAllAds()
        .where((AdListing item) => item.isFeatured || item.dealType != DealType.standard)
        .toList(growable: false);
    items.sort((AdListing a, AdListing b) {
      final int typeRank = _dealPriority(b.dealType).compareTo(_dealPriority(a.dealType));
      if (typeRank != 0) {
        return typeRank;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  List<AdListing> getTodayDeals() {
    return getAllAds().where((AdListing item) => item.dealType == DealType.todayDeal).toList(growable: false);
  }

  List<AdListing> getHalfPriceDeals() {
    return getAllAds()
        .where((AdListing item) => item.dealType == DealType.halfPrice || item.discountPercent >= 45)
        .toList(growable: false);
  }

  List<AdListing> getAdsByCategory(AdCategory category) {
    return getAllAds().where((AdListing item) => item.category == category).toList(growable: false);
  }

  List<AdListing> getProductAds() {
    return getAllAds()
        .where((AdListing item) =>
            item.category == AdCategory.electronics ||
            item.category == AdCategory.groceries ||
            item.category == AdCategory.other)
        .toList(growable: false);
  }

  List<AdListing> getDiscountedServiceAds() {
    return getAllAds()
        .where((AdListing item) =>
            item.category == AdCategory.services ||
            item.category == AdCategory.restaurants ||
            item.dealType == DealType.discountedService)
        .toList(growable: false);
  }

  List<AdListing> getAdsForUser(String userId) {
    final List<AdListing> items = getAllAds(includeInactive: true)
        .where((AdListing item) => item.userId == userId)
        .toList(growable: false);
    items.sort((AdListing a, AdListing b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  AdListing? getAdById(String adId) {
    for (final AdListing item in getAllAds(includeInactive: true)) {
      if (item.adId == adId) {
        return item;
      }
    }
    return null;
  }

  Future<AdListing> createAd({
    required AppUser user,
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
    final String cleanedTitle = title.trim();
    final String cleanedDescription = description.trim();
    final String cleanedPhone = _normalizePhone(phoneNumber);
    final String cleanedLocation = locationText.trim();
    final List<String> cleanedImages = images
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);

    if (cleanedTitle.length < 4) {
      throw const AuthException('عنوان الإعلان يجب أن يكون أوضح وبحد أدنى 4 أحرف.');
    }
    if (cleanedDescription.length < 12) {
      throw const AuthException('اكتب وصفاً أوضح للإعلان بما لا يقل عن 12 حرفاً.');
    }
    if (!_isValidPhone(cleanedPhone)) {
      throw const AuthException('رقم التواصل غير صحيح. استخدم من 9 إلى 15 رقماً.');
    }
    if (cleanedLocation.length < 3) {
      throw const AuthException('أدخل الموقع النصي للإعلان.');
    }
    if (cleanedImages.isEmpty) {
      throw const AuthException('أضف صورة واحدة على الأقل للإعلان.');
    }
    if (priceAfter <= 0) {
      throw const AuthException('السعر الحالي يجب أن يكون أكبر من صفر.');
    }
    if (priceBefore > 0 && priceBefore < priceAfter) {
      throw const AuthException('السعر قبل الخصم يجب أن يكون أكبر من أو يساوي السعر الحالي.');
    }
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
      throw const AuthException('تاريخ انتهاء العرض يجب أن يكون في المستقبل.');
    }

    final List<AdListing> current = _normalizeStatuses(_storage.loadAds()).toList(growable: true);
    final String dedupeKey = _buildDuplicateKey(
      userId: user.userId,
      title: cleanedTitle,
      category: category,
      locationText: cleanedLocation,
    );
    final bool duplicateExists = current.any(
      (AdListing item) =>
          item.effectiveStatus != AdStatus.rejected &&
          _buildDuplicateKey(
                userId: item.userId,
                title: item.title,
                category: item.category,
                locationText: item.locationText,
              ) ==
              dedupeKey,
    );
    if (duplicateExists) {
      throw const AuthException('يوجد إعلان مشابه بالفعل لهذا المستخدم في نفس التصنيف والموقع.');
    }

    final DateTime now = DateTime.now();
    final AdListing ad = AdListing(
      adId: _generateId('ad'),
      userId: user.userId,
      title: cleanedTitle,
      description: cleanedDescription,
      priceBefore: priceBefore,
      priceAfter: priceAfter,
      images: cleanedImages,
      category: category,
      phoneNumber: cleanedPhone,
      locationText: cleanedLocation,
      createdAt: now,
      expiresAt: expiresAt,
      status: AdStatus.active,
      dealType: dealType,
      ownerName: user.displayName,
      isBanner: false,
      isFeatured: dealType != DealType.standard,
    );

    current.add(ad);
    await _storage.saveAds(current);

    final List<InAppNotification> notifications = _storage.loadNotifications().toList(growable: true);
    notifications.add(
      InAppNotification(
        notificationId: _generateId('notification'),
        userId: user.userId,
        title: 'تم نشر الإعلان',
        body: 'أصبح إعلان "$cleanedTitle" متاحاً داخل سوق مكان.',
        createdAt: now,
        type: NotificationType.general,
      ),
    );
    await _storage.saveNotifications(notifications);
    return ad;
  }

  Future<void> _syncExpiredAds(List<AdListing> source) async {
    final List<AdListing> normalized = _normalizeStatuses(source);
    bool changed = false;
    for (int index = 0; index < source.length; index++) {
      if (source[index].status != normalized[index].status) {
        changed = true;
        break;
      }
    }
    if (changed) {
      await _storage.saveAds(normalized);
    }
  }

  List<AdListing> _normalizeStatuses(List<AdListing> items) {
    return items
        .map(
          (AdListing item) => item.status == AdStatus.active && item.isExpiredByTime
              ? item.copyWith(status: AdStatus.expired)
              : item,
        )
        .toList(growable: true);
  }

  int _dealPriority(DealType type) {
    switch (type) {
      case DealType.todayDeal:
        return 5;
      case DealType.halfPrice:
        return 4;
      case DealType.limitedTime:
        return 3;
      case DealType.discountedService:
        return 2;
      case DealType.standard:
        return 1;
    }
  }

  String _buildDuplicateKey({
    required String userId,
    required String title,
    required AdCategory category,
    required String locationText,
  }) {
    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('-', ' ')
        .trim();
    return '${normalize(userId)}|${normalize(title)}|${category.value}|${normalize(locationText)}';
  }

  String _normalizePhone(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  bool _isValidPhone(String phone) => phone.length >= 9 && phone.length <= 15;

  String _generateId(String prefix) {
    final int stamp = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$stamp';
  }

  List<AdListing> _seedAds() {
    final DateTime now = DateTime.now();
    return <AdListing>[
      AdListing(
        adId: 'ad-seed-1',
        userId: 'seed-provider-1',
        title: 'تخفيض 25% على صيانة المكيفات المنزلية',
        description: 'فحص وتنظيف وتعبئة غاز مع زيارة سريعة داخل صنعاء خلال نفس اليوم.',
        priceBefore: 20000,
        priceAfter: 15000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-ac-banner/1200/800',
          'https://picsum.photos/seed/makaan-ac-2/1200/800',
        ],
        category: AdCategory.services,
        phoneNumber: '777123456',
        locationText: 'صنعاء - شارع الزبيري',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(days: 2)),
        status: AdStatus.active,
        dealType: DealType.todayDeal,
        ownerName: 'مركز النسيم للتكييف',
        isBanner: true,
        isFeatured: true,
      ),
      AdListing(
        adId: 'ad-seed-2',
        userId: 'seed-provider-2',
        title: 'سيارة تويوتا كورولا 2016 بحالة ممتازة',
        description: 'مكينة وبودي ممتاز، استخدام شخصي، جاهزة للفحص والمعاينة.',
        priceBefore: 6500000,
        priceAfter: 6100000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-car-1/1200/800',
          'https://picsum.photos/seed/makaan-car-2/1200/800',
          'https://picsum.photos/seed/makaan-car-3/1200/800',
        ],
        category: AdCategory.cars,
        phoneNumber: '770223344',
        locationText: 'عدن - خور مكسر',
        createdAt: now.subtract(const Duration(hours: 6)),
        status: AdStatus.active,
        dealType: DealType.limitedTime,
        ownerName: 'معرض السهم للسيارات',
        isBanner: true,
        isFeatured: true,
      ),
      AdListing(
        adId: 'ad-seed-3',
        userId: 'seed-provider-3',
        title: 'شقة مفروشة للإيجار الشهري',
        description: 'شقة غرفتين وصالة مفروشة بالكامل، قريبة من الخدمات والشارع العام.',
        priceBefore: 180000,
        priceAfter: 160000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-home-1/1200/800',
          'https://picsum.photos/seed/makaan-home-2/1200/800',
        ],
        category: AdCategory.realEstate,
        phoneNumber: '713456789',
        locationText: 'تعز - وادي القاضي',
        createdAt: now.subtract(const Duration(days: 1)),
        status: AdStatus.active,
        dealType: DealType.todayDeal,
        ownerName: 'مكتب الأندلس العقاري',
        isBanner: true,
        isFeatured: true,
      ),
      AdListing(
        adId: 'ad-seed-4',
        userId: 'seed-provider-4',
        title: 'عرض اليوم على الثلاجات المنزلية',
        description: 'ثلاجات جديدة بضمان سنة مع خدمة توصيل داخل المدينة.',
        priceBefore: 420000,
        priceAfter: 320000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-fridge-1/1200/800',
          'https://picsum.photos/seed/makaan-fridge-2/1200/800',
        ],
        category: AdCategory.electronics,
        phoneNumber: '715000111',
        locationText: 'إب - جبلة',
        createdAt: now.subtract(const Duration(hours: 10)),
        expiresAt: now.add(const Duration(hours: 18)),
        status: AdStatus.active,
        dealType: DealType.halfPrice,
        ownerName: 'بيت الإلكترونيات',
        isFeatured: true,
      ),
      AdListing(
        adId: 'ad-seed-5',
        userId: 'seed-provider-5',
        title: 'وجبة عائلية من مطعم المذاق',
        description: 'خصم خاص على الوجبات العائلية مع توصيل مجاني للمناطق القريبة.',
        priceBefore: 18000,
        priceAfter: 12000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-food-1/1200/800',
          'https://picsum.photos/seed/makaan-food-2/1200/800',
        ],
        category: AdCategory.restaurants,
        phoneNumber: '733777888',
        locationText: 'الحديدة - شارع صنعاء',
        createdAt: now.subtract(const Duration(hours: 14)),
        expiresAt: now.add(const Duration(hours: 12)),
        status: AdStatus.active,
        dealType: DealType.discountedService,
        ownerName: 'مطعم المذاق',
      ),
      AdListing(
        adId: 'ad-seed-6',
        userId: 'seed-provider-6',
        title: 'سلة بقالة أسبوعية بسعر مخفض',
        description: 'مواد أساسية متنوعة مع إمكانية تجهيز الطلب خلال ساعتين فقط.',
        priceBefore: 30000,
        priceAfter: 25000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-grocery-1/1200/800',
        ],
        category: AdCategory.groceries,
        phoneNumber: '711222333',
        locationText: 'ذمار - شارع الجامعة',
        createdAt: now.subtract(const Duration(days: 2)),
        status: AdStatus.active,
        dealType: DealType.limitedTime,
        ownerName: 'بقالة الواحة',
      ),
      AdListing(
        adId: 'ad-seed-7',
        userId: 'seed-provider-7',
        title: 'تصميم وتنفيذ مطبخ ألمنيوم',
        description: 'قياس وتنفيذ وتسليم خلال 7 أيام مع متابعة بعد التركيب.',
        priceBefore: 750000,
        priceAfter: 680000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-kitchen-1/1200/800',
          'https://picsum.photos/seed/makaan-kitchen-2/1200/800',
        ],
        category: AdCategory.services,
        phoneNumber: '775888999',
        locationText: 'صنعاء - حدة',
        createdAt: now.subtract(const Duration(days: 3)),
        status: AdStatus.pending,
        dealType: DealType.standard,
        ownerName: 'ورشة الإبداع',
      ),
      AdListing(
        adId: 'ad-seed-8',
        userId: 'seed-provider-8',
        title: 'أرض تجارية على شارع رئيسي',
        description: 'موقع تجاري مناسب للاستثمار مع أوراق مكتملة وسعر قابل للتفاوض.',
        priceBefore: 12000000,
        priceAfter: 11000000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-land-1/1200/800',
        ],
        category: AdCategory.realEstate,
        phoneNumber: '772555444',
        locationText: 'مأرب - المدينة',
        createdAt: now.subtract(const Duration(days: 4)),
        expiresAt: now.subtract(const Duration(hours: 8)),
        status: AdStatus.active,
        dealType: DealType.limitedTime,
        ownerName: 'الصفوة للعقارات',
      ),
      AdListing(
        adId: 'ad-seed-9',
        userId: 'seed-provider-9',
        title: 'باقة تنظيف فلل ومنازل',
        description: 'الإعلان مرفوض حالياً بسبب نقص المعلومات وسيظل لأغراض معاينة الحالات فقط.',
        priceBefore: 50000,
        priceAfter: 42000,
        images: const <String>[
          'https://picsum.photos/seed/makaan-cleaning-1/1200/800',
        ],
        category: AdCategory.services,
        phoneNumber: '700100200',
        locationText: 'المكلا - فوة',
        createdAt: now.subtract(const Duration(days: 5)),
        status: AdStatus.rejected,
        dealType: DealType.discountedService,
        ownerName: 'نظافة برو',
      ),
    ];
  }
}
