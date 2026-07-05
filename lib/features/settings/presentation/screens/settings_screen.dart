import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppSettings settings = controller.appSettings;
    return AppScaffold(
      title: 'الإعدادات',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _SettingsCard(
                title: 'المظهر واللغة',
                icon: Icons.tune_rounded,
                children: <Widget>[
                  const Text('اللغة'),
                  const SizedBox(height: 10),
                  SegmentedButton<Locale>(
                    segments: const <ButtonSegment<Locale>>[
                      ButtonSegment(value: Locale('ar'), label: Text('العربية')),
                      ButtonSegment(value: Locale('en'), label: Text('English')),
                    ],
                    selected: <Locale>{controller.locale},
                    onSelectionChanged: (Set<Locale> value) async {
                      await controller.updateAdvancedSettings(locale: value.first);
                      if (context.mounted) {
                        AppDialogs.showSuccessSnackBar(context, 'تم تحديث اللغة');
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('الوضع الليلي'),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                      ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                    ],
                    selected: <ThemeMode>{controller.themeMode},
                    onSelectionChanged: (Set<ThemeMode> value) async {
                      await controller.updateAdvancedSettings(themeMode: value.first);
                      if (context.mounted) {
                        AppDialogs.showSuccessSnackBar(context, 'تم تحديث السمة');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'الإشعارات',
                icon: Icons.notifications_active_outlined,
                children: <Widget>[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إشعارات الطلبات والحساب'),
                    subtitle: const Text('تنبيهات الطلبات، الإعلانات، الاشتراكات وتحديثات النظام.'),
                    value: settings.pushNotificationsEnabled,
                    onChanged: (bool value) => controller.updateAdvancedSettings(pushNotificationsEnabled: value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إشعارات العروض'),
                    subtitle: const Text('تنبيهات غير حرجة للعروض والإعلانات المميزة.'),
                    value: settings.marketingNotificationsEnabled,
                    onChanged: (bool value) => controller.updateAdvancedSettings(marketingNotificationsEnabled: value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'حالة الربط والأداء',
                icon: Icons.speed_rounded,
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(controller.isRemoteBackendEnabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
                    title: Text(controller.isRemoteBackendEnabled ? 'قاعدة البيانات السحابية مفعّلة' : 'التطبيق يعمل حالياً بالوضع المحلي'),
                    subtitle: Text(
                      controller.backendStatusMessage ??
                          (controller.isRemoteBackendEnabled
                              ? 'البيانات تقرأ من Supabase مع ذاكرة محلية مؤقتة.'
                              : 'أضف مفاتيح Supabase عند التشغيل لتفعيل الربط الحقيقي.'),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تشخيص الأداء'),
                    subtitle: const Text('حفظ أزمنة التحميل والأخطاء الحرجة في سجل النظام.'),
                    value: settings.performanceDiagnosticsEnabled,
                    onChanged: (bool value) => controller.updateAdvancedSettings(performanceDiagnosticsEnabled: value),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _MetricChip(label: 'عينات الأداء', value: controller.performanceSamples.length.toString()),
                      _MetricChip(label: 'أخطاء حديثة', value: controller.runtimeErrors.length.toString()),
                    ],
                  ),
                  if (controller.isRemoteBackendEnabled) ...<Widget>[
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await controller.refreshBackendData();
                          if (context.mounted) {
                            AppDialogs.showSuccessSnackBar(context, 'تم تحديث البيانات من الخادم.');
                          }
                        },
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('تحديث من الخادم'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'القانوني والدعم',
                icon: Icons.privacy_tip_outlined,
                children: const <Widget>[
                  _InfoTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    subtitle: 'يتم حفظ بيانات الحساب والطلبات والمفضلة فقط لتشغيل خدمات المنصة.',
                  ),
                  _InfoTile(
                    icon: Icons.gavel_outlined,
                    title: 'الشروط والأحكام',
                    subtitle: 'استخدام المنصة يعني الالتزام بعدم نشر إعلانات مضللة أو بيانات غير صحيحة.',
                  ),
                  _InfoTile(
                    icon: Icons.headset_mic_outlined,
                    title: 'التواصل مع الدعم',
                    subtitle: 'يمكن إرسال البلاغات والملاحظات من صفحة الدعم داخل التطبيق.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(child: Text(value)),
      label: Text(label),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
