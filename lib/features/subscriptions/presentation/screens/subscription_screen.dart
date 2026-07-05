import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const List<String> _plans = <String>['Basic', 'Pro', 'Premium', 'Enterprise'];
  String _planType = _plans.first;
  ProviderAccountStatus _accountStatus = ProviderAccountStatus.pending;
  SubscriptionStatus _status = SubscriptionStatus.pending;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _seeded = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final ProviderDetails? details = AppScope.of(context).currentProviderDetails;
    _accountStatus = details == null ? ProviderAccountStatus.pending : details.profile.status;
    final ProviderSubscription? subscription = details?.subscription;
    if (subscription != null) {
      _planType = subscription.planType;
      _status = subscription.status;
      _paymentStatus = subscription.paymentStatus;
      _startDate = subscription.startDate;
      _endDate = subscription.endDate;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initialDate = isStart ? _startDate : _endDate;
    final DateTime firstDate = DateTime.now().subtract(const Duration(days: 365));
    final DateTime lastDate = DateTime.now().add(const Duration(days: 3650));
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ar'),
    );
    if (result == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = result;
        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      } else {
        _endDate = result;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_endDate.isAfter(_startDate)) {
      AppDialogs.showErrorSnackBar(context, 'يجب أن يكون تاريخ الانتهاء بعد تاريخ البداية.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final AppController controller = AppScope.of(context);
      await controller.saveProviderSubscription(
        planType: _planType,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        paymentStatus: _paymentStatus,
      );
      await controller.saveProviderAccountStatus(_accountStatus);
      if (!mounted) {
        return;
      }
      AppDialogs.showSuccessSnackBar(context, 'تم تحديث حالة الاشتراك.');
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
    final AppController controller = AppScope.of(context);
    final ProviderDetails? provider = controller.currentProviderDetails;
    if (provider == null) {
      return AppScaffold(
        title: 'الاشتراك الشهري',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.workspace_premium_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text('ابدأ بإنشاء الملف التجاري أولاً', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'بعد إنشاء ملف مقدم الخدمة سيتم إنشاء سجل اشتراك افتراضي ويمكنك تحديث الخطة والحالة وتواريخ السريان من هنا.',
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
      title: 'الاشتراك الشهري',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('جاهزية الظهور داخل التطبيق', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        provider.isVisibleInApp
                            ? 'النشاط ظاهر حالياً لأن حالة الحساب والاشتراك مؤهلة.'
                            : 'النشاط مخفي حالياً. يلزم أن تكون الحالة Active والدفع Paid حتى يظهر داخل التطبيق.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _SummaryCard(label: 'حالة الحساب', value: provider.profile.status.arabicLabel, icon: Icons.verified_outlined),
                          _SummaryCard(label: 'حالة الاشتراك', value: provider.subscription == null ? '--' : provider.subscription!.status.arabicLabel, icon: Icons.workspace_premium_outlined),
                          _SummaryCard(label: 'الدفع', value: provider.subscription == null ? '--' : provider.subscription!.paymentStatus.arabicLabel, icon: Icons.payments_outlined),
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
                      Text('إدارة بيانات الاشتراك', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'في المرحلة الحالية النظام جاهز بالكامل للحفظ والقراءة. التفعيل اليدوي سيُدار لاحقاً من لوحة التحكم، ويمكنك الآن تعديل القيم لاختبار تجربة الظهور والحالات.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _plans.contains(_planType) ? _planType : _plans.first,
                        items: _plans
                            .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                            .toList(growable: false),
                        decoration: const InputDecoration(
                          labelText: 'الخطة الشهرية',
                          prefixIcon: Icon(Icons.layers_outlined),
                        ),
                        onChanged: (String? value) => setState(() => _planType = value ?? _plans.first),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ProviderAccountStatus>(
                        value: _accountStatus,
                        items: ProviderAccountStatus.values
                            .map(
                              (ProviderAccountStatus item) => DropdownMenuItem<ProviderAccountStatus>(
                                value: item,
                                child: Text(item.arabicLabel),
                              ),
                            )
                            .toList(growable: false),
                        decoration: const InputDecoration(
                          labelText: 'حالة الحساب',
                          prefixIcon: Icon(Icons.manage_accounts_outlined),
                        ),
                        onChanged: (ProviderAccountStatus? value) => setState(() => _accountStatus = value ?? ProviderAccountStatus.pending),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<SubscriptionStatus>(
                              value: _status,
                              items: SubscriptionStatus.values
                                  .map(
                                    (SubscriptionStatus item) => DropdownMenuItem<SubscriptionStatus>(
                                      value: item,
                                      child: Text(item.arabicLabel),
                                    ),
                                  )
                                  .toList(growable: false),
                              decoration: const InputDecoration(
                                labelText: 'حالة الاشتراك',
                                prefixIcon: Icon(Icons.toggle_on_outlined),
                              ),
                              onChanged: (SubscriptionStatus? value) => setState(() => _status = value ?? SubscriptionStatus.pending),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<PaymentStatus>(
                              value: _paymentStatus,
                              items: PaymentStatus.values
                                  .map(
                                    (PaymentStatus item) => DropdownMenuItem<PaymentStatus>(
                                      value: item,
                                      child: Text(item.arabicLabel),
                                    ),
                                  )
                                  .toList(growable: false),
                              decoration: const InputDecoration(
                                labelText: 'حالة الدفع',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                              ),
                              onChanged: (PaymentStatus? value) => setState(() => _paymentStatus = value ?? PaymentStatus.unpaid),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _DateTile(
                              label: 'تاريخ البداية',
                              value: _formatDate(_startDate),
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateTile(
                              label: 'تاريخ الانتهاء',
                              value: _formatDate(_endDate),
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        expand: true,
                        label: _isSaving ? 'جارٍ حفظ الاشتراك...' : 'حفظ حالة الاشتراك',
                        icon: Icons.save_outlined,
                        onPressed: _isSaving ? null : _save,
                      ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
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
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
