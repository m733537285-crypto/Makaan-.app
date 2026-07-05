import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../orders/data/order_repository.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/constants/yemen_locations.dart';
import '../../../../shared/models/order_models.dart';
import '../../../../shared/utils/date_time_formatter.dart';
import '../../../../shared/widgets/app_buttons.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedServiceType;
  String? _selectedGovernorate;
  String? _selectedDistrict;
  bool _isSubmitting = false;
  OrderCreationResult? _lastCreated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedGovernorate != null) {
      return;
    }
    final AppController controller = AppScope.of(context);
    final user = controller.currentUser;
    _phoneController.text = user?.phoneNumber ?? '';
    _selectedGovernorate = user?.governorate?.trim().isNotEmpty == true
        ? user!.governorate
        : YemenLocations.governorateNames.firstOrNull;
    final List<String> districts = YemenLocations.districtsFor(_selectedGovernorate ?? '');
    final String? preferredDistrict = user?.district?.trim().isNotEmpty == true ? user!.district : null;
    _selectedDistrict = districts.contains(preferredDistrict)
        ? preferredDistrict
        : districts.firstOrNull;
    final List<String> services = _serviceTypes(controller);
    _selectedServiceType = services.firstOrNull;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _neighborhoodController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final ThemeData theme = Theme.of(context);
    final List<String> serviceTypes = _serviceTypes(controller);
    final List<String> districtOptions = YemenLocations.districtsFor(_selectedGovernorate ?? '');

    if (!serviceTypes.contains(_selectedServiceType) && serviceTypes.isNotEmpty) {
      _selectedServiceType = serviceTypes.first;
    }
    if (!districtOptions.contains(_selectedDistrict) && districtOptions.isNotEmpty) {
      _selectedDistrict = districtOptions.first;
    }

    return AppScaffold(
      title: 'إنشاء طلب خدمة',
      currentNavIndex: 2,
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'سجل الطلبات',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.orders),
          icon: const Icon(Icons.receipt_long_rounded),
        ),
      ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('اطلب الخدمة الآن', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'املأ البيانات التالية ليتم توجيه الطلب فقط إلى مقدمي الخدمة المناسبين حسب نوع الخدمة والمنطقة والاشتراك النشط.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const <Widget>[
                          _RuleChip(label: 'رقم هاتف صحيح'),
                          _RuleChip(label: 'محافظة + مديرية + حي + معلم'),
                          _RuleChip(label: 'مطابقة نوع الخدمة والمنطقة'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutBack,
                child: _lastCreated == null
                    ? const SizedBox.shrink()
                    : _SuccessSummaryCard(
                        result: _lastCreated!,
                        onOpenOrders: () => Navigator.of(context).pushNamed(AppRoutes.orders),
                      ),
              ),
              if (_lastCreated != null) const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: AbsorbPointer(
                      absorbing: _isSubmitting,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              final bool wide = constraints.maxWidth >= 720;
                              return Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: <Widget>[
                                  SizedBox(
                                    width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedServiceType,
                                      decoration: const InputDecoration(
                                        labelText: 'نوع الخدمة',
                                        prefixIcon: Icon(Icons.handyman_outlined),
                                      ),
                                      items: serviceTypes
                                          .map(
                                            (String item) => DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) => setState(() => _selectedServiceType = value),
                                      validator: (String? value) =>
                                          value == null || value.trim().isEmpty ? 'اختر نوع الخدمة' : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'رقم الهاتف',
                                        hintText: 'مثال: 777123456',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                      validator: (String? value) {
                                        final String cleaned = (value ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
                                        if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleaned)) {
                                          return 'أدخل رقم هاتف صحيح';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedGovernorate,
                                      decoration: const InputDecoration(
                                        labelText: 'المحافظة',
                                        prefixIcon: Icon(Icons.map_outlined),
                                      ),
                                      items: YemenLocations.governorateNames
                                          .map(
                                            (String item) => DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedGovernorate = value;
                                          final List<String> nextDistricts = YemenLocations.districtsFor(value ?? '');
                                          _selectedDistrict = nextDistricts.firstOrNull;
                                        });
                                      },
                                      validator: (String? value) =>
                                          value == null || value.isEmpty ? 'اختر المحافظة' : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedDistrict,
                                      decoration: const InputDecoration(
                                        labelText: 'المديرية',
                                        prefixIcon: Icon(Icons.location_city_outlined),
                                      ),
                                      items: districtOptions
                                          .map(
                                            (String item) => DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) => setState(() => _selectedDistrict = value),
                                      validator: (String? value) =>
                                          value == null || value.isEmpty ? 'اختر المديرية' : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: _neighborhoodController,
                                      decoration: const InputDecoration(
                                        labelText: 'الحي',
                                        hintText: 'اسم الحي أو المنطقة',
                                        prefixIcon: Icon(Icons.pin_drop_outlined),
                                      ),
                                      validator: (String? value) =>
                                          (value ?? '').trim().isEmpty ? 'أدخل اسم الحي' : null,
                                    ),
                                  ),
                                  SizedBox(
                                    width: wide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth,
                                    child: TextFormField(
                                      controller: _landmarkController,
                                      decoration: const InputDecoration(
                                        labelText: 'أقرب معلم',
                                        hintText: 'مثال: بجوار المستشفى الجمهوري',
                                        prefixIcon: Icon(Icons.place_outlined),
                                      ),
                                      validator: (String? value) =>
                                          (value ?? '').trim().isEmpty ? 'أدخل أقرب معلم' : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'وصف الطلب',
                              hintText: 'اشرح المشكلة أو المطلوب بالتفصيل حتى يتمكن مقدم الخدمة من فهم الطلب بسرعة.',
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                padding: EdgeInsetsDirectional.only(top: 12),
                                child: Icon(Icons.description_outlined),
                              ),
                            ),
                            validator: (String? value) {
                              final String cleaned = (value ?? '').trim();
                              if (cleaned.length < 10) {
                                return 'الوصف يجب أن يكون أوضح قليلاً';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                            ),
                            child: Text(
                              'الموقع النصي النهائي: ${_selectedGovernorate ?? '-'} • ${_selectedDistrict ?? '-'} • ${_neighborhoodController.text.trim().isEmpty ? 'الحي' : _neighborhoodController.text.trim()} • ${_landmarkController.text.trim().isEmpty ? 'المعلم' : _landmarkController.text.trim()}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: AppPrimaryButton(
                                  label: _isSubmitting ? 'جاري إرسال الطلب...' : 'إرسال الطلب',
                                  icon: Icons.send_rounded,
                                  expand: true,
                                  onPressed: _isSubmitting ? null : () => _submit(controller),
                                ),
                              ),
                            ],
                          ),
                          if (_isSubmitting) ...<Widget>[
                            const SizedBox(height: 14),
                            const LinearProgressIndicator(minHeight: 6),
                          ],
                        ],
                      ),
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

  List<String> _serviceTypes(AppController controller) {
    final List<String> items = controller.availableServiceTypes;
    return items.isEmpty ? OrderRepository.defaultServiceTypes : items;
  }

  Future<void> _submit(AppController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final OrderCreationResult result = await controller.createServiceOrder(
        serviceType: _selectedServiceType ?? '',
        description: _descriptionController.text,
        location: OrderLocation(
          governorate: _selectedGovernorate ?? '',
          district: _selectedDistrict ?? '',
          neighborhood: _neighborhoodController.text.trim(),
          landmark: _landmarkController.text.trim(),
        ),
        phoneNumber: _phoneController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastCreated = result;
        _descriptionController.clear();
        _neighborhoodController.clear();
        _landmarkController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.matchedProvidersCount == 0
                ? 'تم إنشاء الطلب بنجاح، وسيبقى قيد الانتظار حتى يتوفر مقدم مناسب.'
                : 'تم إنشاء الطلب وإرساله إلى ${result.matchedProvidersCount} مقدم خدمة.',
          ),
        ),
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
}

class _SuccessSummaryCard extends StatelessWidget {
  const _SuccessSummaryCard({required this.result, required this.onOpenOrders});

  final OrderCreationResult result;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      key: ValueKey<String>(result.order.orderId),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.58),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.check_circle_rounded, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('تم إرسال الطلب بنجاح', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'الطلب رقم ${result.order.orderId} • ${DateTimeFormatter.shortDateTime(result.order.createdAt)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.matchedProvidersCount == 0
                        ? 'حالياً لا يوجد مقدم مطابق ظاهر داخل التطبيق، لكن الطلب محفوظ في سجل الطلبات.'
                        : 'تم توجيه الطلب إلى ${result.matchedProvidersCount} مقدم خدمة مناسب.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  AppSecondaryButton(
                    label: 'فتح سجل الطلبات',
                    icon: Icons.receipt_long_rounded,
                    onPressed: onOpenOrders,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.verified_outlined, size: 18),
      label: Text(label),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
