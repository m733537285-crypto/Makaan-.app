import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/ad_models.dart';
import '../../../../shared/models/favorite_models.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../ads/presentation/screens/ad_details_screen.dart';
import '../../../ads/presentation/widgets/ad_ui.dart';
import '../../../providers/presentation/screens/provider_profile_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<AdListing> ads = controller.favoriteAds;
    final List<ProviderDetails> providers = controller.favoriteProviders;

    return AppScaffold(
      title: 'المفضلة',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _FavoritesHero(adCount: ads.length, providerCount: providers.length),
              const SizedBox(height: 18),
              if (ads.isEmpty && providers.isEmpty)
                EmptyStateCard(
                  title: 'لا توجد عناصر محفوظة',
                  subtitle: 'أضف مقدمي الخدمات أو الإعلانات إلى المفضلة من البحث أو التصنيفات أو صفحات التفاصيل. يتم حفظها ومزامنتها مع حسابك الحالي داخل التطبيق.',
                  icon: Icons.favorite_border_rounded,
                )
              else ...<Widget>[
                if (providers.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'مقدمو الخدمات المفضلون', count: providers.length),
                  const SizedBox(height: 10),
                  ...providers.map(
                    (ProviderDetails provider) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FavoriteProviderTile(provider: provider),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (ads.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'الإعلانات المفضلة', count: ads.length),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final int columns = constraints.maxWidth > 880 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: columns == 2 ? 0.95 : 1.28,
                        ),
                        itemCount: ads.length,
                        itemBuilder: (BuildContext context, int index) => _FavoriteAdCard(ad: ads[index]),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesHero extends StatelessWidget {
  const _FavoritesHero({required this.adCount, required this.providerCount});

  final int adCount;
  final int providerCount;

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
              child: const Icon(Icons.favorite_rounded, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('المفضلة الخاصة بحسابك', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'قائمة موحدة للإعلانات ومقدمي الخدمات المحفوظة، مرتبطة بمعرّف المستخدم الحالي داخل التخزين المحلي للمشروع.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text('$providerCount مقدم خدمة')),
                Chip(label: Text('$adCount إعلان')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        Chip(label: Text('$count')),
      ],
    );
  }
}

class _FavoriteProviderTile extends StatelessWidget {
  const _FavoriteProviderTile({required this.provider});

  final ProviderDetails provider;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 28,
          child: Text(provider.profile.businessName.trim().isEmpty ? 'م' : provider.profile.businessName.trim().substring(0, 1)),
        ),
        title: Text(provider.profile.businessName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AdMetaChip(icon: Icons.handyman_outlined, label: provider.profile.mainServiceType),
              AdMetaChip(icon: Icons.location_on_outlined, label: '${provider.profile.governorate} - ${provider.profile.district}'),
              AdMetaChip(icon: Icons.star_rounded, label: provider.averageRating.toStringAsFixed(1)),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 6,
          children: <Widget>[
            IconButton(
              tooltip: 'حذف من المفضلة',
              onPressed: () async {
                await controller.removeFavorite(itemId: provider.profile.providerId, type: FavoriteItemType.provider);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف مقدم الخدمة من المفضلة.')));
              },
              icon: const Icon(Icons.favorite_rounded),
            ),
            IconButton.outlined(
              tooltip: 'فتح التفاصيل',
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.providerProfile,
                arguments: ProviderProfileScreenArgs(providerId: provider.profile.providerId),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.providerProfile,
          arguments: ProviderProfileScreenArgs(providerId: provider.profile.providerId),
        ),
      ),
    );
  }
}

class _FavoriteAdCard extends StatelessWidget {
  const _FavoriteAdCard({required this.ad});

  final AdListing ad;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AdCard(
            ad: ad,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.adDetails,
              arguments: AdDetailsScreenArgs(adId: ad.adId),
            ),
          ),
        ),
        PositionedDirectional(
          top: 12,
          end: 12,
          child: IconButton.filledTonal(
            tooltip: 'حذف من المفضلة',
            onPressed: () async {
              await controller.removeFavorite(itemId: ad.adId, type: FavoriteItemType.ad);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الإعلان من المفضلة.')));
            },
            icon: const Icon(Icons.favorite_rounded),
          ),
        ),
      ],
    );
  }
}
