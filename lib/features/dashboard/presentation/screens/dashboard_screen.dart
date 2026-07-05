import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final ProviderDetails? provider = controller.currentProviderDetails;

    if (provider == null) {
      return AppScaffold(
        title: 'لوحة التحكم',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.space_dashboard_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text('لوحة مقدم الخدمة', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ الملف التجاري أولاً ليظهر لك ملخص الخدمات، الاشتراك، مناطق العمل، والتقييمات في هذه اللوحة.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: 'إنشاء الملف التجاري',
                      icon: Icons.storefront_outlined,
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

    return AppScaffold(
      title: 'لوحة التحكم',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('مرحباً ${provider.profile.businessName}', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'هذه اللوحة تلخص أداء ملف النشاط التجاري والاستعداد للمرحلة القادمة الخاصة بالطلبات والإشعارات.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _MetricTile(label: 'الخدمات', value: '${provider.services.length}', icon: Icons.handyman_outlined),
                          _MetricTile(label: 'الصور', value: '${provider.gallery.length}', icon: Icons.photo_library_outlined),
                          _MetricTile(label: 'المناطق', value: '${provider.serviceAreas.map((ProviderServiceArea item) => item.district).toSet().length}', icon: Icons.location_on_outlined),
                          _MetricTile(label: 'التقييمات', value: '${provider.reviewCount}', icon: Icons.star_outline_rounded),
                          _MetricTile(label: 'المتوسط', value: provider.averageRating.toStringAsFixed(1), icon: Icons.auto_graph_outlined),
                          _MetricTile(label: 'الظهور', value: provider.isVisibleInApp ? 'ظاهر' : 'مخفي', icon: Icons.visibility_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          AppPrimaryButton(
                            label: 'الملف التجاري',
                            icon: Icons.storefront_outlined,
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerProfile),
                          ),
                          AppSecondaryButton(
                            label: 'تعديل البيانات',
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
                            icon: Icons.reviews_outlined,
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reviews),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('حالة النشاط الحالية', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _RowItem(label: 'حالة الحساب', value: provider.profile.status.arabicLabel),
                      _RowItem(label: 'خطة الاشتراك', value: provider.subscription?.planType ?? '--'),
                      _RowItem(label: 'حالة الاشتراك', value: provider.subscription == null ? '--' : provider.subscription!.status.arabicLabel),
                      _RowItem(label: 'الدفع', value: provider.subscription == null ? '--' : provider.subscription!.paymentStatus.arabicLabel),
                      _RowItem(label: 'انتهاء الاشتراك', value: provider.subscription == null ? '--' : _formatDate(provider.subscription!.endDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
