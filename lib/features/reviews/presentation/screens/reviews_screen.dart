import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSaving = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await AppScope.of(context).addProviderReview(
        customerName: _customerNameController.text,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) {
        return;
      }
      AppDialogs.showSuccessSnackBar(context, 'تم حفظ التقييم بنجاح.');
      _customerNameController.clear();
      _commentController.clear();
      setState(() => _rating = 5);
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
    final ProviderDetails? provider = AppScope.of(context).currentProviderDetails;
    if (provider == null) {
      return AppScaffold(
        title: 'التقييمات',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.rate_review_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text('أكمل ملف مقدم الخدمة أولاً', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'سيتم ربط التقييمات بملف النشاط التجاري بعد إنشائه، مع عرض المتوسط وعدد التقييمات وآخر المراجعات.',
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
      title: 'التقييمات',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('ملخص تقييمات ${provider.profile.businessName}', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _SummaryCard(label: 'متوسط التقييم', value: provider.averageRating.toStringAsFixed(1), icon: Icons.star_rounded),
                          _SummaryCard(label: 'عدد التقييمات', value: '${provider.reviewCount}', icon: Icons.reviews_outlined),
                          _SummaryCard(label: 'آخر تقييم', value: provider.latestReviews.isEmpty ? '--' : _formatDate(provider.latestReviews.first.createdAt), icon: Icons.schedule_outlined),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('إضافة تقييم جديد', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'هذه الواجهة تمثل سلوك العميل بعد انتهاء الخدمة: تقييم من 1 إلى 5 نجوم مع تعليق نصي محفوظ داخل قاعدة بيانات التطبيق المحلية.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم العميل',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (String? value) => (value?.trim().isEmpty ?? true) ? 'أدخل اسم العميل' : null,
                        ),
                        const SizedBox(height: 16),
                        Text('عدد النجوم', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: List<Widget>.generate(5, (int index) {
                            final int value = index + 1;
                            final bool selected = value == _rating;
                            return ChoiceChip(
                              label: Text('$value ⭐'),
                              selected: selected,
                              onSelected: (_) => setState(() => _rating = value),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'تعليق العميل',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.comment_outlined),
                          ),
                          validator: (String? value) => (value?.trim().length ?? 0) < 6 ? 'اكتب تعليقاً أوضح' : null,
                        ),
                        const SizedBox(height: 18),
                        AppPrimaryButton(
                          expand: true,
                          label: _isSaving ? 'جارٍ حفظ التقييم...' : 'حفظ التقييم',
                          icon: Icons.save_outlined,
                          onPressed: _isSaving ? null : _saveReview,
                        ),
                      ],
                    ),
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
                      Text('آخر التقييمات', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      if (provider.latestReviews.isEmpty)
                        Text('لا توجد تقييمات محفوظة بعد.', style: Theme.of(context).textTheme.bodyLarge)
                      else
                        ...provider.latestReviews.map(
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
                                      Text('${item.rating} ⭐', style: Theme.of(context).textTheme.titleMedium),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.comment, style: Theme.of(context).textTheme.bodyLarge),
                                  const SizedBox(height: 8),
                                  Text(_formatDate(item.createdAt), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ),
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
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
