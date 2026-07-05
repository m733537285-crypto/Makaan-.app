import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';

class ProviderProfileScreenArgs {
  const ProviderProfileScreenArgs({required this.providerId});

  final String providerId;
}

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key, this.args});

  final ProviderProfileScreenArgs? args;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final ProviderDetails? provider = args == null
        ? controller.currentProviderDetails
        : controller.findProviderById(args!.providerId);
    final bool isOwnProfile = provider != null &&
        controller.currentProviderDetails?.profile.providerId == provider.profile.providerId;
    final bool canManage = args == null || isOwnProfile;

    if (provider == null) {
      return AppScaffold(
        title: 'الملف التجاري',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.storefront_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(args == null ? 'لم يتم إنشاء ملف مقدم الخدمة بعد' : 'مقدم الخدمة غير متاح', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(
                      args == null
                          ? 'أكمل بيانات النشاط التجاري لإظهار الخدمات، المعرض، الاشتراك، والتقييمات في صفحة احترافية عامة.'
                          : 'قد يكون مقدم الخدمة غير موجود أو تم إخفاؤه مؤقتاً.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    if (args == null)
                      AppPrimaryButton(
                        label: 'إنشاء الملف التجاري',
                        icon: Icons.add_business_outlined,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerSetup),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ProviderProfile profile = provider.profile;
    return AppScaffold(
      title: 'Business Profile',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _ProfileHero(provider: provider, canManage: canManage),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(width: 330, child: _BusinessInfoCard(provider: provider)),
                  SizedBox(width: 330, child: _SubscriptionInfoCard(provider: provider)),
                  SizedBox(width: 330, child: _ContactCard(profile: profile)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(width: 520, child: _ServicesCard(provider: provider)),
                  SizedBox(width: 520, child: _AreasCard(provider: provider)),
                ],
              ),
              const SizedBox(height: 16),
              _GalleryCard(provider: provider),
              const SizedBox(height: 16),
              _ReviewsCard(provider: provider, canManage: canManage),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.provider, required this.canManage});

  final ProviderDetails provider;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final ProviderProfile profile = provider.profile;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if ((profile.coverImageUrl ?? '').trim().isNotEmpty)
                  Image.network(
                    profile.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return _GradientCover(profile: profile);
                    },
                  )
                else
                  _GradientCover(profile: profile),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      _StatusPill(
                        label: profile.status.arabicLabel,
                        color: _statusColor(context, profile.status),
                      ),
                      _StatusPill(
                        label: provider.isVisibleInApp ? 'يظهر في التطبيق' : 'مخفي حالياً',
                        color: provider.isVisibleInApp ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 24,
                  left: 24,
                  bottom: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _LogoAvatar(profile: profile, radius: 44),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              profile.businessName,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.mainServiceType,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              children: <Widget>[
                                _QuickMeta(icon: Icons.star_rounded, text: '${provider.averageRating.toStringAsFixed(1)} من 5'),
                                _QuickMeta(icon: Icons.reviews_outlined, text: '${provider.reviewCount} تقييم'),
                                _QuickMeta(icon: Icons.groups_outlined, text: '${profile.customerCount} عميل'),
                                _QuickMeta(icon: Icons.location_on_outlined, text: '${profile.governorate} • ${profile.district}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    if (canManage) ...<Widget>[
                      AppPrimaryButton(
                        label: 'تعديل الملف',
                        icon: Icons.edit_outlined,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerSetup),
                      ),
                      AppSecondaryButton(
                        label: 'الاشتراك',
                        icon: Icons.workspace_premium_outlined,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.subscription),
                      ),
                      AppSecondaryButton(
                        label: 'التقييمات',
                        icon: Icons.star_outline_rounded,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reviews),
                      ),
                    ] else ...<Widget>[
                      _FavoriteProviderButton(providerId: profile.providerId),
                      AppSecondaryButton(
                        label: 'طلب خدمة',
                        icon: Icons.add_task_rounded,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createRequest),
                      ),
                    ],
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

class _BusinessInfoCard extends StatelessWidget {
  const _BusinessInfoCard({required this.provider});

  final ProviderDetails provider;

  @override
  Widget build(BuildContext context) {
    final ProviderProfile profile = provider.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('معلومات النشاط', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _InfoRow(label: 'رقم الملف', value: profile.providerId),
            _InfoRow(label: 'نوع الخدمة', value: profile.mainServiceType),
            _InfoRow(label: 'المحافظة', value: profile.governorate),
            _InfoRow(label: 'المديرية', value: profile.district),
            _InfoRow(label: 'أوقات العمل', value: profile.workingHours ?? 'غير محددة'),
            _InfoRow(label: 'العملاء', value: '${profile.customerCount}'),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionInfoCard extends StatelessWidget {
  const _SubscriptionInfoCard({required this.provider});

  final ProviderDetails provider;

  @override
  Widget build(BuildContext context) {
    final ProviderSubscription? subscription = provider.subscription;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('حالة الاشتراك', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            if (subscription == null)
              Text('لا يوجد اشتراك بعد.', style: Theme.of(context).textTheme.bodyLarge)
            else ...<Widget>[
              _InfoRow(label: 'الخطة', value: subscription.planType),
              _InfoRow(label: 'الحالة', value: subscription.status.arabicLabel),
              _InfoRow(label: 'الدفع', value: subscription.paymentStatus.arabicLabel),
              _InfoRow(label: 'من', value: _formatDate(subscription.startDate)),
              _InfoRow(label: 'إلى', value: _formatDate(subscription.endDate)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: (provider.isVisibleInApp ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                ),
                child: Text(
                  provider.isVisibleInApp
                      ? 'الملف ظاهر حالياً داخل التطبيق لأن حالة الحساب والاشتراك نشطة.'
                      : 'الملف غير ظاهر حالياً. يلزم اشتراك Active مدفوع ليظهر داخل التطبيق.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.profile});

  final ProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('التواصل', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _InfoRow(label: 'الهاتف', value: profile.phoneNumber),
            _InfoRow(label: 'واتساب', value: profile.whatsAppNumber ?? 'غير مضاف'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                AppPrimaryButton(
                  label: 'اتصال مباشر',
                  icon: Icons.phone_forwarded_outlined,
                  onPressed: () => _copyValue(context, profile.phoneNumber, 'تم نسخ رقم الاتصال'),
                ),
                AppSecondaryButton(
                  label: 'واتساب',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: profile.whatsAppNumber == null
                      ? null
                      : () => _copyValue(context, profile.whatsAppNumber!, 'تم نسخ رقم واتساب'),
                ),
                const AppSecondaryButton(
                  label: 'طلب الخدمة قريباً',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyValue(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    AppDialogs.showSuccessSnackBar(context, message);
  }
}

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({required this.provider});

  final ProviderDetails provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('الخدمات', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            if (provider.services.isEmpty)
              Text('لم يتم إضافة خدمات بعد.', style: Theme.of(context).textTheme.bodyLarge)
            else
              ...provider.services.map(
                (ProviderService item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(child: Text(item.title, style: Theme.of(context).textTheme.titleMedium)),
                            if (item.isPrimary) const Chip(label: Text('رئيسية')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
                        if (item.approximatePrice != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text('السعر التقريبي: ${item.approximatePrice!.toStringAsFixed(item.approximatePrice! % 1 == 0 ? 0 : 1)}', style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AreasCard extends StatelessWidget {
  const _AreasCard({required this.provider});

  final ProviderDetails provider;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> grouped = <String, List<String>>{};
    for (final ProviderServiceArea item in provider.serviceAreas) {
      grouped.putIfAbsent(item.district, () => <String>[]);
      if ((item.neighborhood ?? '').trim().isNotEmpty) {
        grouped[item.district]!.add(item.neighborhood!.trim());
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('مناطق الخدمة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'الظهور المستقبلي للعملاء سيتم وفق المحافظة والمديريات والأحياء المحددة هنا.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            if (grouped.isEmpty)
              Text('لا توجد مناطق مضافة.', style: Theme.of(context).textTheme.bodyLarge)
            else
              ...grouped.entries.map(
                (MapEntry<String, List<String>> entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (entry.value.isEmpty)
                          Text('تغطية المديرية بالكامل', style: Theme.of(context).textTheme.bodyMedium)
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.toSet().map((String item) => Chip(label: Text(item))).toList(growable: false),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.provider});

  final ProviderDetails provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('معرض الصور', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('صور الخدمات، الأعمال السابقة، والمعدات أو السيارات.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (provider.gallery.isEmpty)
              Text('لم تتم إضافة صور بعد.', style: Theme.of(context).textTheme.bodyLarge)
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.gallery.length,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final ProviderGalleryItem item = provider.gallery[index];
                    return SizedBox(
                      width: 240,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            if ((item.imageUrl ?? '').trim().isNotEmpty)
                              Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                  return _galleryPlaceholder(context, item);
                                },
                              )
                            else
                              _galleryPlaceholder(context, item),
                            Positioned(
                              right: 0,
                              left: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      Colors.black.withValues(alpha: 0.02),
                                      Colors.black.withValues(alpha: 0.66),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(item.caption, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                                    Text(item.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _galleryPlaceholder(BuildContext context, ProviderGalleryItem item) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.photo_library_outlined, size: 42),
          const SizedBox(height: 8),
          Text(item.category, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.provider, required this.canManage});

  final ProviderDetails provider;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final List<ProviderReview> latest = provider.latestReviews.take(3).toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('التقييمات', style: Theme.of(context).textTheme.titleLarge)),
                if (canManage)
                  AppSecondaryButton(
                    label: 'إدارة التقييمات',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reviews),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _MetricCard(label: 'المتوسط', value: provider.averageRating.toStringAsFixed(1), icon: Icons.star_rounded),
                _MetricCard(label: 'عدد التقييمات', value: '${provider.reviewCount}', icon: Icons.rate_review_outlined),
                _MetricCard(label: 'آخر تقييم', value: latest.isEmpty ? '--' : '${latest.first.rating}⭐', icon: Icons.schedule_outlined),
              ],
            ),
            const SizedBox(height: 16),
            if (latest.isEmpty)
              Text('لا توجد تقييمات بعد. يمكن للعميل إضافة تقييم بعد إتمام الخدمة.', style: Theme.of(context).textTheme.bodyLarge)
            else
              ...latest.map(
                (ProviderReview item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(child: Text(item.customerName, style: Theme.of(context).textTheme.titleMedium)),
                            Text('${item.rating} ⭐'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.comment, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Text(_formatDate(item.createdAt), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}


class _FavoriteProviderButton extends StatelessWidget {
  const _FavoriteProviderButton({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final bool isFavorite = controller.isFavoriteProvider(providerId);
    return AppPrimaryButton(
      label: isFavorite ? 'حذف من المفضلة' : 'إضافة إلى المفضلة',
      icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      onPressed: () async {
        final bool added = await controller.toggleFavoriteProvider(providerId);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(added ? 'تمت الإضافة إلى المفضلة.' : 'تم الحذف من المفضلة.')),
        );
      },
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.profile, required this.radius});

  final ProviderProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if ((profile.logoImageUrl ?? '').trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(profile.logoImageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Text(
        profile.businessName.isEmpty ? 'M' : profile.businessName.substring(0, 1),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.profile});

  final ProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[Color(0xFF0F766E), Color(0xFF2563EB), Color(0xFFF59E0B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.apartment_rounded, color: Colors.white, size: 52),
            const SizedBox(height: 10),
            Text(
              profile.businessName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMeta extends StatelessWidget {
  const _QuickMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, ProviderAccountStatus status) {
  switch (status) {
    case ProviderAccountStatus.active:
      return Colors.green;
    case ProviderAccountStatus.pending:
      return Colors.orange;
    case ProviderAccountStatus.suspended:
      return Theme.of(context).colorScheme.error;
    case ProviderAccountStatus.expired:
      return Colors.grey.shade700;
  }
}

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
