import '../../../features/ads/data/ad_repository.dart';
import '../../../features/providers/data/provider_repository.dart';
import '../../../shared/models/ad_models.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/provider_models.dart';
import '../../../shared/models/search_models.dart';
import '../../../shared/services/runtime_diagnostics_service.dart';

class SearchRepository {
  SearchRepository(this._providerRepository, this._adRepository);

  final ProviderRepository _providerRepository;
  final AdRepository _adRepository;
  final Map<String, _CachedSearchResult> _searchCache = <String, _CachedSearchResult>{};
  final Map<String, List<String>> _tokenCache = <String, List<String>>{};

  static const List<DiscoveryCategory> categories = <DiscoveryCategory>[
    DiscoveryCategory(
      key: 'water',
      label: 'المياه',
      emoji: '🚰',
      keywords: <String>['مياه', 'وايت', 'تحلية', 'خزان', 'توصيل مياه'],
      adCategory: AdCategory.services,
    ),
    DiscoveryCategory(
      key: 'taxi',
      label: 'التكاسي',
      emoji: '🚖',
      keywords: <String>['تاكسي', 'تكسي', 'مشوار', 'توصيل', 'مواصلات', 'نقل'],
      adCategory: AdCategory.services,
    ),
    DiscoveryCategory(
      key: 'tires',
      label: 'البنشري',
      emoji: '🔧',
      keywords: <String>['بنشر', 'بنشري', 'إطارات', 'كفرات', 'تغيير زيت'],
      adCategory: AdCategory.services,
    ),
    DiscoveryCategory(
      key: 'mechanic',
      label: 'الميكانيكي',
      emoji: '🛠',
      keywords: <String>['ميكانيكي', 'سيارات', 'ورشة', 'صيانة سيارة', 'مكينة'],
      adCategory: AdCategory.cars,
    ),
    DiscoveryCategory(
      key: 'restaurants',
      label: 'المطاعم',
      emoji: '🍽',
      keywords: <String>['مطعم', 'مطاعم', 'وجبة', 'غداء', 'عشاء', 'توصيل أكل'],
      adCategory: AdCategory.restaurants,
    ),
    DiscoveryCategory(
      key: 'groceries',
      label: 'البقالات',
      emoji: '🛒',
      keywords: <String>['بقالة', 'بقالات', 'مواد غذائية', 'سوبر ماركت', 'تموينات'],
      adCategory: AdCategory.groceries,
    ),
    DiscoveryCategory(
      key: 'pharmacies',
      label: 'الصيدليات',
      emoji: '💊',
      keywords: <String>['صيدلية', 'صيدليات', 'دواء', 'أدوية', 'مستلزمات طبية'],
      adCategory: AdCategory.services,
    ),
    DiscoveryCategory(
      key: 'real_estate',
      label: 'العقارات',
      emoji: '🏠',
      keywords: <String>['عقار', 'عقارات', 'شقة', 'أرض', 'إيجار', 'بيع'],
      adCategory: AdCategory.realEstate,
    ),
    DiscoveryCategory(
      key: 'cars',
      label: 'السيارات',
      emoji: '🚗',
      keywords: <String>['سيارة', 'سيارات', 'معرض', 'تويوتا', 'هونداي', 'بيع سيارة'],
      adCategory: AdCategory.cars,
    ),
    DiscoveryCategory(
      key: 'craftsmen',
      label: 'الحرفيون',
      emoji: '🔨',
      keywords: <String>['حرفي', 'نجار', 'كهربائي', 'سباك', 'دهان', 'ألمنيوم', 'حداد'],
      adCategory: AdCategory.services,
    ),
    DiscoveryCategory(
      key: 'other',
      label: 'خدمات أخرى',
      emoji: '📦',
      keywords: <String>['خدمات', 'أخرى', 'تنظيف', 'صيانة', 'توصيل'],
      adCategory: AdCategory.other,
    ),
  ];

  List<SmartSearchResult> search({
    required String query,
    required SmartSearchFilters filters,
    AppUser? currentUser,
    int limit = 80,
  }) {
    return RuntimeDiagnosticsService.instance.trackSync('smart_search', () {
      _pruneExpiredCache();
      final String cacheKey = _cacheKey(query: query, filters: filters, limit: limit, user: currentUser);
      final _CachedSearchResult? cached = _searchCache[cacheKey];
      if (cached != null && !cached.isExpired) {
        return cached.results;
      }
      final String normalizedQuery = _normalize(query);
      final List<String> queryTokens = _tokenize(normalizedQuery);
      final List<SmartSearchResult> results = <SmartSearchResult>[];

    for (final ProviderDetails provider in _providerRepository.getAllProviderDetails()) {
      if (!provider.isVisibleInApp) {
        continue;
      }
      final _Document document = _providerDocument(provider);
      if (!_passesFilters(document, filters)) {
        continue;
      }
      final _ScoreMatch match = _score(document, queryTokens, normalizedQuery);
      if (queryTokens.isEmpty || match.score > 0) {
        results.add(
          SmartSearchResult.provider(
            provider: provider,
            score: match.score + (provider.averageRating * 5) + provider.reviewCount,
            matchedTerms: match.terms,
          ),
        );
      }
    }

    for (final AdListing ad in _adRepository.getAllAds()) {
      final _Document document = _adDocument(ad);
      if (!_passesFilters(document, filters)) {
        continue;
      }
      final _ScoreMatch match = _score(document, queryTokens, normalizedQuery);
      if (queryTokens.isEmpty || match.score > 0) {
        results.add(
          SmartSearchResult.ad(
            ad: ad,
            score: match.score + (ad.isFeatured ? 10 : 0) + ad.discountPercent,
            matchedTerms: match.terms,
          ),
        );
      }
    }

      _sortResults(results, filters, currentUser);
      final List<SmartSearchResult> limited = results.take(limit).toList(growable: false);
      _searchCache[cacheKey] = _CachedSearchResult(limited, DateTime.now().add(const Duration(minutes: 3)));
      return limited;
    });
  }

  List<String> suggestions({
    required String query,
    required SmartSearchFilters filters,
    int limit = 8,
  }) {
    final String normalized = _normalize(query);
    final List<String> source = _indexTerms(filters);
    if (normalized.isEmpty) {
      return source.take(limit).toList(growable: false);
    }

    final List<_SuggestionScore> scored = <_SuggestionScore>[];
    for (final String term in source) {
      final String termNormalized = _normalize(term);
      int score = 0;
      if (termNormalized.startsWith(normalized)) {
        score = 100;
      } else if (termNormalized.contains(normalized)) {
        score = 70;
      } else if (_levenshtein(termNormalized, normalized) <= _allowedDistance(normalized)) {
        score = 45;
      }
      if (score > 0) {
        scored.add(_SuggestionScore(term, score));
      }
    }
    scored.sort((_SuggestionScore a, _SuggestionScore b) {
      final int byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.term.length.compareTo(b.term.length);
    });
    return scored.map((_SuggestionScore item) => item.term).take(limit).toList(growable: false);
  }

  List<String> serviceTypes() {
    final Set<String> result = <String>{};
    for (final ProviderDetails provider in _providerRepository.getAllProviderDetails()) {
      final String main = provider.profile.mainServiceType.trim();
      if (main.isNotEmpty) {
        result.add(main);
      }
      for (final ProviderService service in provider.services) {
        final String title = service.title.trim();
        if (title.isNotEmpty) {
          result.add(title);
        }
      }
    }
    for (final DiscoveryCategory category in categories) {
      result.add(category.label);
    }
    final List<String> sorted = result.toList(growable: false);
    sorted.sort((String a, String b) => a.compareTo(b));
    return sorted;
  }

  List<ProviderDetails> topRatedProviders({int limit = 6}) {
    final List<ProviderDetails> items = _providerRepository
        .getAllProviderDetails()
        .where((ProviderDetails item) => item.isVisibleInApp)
        .toList(growable: false);
    items.sort((ProviderDetails a, ProviderDetails b) {
      final int byRating = b.averageRating.compareTo(a.averageRating);
      if (byRating != 0) {
        return byRating;
      }
      return b.reviewCount.compareTo(a.reviewCount);
    });
    return items.take(limit).toList(growable: false);
  }

  List<ProviderDetails> newProviders({int limit = 6}) {
    final List<ProviderDetails> items = _providerRepository
        .getAllProviderDetails()
        .where((ProviderDetails item) => item.isVisibleInApp)
        .toList(growable: false);
    items.sort((ProviderDetails a, ProviderDetails b) => b.profile.createdAt.compareTo(a.profile.createdAt));
    return items.take(limit).toList(growable: false);
  }

  List<String> mostRequestedServices({int limit = 8}) {
    final Map<String, int> counts = <String, int>{};
    for (final ProviderDetails provider in _providerRepository.getAllProviderDetails()) {
      final String main = provider.profile.mainServiceType.trim();
      if (main.isNotEmpty) {
        counts[main] = (counts[main] ?? 0) + 3 + provider.profile.customerCount;
      }
      for (final ProviderService service in provider.services) {
        final String title = service.title.trim();
        if (title.isNotEmpty) {
          counts[title] = (counts[title] ?? 0) + 1;
        }
      }
    }
    for (final DiscoveryCategory category in categories) {
      counts.putIfAbsent(category.label, () => category.key == 'other' ? 1 : 2);
    }
    final List<MapEntry<String, int>> sorted = counts.entries.toList(growable: false);
    sorted.sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    return sorted.map((MapEntry<String, int> item) => item.key).take(limit).toList(growable: false);
  }

  _Document _providerDocument(ProviderDetails provider) {
    final ProviderProfile profile = provider.profile;
    final List<String> fields = <String>[
      profile.businessName,
      profile.description,
      profile.mainServiceType,
      profile.governorate,
      profile.district,
      profile.phoneNumber,
      ...provider.services.expand((ProviderService item) => <String>[item.title, item.description]),
      ...provider.serviceAreas.expand((ProviderServiceArea item) => <String>[
            item.governorate,
            item.district,
            item.neighborhood ?? '',
          ]),
      ...provider.gallery.expand((ProviderGalleryItem item) => <String>[item.caption, item.category]),
    ];
    return _Document(
      text: fields.join(' '),
      governorate: profile.governorate,
      district: profile.district,
      categoryKey: _categoryKeyForText(fields.join(' ')),
      price: _providerPrice(provider),
    );
  }

  _Document _adDocument(AdListing ad) {
    final String text = <String>[
      ad.title,
      ad.description,
      ad.ownerName ?? '',
      ad.category.arabicLabel,
      ad.locationText,
      ad.phoneNumber,
      ad.dealType.arabicLabel,
    ].join(' ');
    return _Document(
      text: text,
      governorate: _firstLocationPart(ad.locationText),
      district: _secondLocationPart(ad.locationText),
      categoryKey: _categoryKeyForAd(ad),
      price: ad.priceAfter,
    );
  }

  bool _passesFilters(_Document document, SmartSearchFilters filters) {
    final String governorate = (filters.governorate ?? '').trim();
    if (governorate.isNotEmpty && _normalize(document.governorate) != _normalize(governorate)) {
      return false;
    }
    final String district = (filters.district ?? '').trim();
    if (district.isNotEmpty && _normalize(document.district) != _normalize(district)) {
      return false;
    }
    final String serviceType = (filters.serviceType ?? '').trim();
    if (serviceType.isNotEmpty && !_normalize(document.text).contains(_normalize(serviceType))) {
      return false;
    }
    final String categoryKey = (filters.categoryKey ?? '').trim();
    if (categoryKey.isNotEmpty && document.categoryKey != categoryKey) {
      return false;
    }
    final double? minPrice = filters.minPrice;
    if (minPrice != null && (document.price == null || document.price! < minPrice)) {
      return false;
    }
    final double? maxPrice = filters.maxPrice;
    if (maxPrice != null && (document.price == null || document.price! > maxPrice)) {
      return false;
    }
    return true;
  }

  _ScoreMatch _score(_Document document, List<String> queryTokens, String normalizedQuery) {
    if (queryTokens.isEmpty) {
      return const _ScoreMatch(1, <String>[]);
    }
    final String text = _normalize(document.text);
    final List<String> textTokens = _tokenize(text);
    double score = 0;
    final Set<String> terms = <String>{};

    if (normalizedQuery.isNotEmpty && text.contains(normalizedQuery)) {
      score += 40 + normalizedQuery.length;
      terms.add(normalizedQuery);
    }

    for (final String queryToken in queryTokens) {
      if (queryToken.isEmpty) {
        continue;
      }
      bool matched = false;
      for (final String token in textTokens) {
        if (token == queryToken) {
          score += 24;
          matched = true;
          terms.add(queryToken);
          break;
        }
        if (token.startsWith(queryToken) || token.contains(queryToken)) {
          score += 13;
          matched = true;
          terms.add(queryToken);
          break;
        }
      }
      if (!matched) {
        for (final String token in textTokens) {
          if (_levenshtein(token, queryToken) <= _allowedDistance(queryToken)) {
            score += 8;
            terms.add(token);
            break;
          }
        }
      }
    }
    return _ScoreMatch(score, terms.take(5).toList(growable: false));
  }

  void _sortResults(List<SmartSearchResult> results, SmartSearchFilters filters, AppUser? currentUser) {
    switch (filters.sortOption) {
      case SearchSortOption.relevance:
        results.sort((SmartSearchResult a, SmartSearchResult b) => b.score.compareTo(a.score));
        return;
      case SearchSortOption.topRated:
        results.sort((SmartSearchResult a, SmartSearchResult b) => b.rating.compareTo(a.rating));
        return;
      case SearchSortOption.nearest:
        results.sort((SmartSearchResult a, SmartSearchResult b) {
          final int aDistance = _distanceBucket(a, filters, currentUser);
          final int bDistance = _distanceBucket(b, filters, currentUser);
          final int byDistance = aDistance.compareTo(bDistance);
          return byDistance != 0 ? byDistance : b.score.compareTo(a.score);
        });
        return;
      case SearchSortOption.latest:
        results.sort((SmartSearchResult a, SmartSearchResult b) => b.createdAt.compareTo(a.createdAt));
        return;
      case SearchSortOption.mostViewed:
        results.sort((SmartSearchResult a, SmartSearchResult b) => b.popularityScore.compareTo(a.popularityScore));
        return;
      case SearchSortOption.priceLowToHigh:
        results.sort((SmartSearchResult a, SmartSearchResult b) => (a.price ?? double.infinity).compareTo(b.price ?? double.infinity));
        return;
      case SearchSortOption.priceHighToLow:
        results.sort((SmartSearchResult a, SmartSearchResult b) => (b.price ?? 0).compareTo(a.price ?? 0));
        return;
    }
  }

  int _distanceBucket(SmartSearchResult result, SmartSearchFilters filters, AppUser? user) {
    final String targetGovernorate = (filters.governorate ?? user?.governorate ?? '').trim();
    final String targetDistrict = (filters.district ?? user?.district ?? '').trim();
    if (targetGovernorate.isEmpty) {
      return 2;
    }
    final String resultLocation = _normalize(result.locationText);
    if (targetDistrict.isNotEmpty && resultLocation.contains(_normalize(targetDistrict))) {
      return 0;
    }
    if (resultLocation.contains(_normalize(targetGovernorate))) {
      return 1;
    }
    return 2;
  }

  List<String> _indexTerms(SmartSearchFilters filters) {
    final Set<String> terms = <String>{};
    for (final DiscoveryCategory category in categories) {
      if ((filters.categoryKey ?? '').trim().isEmpty || filters.categoryKey == category.key) {
        terms.add(category.label);
        terms.addAll(category.keywords);
      }
    }
    for (final ProviderDetails provider in _providerRepository.getAllProviderDetails()) {
      final _Document document = _providerDocument(provider);
      if (!_passesFilters(document, filters)) {
        continue;
      }
      terms.add(provider.profile.businessName);
      terms.add(provider.profile.mainServiceType);
      terms.add(provider.profile.governorate);
      terms.add(provider.profile.district);
      for (final ProviderService service in provider.services) {
        terms.add(service.title);
      }
    }
    for (final AdListing ad in _adRepository.getAllAds()) {
      final _Document document = _adDocument(ad);
      if (!_passesFilters(document, filters)) {
        continue;
      }
      terms.add(ad.title);
      terms.add(ad.category.arabicLabel);
      terms.add(ad.ownerName ?? '');
      terms.addAll(ad.locationText.split(RegExp(r'[-،,\s]+')));
    }
    final List<String> result = terms.map((String item) => item.trim()).where((String item) => item.length > 1).toList(growable: false);
    result.sort((String a, String b) => a.length.compareTo(b.length));
    return result;
  }

  double? _providerPrice(ProviderDetails provider) {
    final List<double> prices = provider.services
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

  String _categoryKeyForAd(AdListing ad) {
    switch (ad.category) {
      case AdCategory.cars:
        return 'cars';
      case AdCategory.realEstate:
        return 'real_estate';
      case AdCategory.restaurants:
        return 'restaurants';
      case AdCategory.groceries:
        return 'groceries';
      case AdCategory.electronics:
        return 'other';
      case AdCategory.services:
      case AdCategory.other:
        return _categoryKeyForText('${ad.title} ${ad.description} ${ad.ownerName ?? ''} ${ad.category.arabicLabel}');
    }
  }

  String _categoryKeyForText(String text) {
    final String normalized = _normalize(text);
    for (final DiscoveryCategory category in categories) {
      if (category.key == 'other') {
        continue;
      }
      for (final String keyword in category.keywords) {
        if (normalized.contains(_normalize(keyword))) {
          return category.key;
        }
      }
    }
    return 'other';
  }

  String _firstLocationPart(String value) {
    final List<String> parts = value.split(RegExp(r'[-،,]')).map((String item) => item.trim()).where((String item) => item.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? '' : parts.first;
  }

  String _secondLocationPart(String value) {
    final List<String> parts = value.split(RegExp(r'[-،,]')).map((String item) => item.trim()).where((String item) => item.isNotEmpty).toList(growable: false);
    return parts.length < 2 ? '' : parts[1];
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[ـًٌٍَُِّْ]'), '')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _tokenize(String value) {
    final String normalized = _normalize(value);
    final List<String>? cached = _tokenCache[normalized];
    if (cached != null) {
      return cached;
    }
    final List<String> tokens = normalized
        .split(' ')
        .where((String token) => token.trim().isNotEmpty)
        .toList(growable: false);
    if (_tokenCache.length > 400) {
      _tokenCache.clear();
    }
    _tokenCache[normalized] = tokens;
    return tokens;
  }

  String _cacheKey({
    required String query,
    required SmartSearchFilters filters,
    required int limit,
    AppUser? user,
  }) {
    return <String>[
      _normalize(query),
      filters.governorate ?? '',
      filters.district ?? '',
      filters.serviceType ?? '',
      filters.categoryKey ?? '',
      filters.minPrice?.toStringAsFixed(0) ?? '',
      filters.maxPrice?.toStringAsFixed(0) ?? '',
      filters.sortOption.name,
      user?.governorate ?? '',
      user?.district ?? '',
      limit.toString(),
    ].join('|');
  }

  void _pruneExpiredCache() {
    if (_searchCache.length < 120) {
      return;
    }
    _searchCache.removeWhere((String key, _CachedSearchResult value) => value.isExpired);
    if (_searchCache.length > 160) {
      _searchCache.clear();
    }
  }

  int _allowedDistance(String value) {
    if (value.length <= 3) {
      return 0;
    }
    if (value.length <= 6) {
      return 1;
    }
    return 2;
  }

  int _levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }
    final List<int> previous = List<int>.generate(b.length + 1, (int index) => index);
    final List<int> current = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final int insertCost = current[j] + 1;
        final int deleteCost = previous[j + 1] + 1;
        final int replaceCost = previous[j] + (a[i] == b[j] ? 0 : 1);
        current[j + 1] = <int>[insertCost, deleteCost, replaceCost].reduce((int x, int y) => x < y ? x : y);
      }
      for (int j = 0; j < previous.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }
}

class _Document {
  const _Document({
    required this.text,
    required this.governorate,
    required this.district,
    required this.categoryKey,
    required this.price,
  });

  final String text;
  final String governorate;
  final String district;
  final String categoryKey;
  final double? price;
}

class _ScoreMatch {
  const _ScoreMatch(this.score, this.terms);

  final double score;
  final List<String> terms;
}

class _SuggestionScore {
  const _SuggestionScore(this.term, this.score);

  final String term;
  final int score;
}

class _CachedSearchResult {
  const _CachedSearchResult(this.results, this.expiresAt);

  final List<SmartSearchResult> results;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
