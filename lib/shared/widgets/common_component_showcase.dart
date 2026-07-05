import 'package:flutter/material.dart';

import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_state_widgets.dart';
import 'app_buttons.dart';
import 'app_input_fields.dart';

class CommonComponentShowcase extends StatelessWidget {
  const CommonComponentShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'المكونات المشتركة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Buttons, fields, cards, feedback, loaders, and reusable preview blocks.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                AppPrimaryButton(
                  label: 'رسالة نجاح',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => AppDialogs.showSuccessSnackBar(
                    context,
                    'تم تنفيذ الإجراء التجريبي بنجاح',
                  ),
                ),
                AppSecondaryButton(
                  label: 'حوار تأكيد',
                  icon: Icons.help_outline_rounded,
                  onPressed: () => AppDialogs.showConfirmationDialog(
                    context: context,
                    title: 'تأكيد الإجراء',
                    message: 'هذه نافذة منبثقة تجريبية قابلة لإعادة الاستخدام.',
                    onConfirm: () =>
                        AppDialogs.showSuccessSnackBar(context, 'تم التأكيد'),
                  ),
                ),
                AppTonalButton(
                  label: 'Bottom Sheet',
                  icon: Icons.expand_less_rounded,
                  onPressed: () => AppDialogs.showActionSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AppSearchField(hint: 'ابحث عن خدمة أو إعلان أو مزود'),
            const SizedBox(height: 14),
            const AppTextField(
              label: 'حقل إدخال',
              hint: 'مثال لعنصر مشترك',
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: _ServicePreviewCard()),
                const SizedBox(width: 12),
                Expanded(child: _AdPreviewCard()),
              ],
            ),
            const SizedBox(height: 14),
            const AppMessageState(
              icon: Icons.check_circle_outline_rounded,
              title: 'تم الحفظ بنجاح',
              message: 'مثال لرسائل النجاح المشتركة داخل النظام.',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.home_repair_service_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'بطاقة خدمة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('كهرباء · سباكة · صيانة · حجز سريع'),
          ],
        ),
      ),
    );
  }
}

class _AdPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 80,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Center(
                  child: Icon(Icons.photo_library_outlined, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('بطاقة إعلان', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('معرض، سعر، موقع، وCTA واضح للتواصل أو الحفظ.'),
          ],
        ),
      ),
    );
  }
}
