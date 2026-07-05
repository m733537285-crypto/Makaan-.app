import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../shared/widgets/app_buttons.dart';

class OtpScreenArgs {
  const OtpScreenArgs({required this.phoneNumber, required this.debugCode});

  final String phoneNumber;
  final String debugCode;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final String? normalized = _normalizePhone(_phoneController.text);
    if (normalized == null) {
      AppDialogs.showErrorSnackBar(context, 'رقم الهاتف غير صالح.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final AppController controller = AppScope.of(context);
      final result = await controller.requestOtp(phoneNumber: normalized);
      if (!mounted) {
        return;
      }
      AppDialogs.showSuccessSnackBar(context, 'تم إنشاء رمز التحقق بنجاح.');
      await Navigator.of(context).pushNamed(
        AppRoutes.otp,
        arguments: OtpScreenArgs(
          phoneNumber: normalized,
          debugCode: result.challenge.code,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppDialogs.showErrorSnackBar(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthTemplate(
      title: 'تسجيل الدخول برقم الهاتف',
      subtitle: 'أدخل رقمك لإرسال رمز تحقق لمرة واحدة والدخول أو إنشاء الحساب تلقائياً.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'رقم الهاتف',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_android_rounded),
                prefixText: '+967  ',
                hintText: '7XXXXXXXX',
              ),
              validator: (String? value) {
                return _normalizePhone(value ?? '') == null
                    ? 'أدخل رقماً يمنياً صحيحاً يبدأ بـ 7'
                    : null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppScope.of(context).isRemoteBackendEnabled
                          ? 'سيتم إرسال رمز تحقق فعلي عبر خدمة المصادقة السحابية المفعّلة للمشروع.'
                          : 'وضع التشغيل المحلي مفعل حالياً. أضف إعدادات Supabase عند التشغيل لتفعيل OTP الحقيقي وقاعدة البيانات السحابية.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              expand: true,
              label: _isSubmitting ? 'جارٍ الإرسال...' : 'إرسال رمز التحقق',
              icon: Icons.sms_outlined,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({required this.args, super.key});

  final OtpScreenArgs args;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  bool _isSubmitting = false;
  bool _isResending = false;
  bool _countdownInitialized = false;
  int _secondsLeft = 60;
  late String _debugCode;

  @override
  void initState() {
    super.initState();
    _debugCode = widget.args.debugCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_countdownInitialized) {
      _countdownInitialized = true;
      _syncCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncCountdown() {
    _timer?.cancel();
    final DateTime resendAt = AppScope.of(context).activeOtpChallenge?.resendAvailableAt ?? DateTime.now();
    _secondsLeft = resendAt.difference(DateTime.now()).inSeconds.clamp(0, 60);
    if (_secondsLeft == 0) {
      setState(() {});
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      final int next = resendAt.difference(DateTime.now()).inSeconds.clamp(0, 60);
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft = next);
      if (next == 0) {
        timer.cancel();
      }
    });
    setState(() {});
  }

  Future<void> _verify() async {
    if (_isSubmitting || _otpController.text.trim().length < 4) {
      AppDialogs.showErrorSnackBar(context, 'أدخل رمز التحقق كاملاً.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final AppController controller = AppScope.of(context);
      await controller.verifyOtp(
        phoneNumber: widget.args.phoneNumber,
        code: _otpController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      AppDialogs.showSuccessSnackBar(context, 'تم التحقق بنجاح.');
      Navigator.of(context).pushNamedAndRemoveUntil(
        controller.resolveAuthenticatedHomeRoute(),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppDialogs.showErrorSnackBar(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isResending) {
      return;
    }
    setState(() => _isResending = true);
    try {
      final AppController controller = AppScope.of(context);
      final result = await controller.requestOtp(
        phoneNumber: widget.args.phoneNumber,
        forceResend: true,
      );
      if (!mounted) {
        return;
      }
      _otpController.clear();
      _debugCode = result.challenge.code;
      _syncCountdown();
      AppDialogs.showSuccessSnackBar(context, 'تم إرسال رمز جديد.');
      _focusNode.requestFocus();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppDialogs.showErrorSnackBar(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String maskedPhone = widget.args.phoneNumber.length >= 9
        ? widget.args.phoneNumber.replaceRange(4, 9, '*****')
        : widget.args.phoneNumber;
    return _AuthTemplate(
      title: 'رمز التحقق',
      subtitle: 'أدخل الرمز المرسل إلى $maskedPhone لإكمال تسجيل الدخول.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _otpController,
            builder: (BuildContext context, TextEditingValue value, Widget? child) {
              return _OtpPinField(
                controller: _otpController,
                focusNode: _focusNode,
                codeLength: 6,
              );
            },
          ),
          const SizedBox(height: 16),
          if (_debugCode.trim().isNotEmpty) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'رمز التجربة الحالي',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    _debugCode,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'يمكنك نسخه أو لصقه مباشرة عند تشغيل التطبيق محلياً بدون ربط سحابي.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'تم إرسال الرمز عبر خدمة OTP السحابية. أدخل الرمز الذي وصلك برسالة SMS.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            _secondsLeft > 0
                ? 'إعادة الإرسال خلال ${_secondsLeft.toString().padLeft(2, '0')} ثانية'
                : 'يمكنك الآن إعادة إرسال الرمز',
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            expand: true,
            label: _isSubmitting ? 'جارٍ التحقق...' : 'تحقق',
            onPressed: _isSubmitting ? null : _verify,
          ),
          const SizedBox(height: 12),
          AppSecondaryButton(
            expand: true,
            label: _isResending ? 'جارٍ إعادة الإرسال...' : 'إعادة إرسال الرمز',
            onPressed: (_secondsLeft == 0 && !_isResending) ? _resend : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            child: const Text('تعديل رقم الهاتف'),
          ),
        ],
      ),
    );
  }
}

class _OtpPinField extends StatelessWidget {
  const _OtpPinField({
    required this.controller,
    required this.focusNode,
    required this.codeLength,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int codeLength;

  @override
  Widget build(BuildContext context) {
    final String value = controller.text.trim();
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
            opacity: 0.02,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: codeLength,
              enableSuggestions: false,
              autocorrect: false,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(codeLength),
              ],
              onSubmitted: (_) {},
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
          IgnorePointer(
            child: Row(
              children: List<Widget>.generate(codeLength, (int index) {
                final bool isActive = value.length == index;
                final bool isFilled = value.length > index;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 62,
                    margin: EdgeInsetsDirectional.only(end: index == codeLength - 1 ? 0 : 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isFilled ? value[index] : '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTemplate extends StatelessWidget {
  const _AuthTemplate({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        child,
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

String? _normalizePhone(String value) {
  String digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('967')) {
    digits = digits.substring(3);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.length != 9 || !digits.startsWith('7')) {
    return null;
  }
  return '+967$digits';
}
