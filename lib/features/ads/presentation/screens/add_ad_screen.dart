import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/ad_models.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../widgets/ad_ui.dart';
import 'ad_details_screen.dart';

class AddAdScreen extends StatefulWidget {
  const AddAdScreen({super.key});

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceBeforeController = TextEditingController();
  final TextEditingController _priceAfterController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  AdCategory _selectedCategory = AdCategory.services;
  DealType _selectedDealType = DealType.standard;
  DateTime? _expiresAt;
  bool _isSubmitting = false;
  final List<String> _images = <String>[];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceBeforeController.dispose();
    _priceAfterController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    return AppScaffold(
      title: 'إضافة إعلان',
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
                      Text('إنشاء إعلان جديد', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل بيانات الإعلان الأساسية: صور، أسعار، وصف، تصنيف، ورقم التواصل. الإعلانات المميزة والمدفوعة ستُفعل لاحقاً.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const <Widget>[
                          _GuideChip(icon: Icons.image_outlined, text: 'صور فقط في هذه المرحلة'),
                          _GuideChip(icon: Icons.shield_outlined, text: 'منع التكرار لنفس المستخدم'),
                          _GuideChip(icon: Icons.timer_outlined, text: 'انتهاء العرض اختياري'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final bool wide = constraints.maxWidth > 700;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: <Widget>[
                                SizedBox(
                                  width: wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: 'عنوان الإعلان',
                                      hintText: 'مثال: سيارة للبيع أو خصم على خدمة تنظيف',
                                    ),
                                    validator: (String? value) {
                                      if ((value ?? '').trim().length < 4) {
                                        return 'اكتب عنواناً أوضح';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'رقم التواصل',
                                      hintText: 'مثال: 777123456',
                                    ),
                                    validator: (String? value) {
                                      final String digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                      if (digits.length < 9 || digits.length > 15) {
                                        return 'رقم الهاتف غير صحيح';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                  child: DropdownButtonFormField<AdCategory>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(labelText: 'التصنيف'),
                                    items: controller.availableAdCategories
                                        .map(
                                          (AdCategory category) => DropdownMenuItem<AdCategory>(
                                            value: category,
                                            child: Text(category.arabicLabel),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (AdCategory? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() => _selectedCategory = value);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                  child: DropdownButtonFormField<DealType>(
                                    value: _selectedDealType,
                                    decoration: const InputDecoration(labelText: 'نوع العرض'),
                                    items: controller.availableDealTypes
                                        .map(
                                          (DealType type) => DropdownMenuItem<DealType>(
                                            value: type,
                                            child: Text(type.arabicLabel),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (DealType? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() => _selectedDealType = value);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _priceBeforeController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'السعر قبل الخصم',
                                      hintText: 'اختياري إذا لم يوجد خصم',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                  child: TextFormField(
                                    controller: _priceAfterController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'السعر الحالي',
                                      hintText: 'مثال: 15000',
                                    ),
                                    validator: (String? value) {
                                      final double? parsed = double.tryParse((value ?? '').trim());
                                      if (parsed == null || parsed <= 0) {
                                        return 'أدخل سعراً صحيحاً';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'الموقع النصي',
                            hintText: 'مثال: صنعاء - حدة - شارع إيران',
                          ),
                          validator: (String? value) {
                            if ((value ?? '').trim().length < 3) {
                              return 'أدخل موقعاً واضحاً';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'وصف الإعلان',
                            hintText: 'اكتب وصفاً كاملاً يشمل الحالة والمزايا ومدة العرض إن وجدت.',
                            alignLabelWithHint: true,
                          ),
                          validator: (String? value) {
                            if ((value ?? '').trim().length < 12) {
                              return 'اكتب وصفاً أوضح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('صور الإعلان', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'أضف روابط صور مباشرة فقط في هذه المرحلة. يمكن إضافة أكثر من صورة للإعلان.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: _imageController,
                                decoration: const InputDecoration(
                                  labelText: 'رابط الصورة',
                                  hintText: 'https://example.com/image.jpg',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AppSecondaryButton(
                              label: 'إضافة',
                              icon: Icons.add_photo_alternate_outlined,
                              onPressed: _addImage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_images.isEmpty)
                          const EmptyStateCard(
                            title: 'لم تتم إضافة صور بعد',
                            subtitle: 'أدخل رابط صورة واضغط إضافة.',
                            icon: Icons.image_not_supported_outlined,
                          )
                        else
                          Column(
                            children: _images
                                .map(
                                  (String image) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: <Widget>[
                                            SizedBox(
                                              width: 90,
                                              child: AdImageView(imageUrl: image, height: 72, borderRadius: 16),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                image,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'حذف',
                                              onPressed: () => setState(() => _images.remove(image)),
                                              icon: const Icon(Icons.delete_outline_rounded),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 20),
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('مدة الإعلان', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  _expiresAt == null
                                      ? 'لم يتم تحديد وقت انتهاء. يمكنك تركه فارغاً أو اختيار تاريخ انتهاء اختياري.'
                                      : 'ينتهي العرض في: ${_formatDate(_expiresAt!)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: <Widget>[
                                    AppSecondaryButton(
                                      label: 'اختيار تاريخ انتهاء',
                                      icon: Icons.event_outlined,
                                      onPressed: _pickExpiryDate,
                                    ),
                                    if (_expiresAt != null)
                                      AppSecondaryButton(
                                        label: 'مسح التاريخ',
                                        icon: Icons.close_rounded,
                                        onPressed: () => setState(() => _expiresAt = null),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.45),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(Icons.workspace_premium_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text('الإعلانات المميزة المدفوعة', style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 6),
                                      Text(
                                        'الدعم البرمجي موجود من ناحية الشارات والعروض، لكن الدفع والاشتراكات الإعلانية ما زالت خارج نطاق هذه المرحلة.',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppPrimaryButton(
                          label: _isSubmitting ? 'جاري نشر الإعلان...' : 'نشر الإعلان',
                          icon: Icons.publish_outlined,
                          expand: true,
                          onPressed: _isSubmitting ? null : () => _submit(controller),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addImage() {
    final String image = _imageController.text.trim();
    if (image.isEmpty) {
      return;
    }
    setState(() {
      _images.add(image);
      _imageController.clear();
    });
  }

  Future<void> _pickExpiryDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _expiresAt ?? now.add(const Duration(days: 1)),
      locale: const Locale('ar'),
    );
    if (picked == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    );
    if (!mounted) {
      return;
    }
    if (time == null) {
      setState(() {
        _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
      });
      return;
    }
    setState(() {
      _expiresAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _submit(AppController controller) async {
    _addImage();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صورة واحدة على الأقل.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final double priceBefore = double.tryParse(_priceBeforeController.text.trim()) ?? 0;
      final double priceAfter = double.tryParse(_priceAfterController.text.trim()) ?? 0;
      final ad = await controller.createAdListing(
        title: _titleController.text,
        description: _descriptionController.text,
        priceBefore: priceBefore,
        priceAfter: priceAfter,
        images: _images,
        category: _selectedCategory,
        phoneNumber: _phoneController.text,
        locationText: _locationController.text,
        dealType: _selectedDealType,
        expiresAt: _expiresAt,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الإعلان بنجاح.')),
      );
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.adDetails,
        arguments: AdDetailsScreenArgs(adId: ad.adId),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year} • ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _GuideChip extends StatelessWidget {
  const _GuideChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
