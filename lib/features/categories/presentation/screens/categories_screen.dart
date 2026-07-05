import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/search_models.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../ads/presentation/screens/ad_details_screen.dart';
import '../../../ads/presentation/widgets/ad_ui.dart';
import '../../../providers/presentation/screens/provider_profile_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selectedCategoryKey;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<DiscoveryCategory> categories = controller.discoveryCategories;
    final DiscoveryCategory selectedCategory = categories.firstWhere(
      (DiscoveryCategory item) => item.key == _selectedCategoryKey,
      orElse: () => categories.first,
    );
    _selectedCategoryKey ??= selectedCategory.key;

    final SmartSearchFilters filters = SmartSearchFilters(categoryKey: _selectedCategoryKey);
    final List<SmartSearchResult> results = controller.smartSearch(query: '', filters: filters);

    return AppScaffold(
      title: 'التصنيفات',
      currentNavIndex: 1,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _CategoriesHero(
                onSearchPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int columns = constraints.maxWidth > 980
                      ? 4
                      : constraints.maxWidth > 680
                          ? 3
                          : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth > 680 ? 1.8 : 1.35,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final DiscoveryCategory category = categories[index];
                      return _CategoryCard(
                        category: category,
                        selected: category.key == _selectedCategoryKey,
                        onTap: () => setState(() => _selectedCategoryKey = category.key),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              _CategoryResultsHeader(
                category: selectedCategory,
                count: results.length,
                onOpenInSearch: () => Navigator.of(context).pushNamed(
                  AppRoutes.search,
                  arguments: SearchScreenArgs(categoryKey: selectedCategory.key),
                ),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                EmptyStateCard(
                  title: 'لا توجد خدمات في هذا التصنيف حالياً',
                  subtitle: 'سيتم عرض الخدمات والإعلانات المرتبطة بتصنيف ${selectedCategory.label} بمجرد توفرها.',
                  icon: Icons.category_outlined,
                )
              else
                ...results.map(
                  (SmartSearchResult item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryResultTile(result: item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesHero extends StatelessWidget {
  const _CategoriesHero({required this.onSearchPressed});

  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.grid_view_rounded, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('اكتشاف الخدمات حسب التصنيف', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'اختر التصنيف المناسب لعرض مقدمي الخدمات والإعلانات المرتبطة به فقط، مع إمكانية فتح نفس التصنيف داخل البحث الذكي.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppPrimaryButton(
              label: 'بحث متقدم',
              icon: Icons.manage_search_rounded,
              onPressed: onSearchPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.selected, required this.onTap});

  final DiscoveryCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.primaryContainer : scheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(category.emoji, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(category.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                category.keywords.take(3).join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryResultsHeader extends StatelessWidget {
  const _CategoryResultsHeader({required this.category, required this.count, required this.onOpenInSearch});

  final DiscoveryCategory category;
  final int count;
  final VoidCallback onOpenInSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${category.emoji} ${category.label}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('يعرض هذا القسم الخدمات والإعلانات المرتبطة بهذا التصنيف فقط.', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Chip(label: Text('$count نتيجة')),
        const SizedBox(width: 8),
        AppSecondaryButton(
          label: 'فتح في البحث',
          icon: Icons.search_rounded,
          onPressed: onOpenInSearch,
        ),
      ],
    );
  }
}

class _CategoryResultTile extends StatelessWidget {
  const _CategoryResultTile({required this.result});

  final SmartSearchResult result;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final bool isAd = result.type == SearchResultType.ad;
    final bool isFavorite = isAd
        ? controller.isFavoriteAd(result.id)
        : controller.isFavoriteProvider(result.id);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 26,
          child: Icon(isAd ? Icons.campaign_outlined : Icons.storefront_outlined),
        ),
        title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AdMetaChip(icon: Icons.location_on_outlined, label: result.locationText.isEmpty ? 'غير محدد' : result.locationText),
              AdMetaChip(icon: Icons.category_outlined, label: result.categoryLabel.isEmpty ? 'غير محدد' : result.categoryLabel),
              if (result.rating > 0) AdMetaChip(icon: Icons.star_rounded, label: result.rating.toStringAsFixed(1)),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 6,
          children: <Widget>[
            IconButton(
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
            IconButton(
              tooltip: 'فتح التفاصيل',
              onPressed: () => _openDetails(context),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
        onTap: () => _openDetails(context),
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
