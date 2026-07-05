import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../shared/constants/yemen_locations.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_buttons.dart';

class EditProfileScreenArgs {
  const EditProfileScreenArgs({this.forceComplete = false});

  final bool forceComplete;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.args, super.key});

  final EditProfileScreenArgs args;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String? _governorate;
  String? _district;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppUser user = AppScope.of(context).currentUser!;
    if (_nameController.text.isEmpty) {
      _nameController.text = user.name ?? '';
      _governorate = user.governorate;
      _district = user.district;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final AppController controller = AppScope.of(context);
      await controller.updateProfile(
        name: _nameController.text,
        governorate: _governorate!,
        district: _district!,
      );
      if (!mounted) {
        return;
      }
      AppDialogs.showSuccessSnackBar(context, 'تم تحديث الملف الشخصي.');
      if (widget.args.forceComplete) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          controller.resolveAuthenticatedHomeRoute(),
          (Route<dynamic> route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
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
    final AppUser user = AppScope.of(context).currentUser!;
    final List<String> districtOptions = YemenLocations.districtsFor(_governorate ?? '');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.args.forceComplete,
        title: Text(widget.args.forceComplete ? 'استكمال الملف الشخصي' : 'تعديل الملف الشخصي'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                if (widget.args.forceComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'أكمل بياناتك الأساسية قبل الانتقال إلى الصفحة الرئيسية.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                              hintText: 'اختياري',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            readOnly: true,
                            initialValue: user.phoneNumber,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              prefixIcon: Icon(Icons.phone_android_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            readOnly: true,
                            initialValue: user.userType?.arabicLabel ?? 'غير محدد',
                            decoration: const InputDecoration(
                              labelText: 'نوع الحساب',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: YemenLocations.governorateNames.contains(_governorate) ? _governorate : null,
                            items: YemenLocations.governorateNames
                                .map(
                                  (String item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(growable: false),
                            decoration: const InputDecoration(
                              labelText: 'المحافظة',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            onChanged: (String? value) {
                              setState(() {
                                _governorate = value;
                                final List<String> nextDistricts = YemenLocations.districtsFor(value ?? '');
                                if (!nextDistricts.contains(_district)) {
                                  _district = null;
                                }
                              });
                            },
                            validator: (String? value) => value == null ? 'اختر المحافظة' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: districtOptions.contains(_district) ? _district : null,
                            items: districtOptions
                                .map(
                                  (String item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(growable: false),
                            decoration: const InputDecoration(
                              labelText: 'المديرية',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                            onChanged: districtOptions.isEmpty
                                ? null
                                : (String? value) => setState(() => _district = value),
                            validator: (String? value) => value == null ? 'اختر المديرية' : null,
                          ),
                          const SizedBox(height: 24),
                          AppPrimaryButton(
                            expand: true,
                            label: _isSaving ? 'جارٍ الحفظ...' : 'حفظ الملف',
                            onPressed: _isSaving ? null : _save,
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
      ),
    );
  }
}
