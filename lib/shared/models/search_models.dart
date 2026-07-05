import 'ad_models.dart';
import 'provider_models.dart';

enum SearchResultType { provider, ad }

enum SearchSortOption { relevance, topRated, nearest, latest, mostViewed, priceLowToHigh, priceHighToLow }

extension SearchSortOptionX on SearchSortOption {
  String get arabicLabel {
    switch (this) {
      case SearchSortOption.relevance:
        return 'الأكثر صلة';
      case SearchSortOption.topRated:
        return 'أعلى تقييم';
      case SearchSortOption.nearest:
        return 'الأقرب';
      case SearchSortOption.latest:
        return 'الأحدث';
      case SearchSortOption.mostViewed:
        return 'الأكثر مشاهدة';
      case SearchSortOption.priceLowToHigh:
        return 'السعر: الأقل أولاً';
      case SearchSortOption.priceHighToLow:
        return 'السعر: الأعلى أولاً';
    }
  }
}

class SmartSearchFilters {
  const SmartSearchFilters({
    this.governorate,
    this.district,
    this.serviceType,
    this.categoryKey,
    this.minPrice,
    this.maxPrice,
    this.sortOption = SearchSortOption.relevance,
  });

  final String? governorate;
  final String? district;
  final String? serviceType;
  final String? categoryKey;
  final double? minPrice;
  final double? maxPrice;
  final SearchSortOption sortOption;

  bool get hasActiveFilters =>
      (governorate ?? '').trim().isNotEmpty ||
      (district ?? '').trim().isNotEmpty ||
      (serviceType ?? '').trim().isNotEmpty ||
      (categoryKey ?? '').trim().isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      sortOption != SearchSortOption.relevance;

  SmartSearchFilters copyWith({
    String? governorate,
    bool clearGovernorate = false,
    String? district,
    bool clearDistrict = false,
    String? serviceType,
    bool clearServiceType = false,
    String? categoryKey,
    bool clearCategoryKey = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    SearchSortOption? sortOption,
  }) {
    return SmartSearchFilters(
      governorate: clearGovernorate ? null : (governorate ?? this.governorate),
      district: clearDistrict ? null : (district ?? this.district),
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      categoryKey: clearCategoryKey ? null : (categoryKey ?? this.categoryKey),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class DiscoveryCategory {
  const DiscoveryCategory({
    required this.key,
    required this.label,
    required this.emoji,
    required this.keywords,
    this.adCategory,
  });

  final String key;
  final String label;
  final String emoji;
  final List<String> keywords;
  final AdCategory? adCategory;
}

class SmartSearchResult {
  const SmartSearchResult.provider({
    required ProviderDetails this.provider,
    required this.score,
    required this.matchedTerms,
  })  : ad = null,
        type = SearchResultType.provider;

  const SmartSearchResult.ad({
    required AdListing this.ad,
    required this.score,
    required this.matchedTerms,
  })  : provider = null,
        type = SearchResultType.ad;

  final SearchResultType type;
  final ProviderDetails? provider;
  final AdListing? ad;
  final double score;
  final List<String> matchedTerms;

  String get id => provider?.profile.providerId ?? ad?.adId ?? '';

  String get title => provider?.profile.businessName ?? ad?.title ?? '';

  String get subtitle => provider?.profile.description ?? ad?.description ?? '';

  String get locationText {
    final ProviderProfile? profile = provider?.profile;
    if (profile != null) {
      return '${profile.governorate} - ${profile.district}';
    }
    return ad?.locationText ?? '';
  }

  String get categoryLabel => provider?.profile.mainServiceType ?? ad?.category.arabicLabel ?? '';

  double get rating => provider?.averageRating ?? 0;

  double? get price {
    if (ad != null) {
      return ad!.priceAfter;
    }
    final List<ProviderService> services = provider?.services ?? const <ProviderService>[];
    final List<double> prices = services
        .map((ProviderService item) => item.approximatePrice)
        .whereType<double>()
        .where((double item) => item > 0)
        .toList(growable: false);
    if (prices.isEmpty) {
      return null;
    }
    prices.sort();
    return prices.first;
  }

  DateTime get createdAt => provider?.profile.createdAt ?? ad?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  int get popularityScore {
    if (provider != null) {
      return provider!.profile.customerCount + (provider!.reviewCount * 10);
    }
    final AdListing? currentAd = ad;
    if (currentAd == null) {
      return 0;
    }
    return (currentAd.isFeatured ? 80 : 0) +
        (currentAd.isBanner ? 60 : 0) +
        (currentAd.discountPercent * 2) +
        (currentAd.dealType == DealType.standard ? 5 : 30);
  }
}
