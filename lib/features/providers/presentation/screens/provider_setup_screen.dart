import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../shared/constants/yemen_locations.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/widgets/app_buttons.dart';

class ProviderSetupScreen extends StatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  State<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends State<ProviderSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mainServiceTypeController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _logoImageController = TextEditingController();
  final TextEditingController _customerCountController = TextEditingController(text: '0');
  final TextEditingController _neighborhoodsController = TextEditingController();

  String? _governorate;
  String? _district;
  final Set<String> _selectedDistricts = <String>{};
  final List<_ServiceDraft> _services = <_ServiceDraft>[];
  final List<_GalleryDraft> _gallery = <_GalleryDraft>[];
  bool _seeded = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final AppController controller = AppScope.of(context);
    final provider = controller.currentProviderDetails;
    final user = controller.currentUser!;
    _governorate = provider == null ? user.governorate : provider.profile.governorate;
    _district = provider == null ? user.district : provider.profile.district;

    _businessNameController.text = provider == null ? user.displayName : provider.profile.businessName;
    _phoneController.text = provider == null ? user.phoneNumber : provider.profile.phoneNumber;
    _descriptionController.text = provider == null ? '' : provider.profile.description;
    _mainServiceTypeController.text = provider == null ? '' : provider.profile.mainServiceType;
    _workingHoursController.text = provider == null ? 'السبت - الخميس • 8:00 ص إلى 10:00 م' : (provider.profile.workingHours ?? 'السبت - الخميس • 8:00 ص إلى 10:00 م');
    _whatsAppController.text = provider == null ? user.phoneNumber : (provider.profile.whatsAppNumber ?? user.phoneNumber);
    _coverImageController.text = provider == null ? '' : (provider.profile.coverImageUrl ?? '');
    _logoImageController.text = provider == null ? '' : (provider.profile.logoImageUrl ?? '');
    _customerCountController.text = '${provider == null ? 0 : provider.profile.customerCount}';

    final Set<String> districts = provider == null
        ? <String>{}
        : provider.serviceAreas.map((ProviderServiceArea item) => item.district).toSet();
    if (districts.isEmpty && _district != null) {
      districts.add(_district!);
    }
    _selectedDistricts.addAll(districts);

    final Set<String> neighborhoods = provider == null
        ? <String>{}
        : provider.serviceAreas
            .map((ProviderServiceArea item) => item.neighborhood?.trim() ?? '')
            .where((String item) => item.isNotEmpty)
            .toSet();
    _neighborhoodsController.text = neighborhoods.join('، ');

    if (provider != null && provider.services.isNotEmpty) {
      for (final ProviderService item in provider.services) {
        _services.add(_ServiceDraft.fromModel(item));
      }
    } else {
      _services.add(_ServiceDraft(title: '', description: '', price: '', isPrimary: true));
    }

    if (provider != null && provider.gallery.isNotEmpty) {
      for (final ProviderGalleryItem item in provider.gallery) {
        _gallery.add(_GalleryDraft.fromModel(item));
      }
    } else {
      _gallery.add(_GalleryDraft(caption: 'واجهة العمل', category: 'الخدمات', imageUrl: ''));
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _mainServiceTypeController.dispose();
    _workingHoursController.dispose();
    _whatsAppController.dispose();
    _coverImageController.dispose();
    _logoImageController.dispose();
    _customerCountController.dispose();
    _neighborhoodsController.dispose();
    for (final _ServiceDraft item in _services) {
      item.dispose();
    }
    for (final _GalleryDraft item in _gallery) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDistricts.isEmpty) {
      AppDialogs.showErrorSnackBar(context, 'اختر مديرية واحدة على الأقل ضمن مناطق العمل.');
      return;
    }

    final List<_ServiceDraft> validServices = _services.where((item) => item.title.text.trim().isNotEmpty).toList(growable: false);
    if (validServices.isEmpty) {
      AppDialogs.showErrorSnackBar(context, 'أضف خدمة واحدة على الأقل.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final AppController controller = AppScope.of(context);
      final List<ProviderService> services = <ProviderService>[];
      for (int index = 0; index < validServices.length; index++) {
        final _ServiceDraft item = validServices[index];
        services.add(
          ProviderService(
            serviceId: item.id,
            providerId: '',
            title: item.title.text.trim(),
            description: item.description.text.trim(),
            approximatePrice: double.tryParse(item.price.text.trim()),
            isPrimary: index == 0 || item.isPrimary,
          ),
        );
      }

      final List<ProviderGalleryItem> gallery = _gallery
          .where((item) => item.caption.text.trim().isNotEmpty || item.imageUrl.text.trim().isNotEmpty)
          .map(
            (_GalleryDraft item) => ProviderGalleryItem(
              imageId: item.id,
              providerId: '',
              caption: item.caption.text.trim().isEmpty ? 'صورة من المعرض' : item.caption.text.trim(),
              category: item.category.text.trim().isEmpty ? 'الخدمات' : item.category.text.trim(),
              imageUrl: item.imageUrl.text.trim().isEmpty ? null : item.imageUrl.text.trim(),
            ),
          )
          .toList(growable: false);

      final List<String> neighborhoods = _neighborhoodsController.text
          .split(RegExp(r'[،,\n]'))
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);

      final List<ProviderServiceArea> serviceAreas = <ProviderServiceArea>[];
      for (final String district in _selectedDistricts) {
        if (neighborhoods.isEmpty) {
          serviceAreas.add(
            ProviderServiceArea(
              areaId: '',
              providerId: '',
              governorate: _governorate!,
              district: district,
            ),
          );
          continue;
        }
        for (final String neighborhood in neighborhoods) {
          serviceAreas.add(
            ProviderServiceArea(
              areaId: '',
              providerId: '',
              governorate: _governorate!,
              district: district,
              neighborhood: neighborhood,
            ),
          );
        }
      }

      await controller.saveProviderBusinessProfile(
        businessName: _businessNameController.text,
        phoneNumber: _phoneController.text,
        description: _descriptionController.text,
        mainServiceType: _mainServiceTypeController.text,
        governorate: _governorate!,
        district: _district ?? _selectedDistricts.first,
        coverImageUrl: _coverImageController.text,
        logoImageUrl: _logoImageController.text,
        workingHours: _workingHoursController.text,
        whatsAppNumber: _whatsAppController.text,
        customerCount: int.tryParse(_customerCountController.text.trim()) ?? 0,
        services: services,
        gallery: gallery,
        serviceAreas: serviceAreas,
      );
      if (!mounted) {
        return;
      }
      AppDialogs.showSuccessSnackBar(context, 'تم حفظ ملف مقدم الخدمة بنجاح.');
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.providerProfile,
        (Route<dynamic> route) => false,
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
    final List<String> districtOptions = YemenLocations.districtsFor(_governorate ?? '');
    return Scaffold(
      appBar: AppBar(title: const Text('ملف مقدم الخدمة')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('أنشئ هويتك التجارية', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            'هذه الصفحة تبني ملف مقدم الخدمة الكامل: البيانات الأساسية، الخدمات، مناطق التغطية، المعرض، والاشتراك الجاهز للربط مع لوحة التحكم لاحقاً.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              _StatChip(icon: Icons.storefront_outlined, label: 'ملف تجاري متكامل'),
                              _StatChip(icon: Icons.workspace_premium_outlined, label: 'اشتراك شهري جاهز'),
                              _StatChip(icon: Icons.star_outline_rounded, label: 'تقييمات قابلة للحفظ'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'البيانات الأساسية',
                    subtitle: 'المعلومات التي ستظهر في صفحة النشاط العامة داخل التطبيق.',
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _businessNameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم التجاري',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (String? value) => (value?.trim().isEmpty ?? true) ? 'أدخل الاسم التجاري' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(20)],
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (String? value) => (value?.trim().isEmpty ?? true) ? 'أدخل رقم الهاتف' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _whatsAppController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم واتساب (اختياري)',
                            prefixIcon: Icon(Icons.chat_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mainServiceTypeController,
                          decoration: const InputDecoration(
                            labelText: 'نوع الخدمة الرئيسية',
                            hintText: 'مثال: مياه، تكسي، بنشري، كهربائي',
                            prefixIcon: Icon(Icons.handyman_outlined),
                          ),
                          validator: (String? value) => (value?.trim().isEmpty ?? true) ? 'أدخل نوع الخدمة الرئيسية' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'الوصف الكامل',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (String? value) => (value?.trim().length ?? 0) < 20 ? 'أضف وصفاً أوضح لا يقل عن 20 حرفاً' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: YemenLocations.governorateNames.contains(_governorate) ? _governorate : null,
                                items: YemenLocations.governorateNames
                                    .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                                    .toList(growable: false),
                                decoration: const InputDecoration(
                                  labelText: 'المحافظة',
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                ),
                                onChanged: (String? value) {
                                  setState(() {
                                    _governorate = value;
                                    final List<String> allowed = YemenLocations.districtsFor(value ?? '');
                                    _selectedDistricts.removeWhere((String item) => !allowed.contains(item));
                                    if (!allowed.contains(_district)) {
                                      _district = null;
                                    }
                                  });
                                },
                                validator: (String? value) => value == null ? 'اختر المحافظة' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: districtOptions.contains(_district) ? _district : null,
                                items: districtOptions
                                    .map((String item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                                    .toList(growable: false),
                                decoration: const InputDecoration(
                                  labelText: 'المديرية الأساسية',
                                  prefixIcon: Icon(Icons.map_outlined),
                                ),
                                onChanged: (String? value) {
                                  setState(() {
                                    _district = value;
                                    if (value != null) {
                                      _selectedDistricts.add(value);
                                    }
                                  });
                                },
                                validator: (String? value) => value == null ? 'اختر المديرية الأساسية' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: _workingHoursController,
                                decoration: const InputDecoration(
                                  labelText: 'أوقات العمل',
                                  prefixIcon: Icon(Icons.access_time_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 160,
                              child: TextFormField(
                                controller: _customerCountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'عدد العملاء',
                                  prefixIcon: Icon(Icons.groups_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _coverImageController,
                          decoration: const InputDecoration(
                            labelText: 'رابط صورة الغلاف (اختياري)',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _logoImageController,
                          decoration: const InputDecoration(
                            labelText: 'رابط الشعار (اختياري)',
                            prefixIcon: Icon(Icons.account_circle_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'الخدمات',
                    subtitle: 'أضف الخدمة الرئيسية والخدمات الفرعية مع وصف واضح وسعر تقريبي عند الحاجة.',
                    child: Column(
                      children: <Widget>[
                        for (int index = 0; index < _services.length; index++) ...<Widget>[
                          _ServiceEditor(
                            index: index,
                            draft: _services[index],
                            onRemove: _services.length == 1
                                ? null
                                : () {
                                    final _ServiceDraft item = _services.removeAt(index);
                                    item.dispose();
                                    setState(() {});
                                  },
                          ),
                          if (index != _services.length - 1) const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppSecondaryButton(
                            label: 'إضافة خدمة جديدة',
                            icon: Icons.add_rounded,
                            onPressed: () => setState(() {
                              _services.add(_ServiceDraft(title: '', description: '', price: ''));
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'مناطق العمل',
                    subtitle: 'حدد المديريات التي تخدمها والأحياء الاختيارية ليتم عرض نشاطك للعملاء القريبين فقط لاحقاً.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('المديريات المغطاة', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: districtOptions
                              .map(
                                (String item) => FilterChip(
                                  label: Text(item),
                                  selected: _selectedDistricts.contains(item),
                                  onSelected: (bool value) {
                                    setState(() {
                                      if (value) {
                                        _selectedDistricts.add(item);
                                      } else {
                                        _selectedDistricts.remove(item);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _neighborhoodsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'الأحياء (اختياري)',
                            hintText: 'افصل بين الأحياء بفاصلة مثل: التحرير، الزبيري، حدة',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.pin_drop_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'معرض الصور',
                    subtitle: 'اربط صور الخدمات أو الأعمال السابقة أو السيارات والمعدات بروابط صور جاهزة.',
                    child: Column(
                      children: <Widget>[
                        for (int index = 0; index < _gallery.length; index++) ...<Widget>[
                          _GalleryEditor(
                            index: index,
                            draft: _gallery[index],
                            onRemove: _gallery.length == 1
                                ? null
                                : () {
                                    final _GalleryDraft item = _gallery.removeAt(index);
                                    item.dispose();
                                    setState(() {});
                                  },
                          ),
                          if (index != _gallery.length - 1) const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppSecondaryButton(
                            label: 'إضافة صورة',
                            icon: Icons.add_photo_alternate_outlined,
                            onPressed: () => setState(() {
                              _gallery.add(_GalleryDraft(caption: '', category: '', imageUrl: ''));
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    expand: true,
                    label: _isSaving ? 'جارٍ حفظ الملف...' : 'حفظ ملف مقدم الخدمة',
                    icon: Icons.save_outlined,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ServiceEditor extends StatelessWidget {
  const _ServiceEditor({required this.index, required this.draft, this.onRemove});

  final int index;
  final _ServiceDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('الخدمة ${index + 1}', style: Theme.of(context).textTheme.titleMedium)),
              if (onRemove != null)
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.title,
            decoration: const InputDecoration(labelText: 'اسم الخدمة'),
            validator: (String? value) {
              if ((value?.trim().isEmpty ?? true) && index == 0) {
                return 'أدخل اسم الخدمة الأساسية';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.description,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'وصف الخدمة'),
            validator: (String? value) {
              if (draft.title.text.trim().isNotEmpty && (value?.trim().isEmpty ?? true)) {
                return 'أضف وصف الخدمة';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: draft.price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'سعر تقريبي (اختياري)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  index == 0 ? 'أول خدمة تُعتمد كخدمة رئيسية تلقائياً.' : 'يمكن إضافة خدمات فرعية متعددة.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryEditor extends StatelessWidget {
  const _GalleryEditor({required this.index, required this.draft, this.onRemove});

  final int index;
  final _GalleryDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('الصورة ${index + 1}', style: Theme.of(context).textTheme.titleMedium)),
              if (onRemove != null)
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.caption,
            decoration: const InputDecoration(labelText: 'عنوان الصورة / التعليق'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.category,
            decoration: const InputDecoration(labelText: 'التصنيف', hintText: 'الخدمات / الأعمال السابقة / المعدات'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.imageUrl,
            decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ServiceDraft {
  _ServiceDraft({required String title, required String description, required String price, this.id = '', this.isPrimary = false})
      : title = TextEditingController(text: title),
        description = TextEditingController(text: description),
        price = TextEditingController(text: price);

  final String id;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController price;
  bool isPrimary;

  factory _ServiceDraft.fromModel(ProviderService model) {
    return _ServiceDraft(
      id: model.serviceId,
      title: model.title,
      description: model.description,
      price: model.approximatePrice?.toString() ?? '',
      isPrimary: model.isPrimary,
    );
  }

  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
  }
}

class _GalleryDraft {
  _GalleryDraft({required String caption, required String category, required String imageUrl, this.id = ''})
      : caption = TextEditingController(text: caption),
        category = TextEditingController(text: category),
        imageUrl = TextEditingController(text: imageUrl);

  final String id;
  final TextEditingController caption;
  final TextEditingController category;
  final TextEditingController imageUrl;

  factory _GalleryDraft.fromModel(ProviderGalleryItem model) {
    return _GalleryDraft(
      id: model.imageId,
      caption: model.caption,
      category: model.category,
      imageUrl: model.imageUrl ?? '',
    );
  }

  void dispose() {
    caption.dispose();
    category.dispose();
    imageUrl.dispose();
  }
}
