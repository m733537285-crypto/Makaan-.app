import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/ad_models.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../widgets/ad_ui.dart';
import 'ad_details_screen.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  AdCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<AdListing> filteredAds = _selectedCategory == null
        ? controller.activeAds
        : controller.adsByCategory(_selectedCategory!);
    final List<AdListing> myAds = controller.myAds;

    return AppScaffold(
      title: 'الإعلانات والعروض',
      currentNavIndex: 3,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addAd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة إعلان'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SectionTitleRow(
                        title: 'سوق مكان للإعلانات',
                        subtitle: 'إعلانات السيارات والعقارات والمنتجات والخدمات المخفضة في مكان واحد.',
                        trailing: AppSecondaryButton(
                          label: 'إنشاء إعلان',
                          icon: Icons.campaign_outlined,
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addAd),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _MetricCard(title: 'الإعلانات النشطة', value: '${controller.activeAds.length}', icon: Icons.campaign_outlined),
                          _MetricCard(title: 'عروض اليوم', value: '${controller.todayDeals.length}', icon: Icons.local_offer_outlined),
                          _MetricCard(title: 'نصف السعر', value: '${controller.halfPriceDeals.length}', icon: Icons.percent_rounded),
                          _MetricCard(title: 'إعلاناتي', value: '${myAds.length}', icon: Icons.person_outline_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('التصنيفات', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          ChoiceChip(
                            selected: _selectedCategory == null,
                            label: const Text('الكل'),
                            onSelected: (_) => setState(() => _selectedCategory = null),
                          ),
                          ...controller.availableAdCategories.map(
                            (AdCategory category) => ChoiceChip(
                              selected: _selectedCategory == category,
                              label: Text(category.arabicLabel),
                              onSelected: (_) => setState(() => _selectedCategory = category),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _AdSection(
                title: '🏷 عروض اليوم',
                subtitle: 'عروض يومية سريعة الظهور مناسبة للشراء السريع.',
                ads: controller.todayDeals,
              ),
              const SizedBox(height: 22),
              _AdSection(
                title: '🛒 منتجات للبيع',
                subtitle: 'منتجات وبقالات وأجهزة إلكترونية جاهزة للشراء.',
                ads: controller.productAds,
              ),
              const SizedBox(height: 22),
              _AdSection(
                title: '🚗 سيارات للبيع',
                subtitle: 'سيارات مع صور متعددة وأسعار واضحة وبيانات تواصل مباشرة.',
                ads: controller.adsByCategory(AdCategory.cars),
              ),
              const SizedBox(height: 22),
              _AdSection(
                title: '🏠 عقارات',
                subtitle: 'شقق وأراضٍ ووحدات معروضة داخل السوق المحلي.',
                ads: controller.adsByCategory(AdCategory.realEstate),
              ),
              const SizedBox(height: 22),
              _AdSection(
                title: '🔧 خدمات مخفضة',
                subtitle: 'خصومات وعروض مؤقتة على الخدمات والمطاعم.',
                ads: controller.discountedServiceAds,
              ),
              const SizedBox(height: 22),
              SectionTitleRow(
                title: _selectedCategory == null ? 'استكشاف كل الإعلانات' : 'استكشاف ${_selectedCategory!.arabicLabel}',
                subtitle: 'تصفّح البطاقات الكاملة واضغط على أي إعلان لفتح التفاصيل.',
              ),
              const SizedBox(height: 14),
              if (filteredAds.isEmpty)
                const EmptyStateCard(
                  title: 'لا توجد إعلانات في هذا التصنيف',
                  subtitle: 'جرّب تصنيفاً آخر أو أضف إعلاناً جديداً.',
                )
              else
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final int columns = constraints.maxWidth > 1020
                        ? 3
                        : constraints.maxWidth > 700
                            ? 2
                            : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAds.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: constraints.maxWidth > 700 ? 0.88 : 0.9,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final AdListing ad = filteredAds[index];
                        return AdCard(
                          ad: ad,
                          onTap: () => _openAdDetails(ad),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 22),
              SectionTitleRow(
                title: 'إدارة إعلاناتي',
                subtitle: 'متابعة الحالات: نشط، بانتظار المراجعة، منتهي، ومرفوض.',
              ),
              const SizedBox(height: 14),
              if (myAds.isEmpty)
                EmptyStateCard(
                  title: 'لا توجد إعلانات مرتبطة بحسابك بعد',
                  subtitle: 'أضف أول إعلان الآن وسيظهر هنا مع حالته الحالية.',
                  icon: Icons.add_business_outlined,
                )
              else
                ...myAds.map(
                  (AdListing ad) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AdCard(
                      ad: ad,
                      showStatus: true,
                      onTap: () => _openAdDetails(ad),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdDetails(AdListing ad) {
    Navigator.of(context).pushNamed(
      AppRoutes.adDetails,
      arguments: AdDetailsScreenArgs(adId: ad.adId),
    );
  }
}

class _AdSection extends StatelessWidget {
  const _AdSection({
    required this.title,
    required this.subtitle,
    required this.ads,
  });

  final String title;
  final String subtitle;
  final List<AdListing> ads;

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      return EmptyStateCard(title: title, subtitle: 'لا توجد عناصر متاحة حالياً في هذا القسم.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitleRow(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        SizedBox(
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 14),
            itemBuilder: (BuildContext context, int index) {
              final AdListing ad = ads[index];
              return SizedBox(
                width: 320,
                child: AdCard(
                  ad: ad,
                  compact: true,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.adDetails,
                      arguments: AdDetailsScreenArgs(adId: ad.adId),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
