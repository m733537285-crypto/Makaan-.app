import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/ad_models.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../ads/presentation/screens/ad_details_screen.dart';
import '../../../ads/presentation/widgets/ad_ui.dart';
import '../../../providers/presentation/screens/provider_profile_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppUser user = controller.currentUser!;
    final ProviderDetails? provider = controller.currentProviderDetails;

    return AppScaffold(
      title: 'الرئيسية',
      currentNavIndex: 0,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _HomeBannerCarousel(ads: controller.bannerAds),
              const SizedBox(height: 18),
              _QuickAdsStrip(featuredAds: controller.featuredAds.take(4).toList(growable: false)),
              const SizedBox(height: 18),
              _SmartDiscoverySection(controller: controller),
              const SizedBox(height: 18),
              if (user.isProvider)
                _ProviderHomeSection(provider: provider)
              else
                _ClientHomeSection(user: user),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({required this.ads});

  final List<AdListing> ads;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads.length != widget.ads.length) {
      _currentIndex = 0;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) {
      return const EmptyStateCard(
        title: 'لا توجد بنرات حالياً',
        subtitle: 'ستظهر هنا عروض اليوم والإعلانات العلوية بمجرد توفرها.',
        icon: Icons.slideshow_outlined,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionTitleRow(
              title: 'الشريط الإعلاني',
              subtitle: 'عروض متحركة سريعة مع انتقال تلقائي وزر لعرض التفاصيل.',
              trailing: AppSecondaryButton(
                label: 'كل الإعلانات',
                icon: Icons.campaign_outlined,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ads),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.ads.length,
                onPageChanged: (int index) => setState(() => _currentIndex = index),
                itemBuilder: (BuildContext context, int index) {
                  final AdListing ad = widget.ads[index];
                  return _BannerCard(ad: ad);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                widget.ads.length,
                (int index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 22 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted || widget.ads.length < 2) {
        return;
      }
      final int nextPage = (_currentIndex + 1) % widget.ads.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.ad});

  final AdListing ad;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.adDetails,
        arguments: AdDetailsScreenArgs(adId: ad.adId),
      ),
      child: Stack(
        children: <Widget>[
          AdImageView(imageUrl: ad.primaryImage, height: 280, borderRadius: 24),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[Color(0xCC0F172A), Color(0x220F172A)],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 18,
            end: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DealBadge(ad: ad),
                const SizedBox(height: 10),
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '${ad.priceAfter.round()} ر.ي',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (ad.priceBefore > 0)
                      Text(
                        '${ad.priceBefore.round()} ر.ي',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.adDetails,
                        arguments: AdDetailsScreenArgs(adId: ad.adId),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('عرض التفاصيل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdsStrip extends StatelessWidget {
  const _QuickAdsStrip({required this.featuredAds});

  final List<AdListing> featuredAds;

  @override
  Widget build(BuildContext context) {
    if (featuredAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionTitleRow(
              title: 'عروض سريعة',
              subtitle: 'بطاقات جميلة وسريعة التنقل لأهم الإعلانات الحالية.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredAds.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final AdListing ad = featuredAds[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.adDetails,
                      arguments: AdDetailsScreenArgs(adId: ad.adId),
                    ),
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              DealBadge(ad: ad),
                              if (ad.discountPercent > 0)
                                Chip(label: Text('${ad.discountPercent}% خصم')),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            ad.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text('${ad.priceAfter.round()} ر.ي', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SmartDiscoverySection extends StatelessWidget {
  const _SmartDiscoverySection({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final List<String> services = controller.mostRequestedServices.take(6).toList(growable: false);
    final List<AdListing> featuredAds = controller.featuredAds.take(3).toList(growable: false);
    final List<ProviderDetails> topProviders = controller.topRatedProviders.take(3).toList(growable: false);
    final List<ProviderDetails> newProviders = controller.newProviderDetails.take(3).toList(growable: false);
    final List<AdListing> offers = controller.todayDeals.isNotEmpty
        ? controller.todayDeals.take(3).toList(growable: false)
        : controller.halfPriceDeals.take(3).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionTitleRow(
              title: 'اقتراحات ذكية',
              subtitle: 'خدمات مطلوبة، إعلانات مميزة، مقدمو خدمات أعلى تقييماً، وخدمات جديدة حسب البيانات المتاحة.',
              trailing: AppSecondaryButton(
                label: 'بحث ذكي',
                icon: Icons.manage_search_rounded,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double tileWidth = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth > 620
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: tileWidth,
                      child: _SuggestionGroup(
                        title: 'الأكثر طلباً',
                        icon: Icons.local_fire_department_outlined,
                        children: services
                            .map(
                              (String service) => ActionChip(
                                label: Text(service),
                                onPressed: () => Navigator.of(context).pushNamed(
                                  AppRoutes.search,
                                  arguments: SearchScreenArgs(initialQuery: service),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _SuggestionGroup(
                        title: 'إعلانات مميزة',
                        icon: Icons.workspace_premium_outlined,
                        children: featuredAds
                            .map(
                              (AdListing ad) => _SmallLinkTile(
                                title: ad.title,
                                subtitle: '${ad.priceAfter.round()} ر.ي',
                                icon: Icons.campaign_outlined,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.adDetails,
                                  arguments: AdDetailsScreenArgs(adId: ad.adId),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _SuggestionGroup(
                        title: 'الأعلى تقييماً',
                        icon: Icons.star_rounded,
                        children: topProviders
                            .map(
                              (ProviderDetails provider) => _SmallLinkTile(
                                title: provider.profile.businessName,
                                subtitle: '${provider.averageRating.toStringAsFixed(1)} ⭐ • ${provider.profile.district}',
                                icon: Icons.storefront_outlined,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.providerProfile,
                                  arguments: ProviderProfileScreenArgs(providerId: provider.profile.providerId),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _SuggestionGroup(
                        title: 'خدمات جديدة',
                        icon: Icons.fiber_new_rounded,
                        children: newProviders
                            .map(
                              (ProviderDetails provider) => _SmallLinkTile(
                                title: provider.profile.businessName,
                                subtitle: provider.profile.mainServiceType,
                                icon: Icons.new_releases_outlined,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.providerProfile,
                                  arguments: ProviderProfileScreenArgs(providerId: provider.profile.providerId),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _SuggestionGroup(
                        title: 'العروض المميزة',
                        icon: Icons.local_offer_outlined,
                        children: offers
                            .map(
                              (AdListing ad) => _SmallLinkTile(
                                title: ad.title,
                                subtitle: ad.discountPercent > 0 ? 'خصم ${ad.discountPercent}%' : ad.dealType.arabicLabel,
                                icon: Icons.sell_outlined,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.adDetails,
                                  arguments: AdDetailsScreenArgs(adId: ad.adId),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionGroup extends StatelessWidget {
  const _SuggestionGroup({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text('لا توجد بيانات كافية حالياً.', style: Theme.of(context).textTheme.bodyMedium)
          else
            Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _SmallLinkTile extends StatelessWidget {
  const _SmallLinkTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderHomeSection extends StatelessWidget {
  const _ProviderHomeSection({required this.provider});

  final ProviderDetails? provider;

  @override
  Widget build(BuildContext context) {
    if (provider == null) {
      return Column(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('ابدأ نشاطك داخل مكان', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'تم إنشاء حساب مقدم خدمة بنجاح. الخطوة التالية هي بناء الملف التجاري بالكامل مع الخدمات، المعرض، التغطية، الاشتراك، والتقييمات.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  AppPrimaryButton(
                    label: 'إنشاء الملف التجاري',
                    icon: Icons.storefront_outlined,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerSetup),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('مرحباً ${provider.profile.businessName}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'ملفك التجاري جاهز داخل التطبيق مع نظام اشتراك وتقييمات ومعرض ومناطق عمل محفوظة، والآن تم ربطه بصندوق طلبات فعلي وإعلانات وعروض محلية.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    Chip(label: Text(provider.profile.status.arabicLabel)),
                    Chip(label: Text('${provider.averageRating.toStringAsFixed(1)} ⭐')),
                    Chip(label: Text('${provider.reviewCount} تقييم')),
                    Chip(label: Text(provider.isVisibleInApp ? 'ظاهر في التطبيق' : 'مخفي حالياً')),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    AppPrimaryButton(
                      label: 'Business Profile',
                      icon: Icons.storefront_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerProfile),
                    ),
                    AppSecondaryButton(
                      label: 'إضافة إعلان',
                      icon: Icons.campaign_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addAd),
                    ),
                    AppSecondaryButton(
                      label: 'الاشتراك',
                      icon: Icons.workspace_premium_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.subscription),
                    ),
                    AppSecondaryButton(
                      label: 'التقييمات',
                      icon: Icons.reviews_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reviews),
                    ),
                    AppSecondaryButton(
                      label: 'الطلبات',
                      icon: Icons.receipt_long_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.orders),
                    ),
                    AppSecondaryButton(
                      label: 'الإشعارات',
                      icon: Icons.notifications_none_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 960 ? 3 : 1,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.38,
          children: <Widget>[
            _StatusCard(
              title: 'الخدمات',
              value: '${provider.services.length}',
              subtitle: 'عدد الخدمات المسجلة داخل ملف النشاط التجاري.',
              icon: Icons.handyman_outlined,
            ),
            _StatusCard(
              title: 'المعرض',
              value: '${provider.gallery.length}',
              subtitle: 'صور الخدمات والأعمال السابقة والمعدات.',
              icon: Icons.photo_library_outlined,
            ),
            _StatusCard(
              title: 'التغطية',
              value: '${provider.serviceAreas.map((ProviderServiceArea item) => item.district).toSet().length} مديرية',
              subtitle: 'مناطق العمل المستخدمة لاحقاً لإظهار مقدمي الخدمات القريبين.',
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _ClientHomeSection extends StatelessWidget {
  const _ClientHomeSection({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('مرحباً ${user.displayName}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'أصبح التطبيق يعمل فعلياً: يمكنك الآن إنشاء طلبات خدمة، متابعة حالتها، واستكشاف سوق إعلانات محلي متكامل مع عروض يومية.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    Chip(label: Text(user.userType?.arabicLabel ?? 'غير محدد')),
                    Chip(label: Text(user.phoneNumber)),
                    Chip(label: Text(user.hasCompletedProfile ? 'الملف مكتمل' : 'الملف يحتاج استكمال')),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    AppPrimaryButton(
                      label: 'الملف الشخصي',
                      icon: Icons.person_outline_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
                    ),
                    AppSecondaryButton(
                      label: 'طلب خدمة',
                      icon: Icons.add_task_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createRequest),
                    ),
                    AppSecondaryButton(
                      label: 'الإعلانات',
                      icon: Icons.campaign_outlined,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ads),
                    ),
                    AppSecondaryButton(
                      label: 'طلباتي',
                      icon: Icons.receipt_long_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.orders),
                    ),
                    AppSecondaryButton(
                      label: 'التصنيفات',
                      icon: Icons.grid_view_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.categories),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.45,
          children: const <Widget>[
            _StatusCard(
              title: 'الجلسة',
              value: 'محفوظة محلياً',
              subtitle: 'يتم فتح التطبيق مباشرة بدون إعادة تسجيل الدخول.',
              icon: Icons.verified_user_outlined,
            ),
            _StatusCard(
              title: 'OTP',
              value: '6 أرقام',
              subtitle: 'تحقق مع مؤقت إعادة إرسال وحد أقصى للمحاولات.',
              icon: Icons.password_rounded,
            ),
            _StatusCard(
              title: 'سوق الإعلانات',
              value: 'مفعّل',
              subtitle: 'بنرات، عروض، صفحات تفاصيل، وإضافة إعلان من داخل التطبيق.',
              icon: Icons.campaign_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.value, required this.subtitle, required this.icon});

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(child: Icon(icon)),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
