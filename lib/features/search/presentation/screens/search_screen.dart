import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/constants/yemen_locations.dart';
import '../../../../shared/models/search_models.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../ads/presentation/screens/ad_details_screen.dart';
import '../../../ads/presentation/widgets/ad_ui.dart';
import '../../../providers/presentation/screens/provider_profile_screen.dart';

class SearchScreenArgs {
  const SearchScreenArgs({this.initialQuery, this.categoryKey});

  final String? initialQuery;
  final String? categoryKey;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.args, super.key});

  final SearchScreenArgs args;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _queryController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  Timer? _debounce;
  bool _isSearching = false;
  SmartSearchFilters _filters = const SmartSearchFilters();

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.args.initialQuery ?? '');
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    if ((widget.args.categoryKey ?? '').trim().isNotEmpty) {
      _filters = _filters.copyWith(categoryKey: widget.args.categoryKey);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<SmartSearchResult> results = controller.smartSearch(
      query: _queryController.text,
      filters: _filters,
    );
    final List<String> suggestions = controller.smartSearchSuggestions(
      query: _queryController.text,
      filters: _filters,
    );

    return AppScaffold(
      title: 'البحث الذكي',
      currentNavIndex: 1,
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'المفضلة',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.favorites),
          icon: const Icon(Icons.favorite_border_rounded),
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _SearchHeader(
                queryController: _queryController,
                isSearching: _isSearching,
                onChanged: _onQueryChanged,
                onClear: () {
                  _queryController.clear();
                  _onQueryChanged('');
                },
              ),
              const SizedBox(height: 14),
              _SuggestionStrip(
                suggestions: suggestions,
                onSelected: (String value) {
                  _queryController.text = value;
                  _queryController.selection = TextSelection.collapsed(offset: value.length);
                  _onQueryChanged(value);
                },
              ),
              const SizedBox(height: 14),
              _FiltersPanel(
                filters: _filters,
                serviceTypes: controller.searchableServiceTypes(),
                categories: controller.discoveryCategories,
                minPriceController: _minPriceController,
                maxPriceController: _maxPriceController,
                onChanged: (SmartSearchFilters value) => setState(() => _filters = value),
                onReset: _resetFilters,
              ),
              const SizedBox(height: 16),
              _ResultsSummary(
                query: _queryController.text,
                count: results.length,
                hasFilters: _filters.hasActiveFilters,
              ),
              const SizedBox(height: 12),
              if (_isSearching)
                const LinearProgressIndicator(minHeight: 4)
              else if (results.isEmpty)
                EmptyStateCard(
                  title: 'لا توجد نتائج مطابقة',
                  subtitle: _queryController.text.trim().isEmpty
                      ? 'جرّب اختيار تصنيف أو تغيير الفلاتر الحالية.'
                      : 'لم نجد نتائج لعبارة "${_queryController.text}". جرّب كلمة أقصر أو استخدم أحد الاقتراحات.',
                  icon: Icons.search_off_rounded,
                )
              else
                ...results.map(
                  (SmartSearchResult result) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SearchResultCard(result: result),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      setState(() => _isSearching = false);
    });
  }

  void _resetFilters() {
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() => _filters = const SmartSearchFilters());
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.queryController,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController queryController;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('كل خدماتك في مكان واحد', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'ابحث في مقدمي الخدمات، المتاجر، الإعلانات، المنتجات، السيارات، العقارات، الوصف، المحافظات والمديريات.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            SearchBar(
              controller: queryController,
              autoFocus: true,
              hintText: 'مثال: ميكانيكي، شقة، مطعم، تعز، كورولا...',
              leading: const Icon(Icons.search_rounded),
              trailing: <Widget>[
                if (isSearching)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                if (queryController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
              onChanged: onChanged,
              onSubmitted: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text('اقتراحات:', style: Theme.of(context).textTheme.labelLarge),
            ),
            ...suggestions.map(
              (String item) => ActionChip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(item),
                onPressed: () => onSelected(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.filters,
    required this.serviceTypes,
    required this.categories,
    required this.minPriceController,
    required this.maxPriceController,
    required this.onChanged,
    required this.onReset,
  });

  final SmartSearchFilters filters;
  final List<String> serviceTypes;
  final List<DiscoveryCategory> categories;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final ValueChanged<SmartSearchFilters> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final List<String> districts = (filters.governorate ?? '').trim().isEmpty
        ? const <String>[]
        : YemenLocations.districtsFor(filters.governorate!);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: filters.hasActiveFilters,
        leading: const Icon(Icons.tune_rounded),
        title: const Text('الفلاتر المتقدمة'),
        subtitle: Text(filters.hasActiveFilters ? 'يوجد فلتر نشط' : 'المحافظة، المديرية، التصنيف، السعر، الترتيب'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth > 760 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(width: width, child: _GovernorateDropdown(filters: filters, onChanged: onChanged)),
                  SizedBox(width: width, child: _DistrictDropdown(filters: filters, districts: districts, onChanged: onChanged)),
                  SizedBox(width: width, child: _CategoryDropdown(filters: filters, categories: categories, onChanged: onChanged)),
                  SizedBox(width: width, child: _ServiceDropdown(filters: filters, serviceTypes: serviceTypes, onChanged: onChanged)),
                  SizedBox(width: width, child: _PriceField(label: 'أقل سعر', controller: minPriceController, onChanged: (double? value) => onChanged(filters.copyWith(minPrice: value, clearMinPrice: value == null)))),
                  SizedBox(width: width, child: _PriceField(label: 'أعلى سعر', controller: maxPriceController, onChanged: (double? value) => onChanged(filters.copyWith(maxPrice: value, clearMaxPrice: value == null)))),
                  SizedBox(width: width, child: _SortDropdown(filters: filters, onChanged: onChanged)),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppSecondaryButton(
              label: 'إعادة تعيين الفلاتر',
              icon: Icons.restart_alt_rounded,
              onPressed: onReset,
            ),
          ),
        ],
      ),
    );
  }
}

class _GovernorateDropdown extends StatelessWidget {
  const _GovernorateDropdown({required this.filters, required this.onChanged});

  final SmartSearchFilters filters;
  final ValueChanged<SmartSearchFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: filters.governorate,
      decoration: const InputDecoration(labelText: 'المحافظة', prefixIcon: Icon(Icons.location_city_outlined)),
      items: YemenLocations.governorateNames
          .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: (String? value) => onChanged(
        filters.copyWith(
          governorate: value,
          clearGovernorate: value == null,
          clearDistrict: true,
        ),
      ),
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  const _DistrictDropdown({required this.filters, required this.districts, required this.onChanged});

  final SmartSearchFilters filters;
  final List<String> districts;
  final ValueChanged<SmartSearchFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: districts.contains(filters.district) ? filters.district : null,
      decoration: const InputDecoration(labelText: 'المديرية', prefixIcon: Icon(Icons.map_outlined)),
      items: districts
          .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: districts.isEmpty
          ? null
          : (String? value) => onChanged(filters.copyWith(district: value, clearDistrict: value == null)),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.filters, required this.categories, required this.onChanged});

  final SmartSearchFilters filters;
  final List<DiscoveryCategory> categories;
  final ValueChanged<SmartSearchFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: filters.categoryKey,
      decoration: const InputDecoration(labelText: 'التصنيف', prefixIcon: Icon(Icons.category_outlined)),
      items: categories
          .map((DiscoveryCategory item) => DropdownMenuItem<String>(value: item.key, child: Text('${item.emoji} ${item.label}')))
          .toList(growable: false),
      onChanged: (String? value) => onChanged(filters.copyWith(categoryKey: value, clearCategoryKey: value == null)),
    );
  }
}

class _ServiceDropdown extends StatelessWidget {
  const _ServiceDropdown({required this.filters, required this.serviceTypes, required this.onChanged});

  final SmartSearchFilters filters;
  final List<String> serviceTypes;
  final ValueChanged<SmartSearchFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final String? value = serviceTypes.contains(filters.serviceType) ? filters.serviceType : null;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'نوع الخدمة', prefixIcon: Icon(Icons.handyman_outlined)),
      items: serviceTypes
          .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: (String? selected) => onChanged(filters.copyWith(serviceType: selected, clearServiceType: selected == null)),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.label, required this.controller, required this.onChanged});

  final String label;
  final TextEditingController controller;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.payments_outlined), suffixText: 'ر.ي'),
      onChanged: (String value) {
        final String normalized = value.replaceAll(',', '').trim();
        onChanged(normalized.isEmpty ? null : double.tryParse(normalized));
      },
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.filters, required this.onChanged});

  final SmartSearchFilters filters;
  final ValueChanged<SmartSearchFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SearchSortOption>(
      value: filters.sortOption,
      decoration: const InputDecoration(labelText: 'ترتيب النتائج', prefixIcon: Icon(Icons.sort_rounded)),
      items: SearchSortOption.values
          .map((SearchSortOption item) => DropdownMenuItem<SearchSortOption>(value: item, child: Text(item.arabicLabel)))
          .toList(growable: false),
      onChanged: (SearchSortOption? value) => onChanged(filters.copyWith(sortOption: value ?? SearchSortOption.relevance)),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.query, required this.count, required this.hasFilters});

  final String query;
  final int count;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final String title = query.trim().isEmpty ? 'كل النتائج المتاحة' : 'نتائج البحث عن "$query"';
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        Chip(label: Text('$count نتيجة')),
        if (hasFilters) ...<Widget>[
          const SizedBox(width: 8),
          const Chip(label: Text('مفلترة')),
        ],
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result});

  final SmartSearchResult result;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final bool isAd = result.type == SearchResultType.ad;
    final bool isFavorite = isAd
        ? controller.isFavoriteAd(result.id)
        : controller.isFavoriteProvider(result.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ResultThumbnail(result: result),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Chip(label: Text(isAd ? 'إعلان' : 'مقدم خدمة')),
                        Chip(label: Text(result.categoryLabel.isEmpty ? 'غير محدد' : result.categoryLabel)),
                        if (result.rating > 0) Chip(label: Text('${result.rating.toStringAsFixed(1)} ⭐')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        AdMetaChip(icon: Icons.location_on_outlined, label: result.locationText.isEmpty ? 'الموقع غير محدد' : result.locationText),
                        if (result.price != null) AdMetaChip(icon: Icons.payments_outlined, label: '${result.price!.round()} ر.ي'),
                        if (result.matchedTerms.isNotEmpty)
                          AdMetaChip(icon: Icons.manage_search_rounded, label: 'مطابقة: ${result.matchedTerms.join('، ')}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
                  IconButton.filledTonal(
                    tooltip: isFavorite ? 'حذف من المفضلة' : 'إضافة إلى المفضلة',
                    onPressed: () async {
                      final bool added = isAd
                          ? await controller.toggleFavoriteAd(result.id)
                          : await controller.toggleFavoriteProvider(result.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(added ? 'تمت الإضافة إلى المفضلة.' : 'تم الحذف من المفضلة.')),
                      );
                    },
                    icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                  ),
                  const SizedBox(height: 8),
                  IconButton.outlined(
                    tooltip: 'فتح التفاصيل',
                    onPressed: () => _openDetails(context),
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    if (result.type == SearchResultType.ad) {
      Navigator.of(context).pushNamed(
        AppRoutes.adDetails,
        arguments: AdDetailsScreenArgs(adId: result.id),
      );
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.providerProfile,
      arguments: ProviderProfileScreenArgs(providerId: result.id),
    );
  }
}

class _ResultThumbnail extends StatelessWidget {
  const _ResultThumbnail({required this.result});

  final SmartSearchResult result;

  @override
  Widget build(BuildContext context) {
    if (result.ad != null) {
      return SizedBox(
        width: 104,
        child: AdImageView(imageUrl: result.ad!.primaryImage, height: 104, borderRadius: 18),
      );
    }
    final String? logo = result.provider?.profile.logoImageUrl;
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: (logo ?? '').trim().isEmpty
          ? Icon(Icons.storefront_outlined, size: 42, color: Theme.of(context).colorScheme.onPrimaryContainer)
          : Image.network(
              logo!,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Icon(
                Icons.storefront_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }
}
