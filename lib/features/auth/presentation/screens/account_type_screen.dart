import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  UserType? _selectedType;
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_selectedType == null || _isSaving) {
      AppDialogs.showErrorSnackBar(context, 'اختر نوع الحساب أولاً.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final AppController controller = AppScope.of(context);
      await controller.chooseUserType(_selectedType!);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.editProfile,
        arguments: const EditProfileScreenArgs(forceComplete: true),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppDialogs.showErrorSnackBar(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const AppBrandLockup(),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'اختر نوع الحساب',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا يمكن تغيير هذا الاختيار بسهولة لاحقاً، لذا اختر النوع الذي يناسب استخدامك الأساسي داخل التطبيق.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 22),
                        _TypeCard(
                          icon: Icons.person_outline_rounded,
                          title: '👤 عميل',
                          subtitle: 'للبحث عن الخدمات وطلبها ومتابعة التنفيذ.',
                          selected: _selectedType == UserType.client,
                          onTap: () => setState(() => _selectedType = UserType.client),
                        ),
                        const SizedBox(height: 14),
                        _TypeCard(
                          icon: Icons.handyman_outlined,
                          title: '🛠 مقدم خدمة',
                          subtitle: 'لعرض خدماتك واستقبال الطلبات والتقييمات لاحقاً.',
                          selected: _selectedType == UserType.provider,
                          onTap: () => setState(() => _selectedType = UserType.provider),
                        ),
                        const SizedBox(height: 24),
                        AppPrimaryButton(
                          expand: true,
                          label: _isSaving ? 'جارٍ الحفظ...' : 'متابعة',
                          onPressed: _isSaving ? null : _continue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : scheme.surface,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: selected ? scheme.primary : scheme.primaryContainer,
              child: Icon(icon, color: selected ? scheme.onPrimary : scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? scheme.primary : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
