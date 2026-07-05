import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppUser user = controller.currentUser!;
    final ProviderDetails? provider = controller.currentProviderDetails;

    return AppScaffold(
      title: 'الملف الشخصي',
      currentNavIndex: 4,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 34,
                        child: Text(
                          user.displayName.substring(0, 1),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(user.displayName, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 6),
                            Text(user.phoneNumber),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                Chip(label: Text(user.userType?.arabicLabel ?? 'غير محدد')),
                                Chip(label: Text(user.isVerified ? 'موثق' : 'غير موثق')),
                                if (user.isProvider)
                                  Chip(label: Text(provider == null ? 'ملف تجاري غير مكتمل' : provider.profile.status.arabicLabel)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('البيانات الأساسية', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
                      _InfoRow(label: 'الاسم', value: (user.name?.trim() ?? '').isNotEmpty ? user.name!.trim() : 'غير مضاف'),
                      _InfoRow(label: 'رقم الهاتف', value: user.phoneNumber),
                      _InfoRow(label: 'نوع الحساب', value: user.userType?.arabicLabel ?? 'غير محدد'),
                      _InfoRow(label: 'المحافظة', value: user.governorate ?? 'غير محددة'),
                      _InfoRow(label: 'المديرية', value: user.district ?? 'غير محددة'),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          AppPrimaryButton(
                            label: 'تعديل الملف',
                            icon: Icons.edit_outlined,
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
                          ),
                          AppSecondaryButton(
                            label: 'تسجيل الخروج',
                            icon: Icons.logout_rounded,
                            onPressed: () => _logout(context, controller),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (user.isProvider) ...<Widget>[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('بيانات مقدم الخدمة', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 14),
                        if (provider == null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('لم يتم إنشاء الملف التجاري بعد.', style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 16),
                              AppPrimaryButton(
                                label: 'إنشاء الملف التجاري',
                                icon: Icons.storefront_outlined,
                                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerSetup),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _InfoRow(label: 'الاسم التجاري', value: provider.profile.businessName),
                              _InfoRow(label: 'الخدمة الرئيسية', value: provider.profile.mainServiceType),
                              _InfoRow(label: 'الاشتراك', value: provider.subscription == null ? 'غير مضاف' : provider.subscription!.status.arabicLabel),
                              _InfoRow(label: 'التقييم', value: provider.averageRating.toStringAsFixed(1)),
                              _InfoRow(label: 'الخدمات', value: '${provider.services.length}'),
                              _InfoRow(label: 'الصور', value: '${provider.gallery.length}'),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: <Widget>[
                                  AppPrimaryButton(
                                    label: 'Business Profile',
                                    icon: Icons.open_in_new_rounded,
                                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.providerProfile),
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
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, AppController controller) async {
    await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'تسجيل الخروج',
      message: 'هل تريد إنهاء الجلسة الحالية؟',
      onConfirm: () async {
        await controller.logout();
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (Route<dynamic> route) => false,
        );
      },
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
