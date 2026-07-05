class SecurityViolation implements Exception {
  const SecurityViolation(this.message);

  final String message;

  @override
  String toString() => message;
}

class SecurityGuardService {
  SecurityGuardService._();

  static final SecurityGuardService instance = SecurityGuardService._();

  final Map<String, List<DateTime>> _attempts = <String, List<DateTime>>{};

  void checkRateLimit({
    required String key,
    required int maxAttempts,
    required Duration window,
    String message = 'تم تنفيذ هذه العملية عدة مرات. حاول لاحقاً.',
  }) {
    final DateTime now = DateTime.now();
    final DateTime threshold = now.subtract(window);
    final List<DateTime> attempts = _attempts.putIfAbsent(key, () => <DateTime>[])
      ..removeWhere((DateTime item) => item.isBefore(threshold));
    if (attempts.length >= maxAttempts) {
      throw SecurityViolation(message);
    }
    attempts.add(now);
  }

  void validatePhoneNumber(String phoneNumber) {
    final String cleaned = phoneNumber.trim().replaceAll(RegExp(r'[\s-]'), '');
    final bool valid = RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned);
    if (!valid) {
      throw const SecurityViolation('رقم الهاتف غير صالح. استخدم أرقاماً فقط مع رمز الدولة عند الحاجة.');
    }
  }

  void validateSafeText(String value, {required String fieldName, int minLength = 0, int maxLength = 500}) {
    final String cleaned = value.trim();
    if (cleaned.length < minLength) {
      throw SecurityViolation('$fieldName قصير جداً.');
    }
    if (cleaned.length > maxLength) {
      throw SecurityViolation('$fieldName أطول من الحد المسموح.');
    }
    if (RegExp(r'<\s*script|javascript:|data:text/html', caseSensitive: false).hasMatch(cleaned)) {
      throw SecurityViolation('$fieldName يحتوي على مدخلات غير آمنة.');
    }
  }

  void validateImageReference(String value) {
    final String cleaned = value.trim();
    if (cleaned.isEmpty) {
      return;
    }
    final bool isAsset = cleaned.startsWith('assets/');
    final bool isHttp = Uri.tryParse(cleaned)?.hasAbsolutePath ?? false;
    final bool isAllowed = isAsset || (cleaned.startsWith('http://') || cleaned.startsWith('https://')) && isHttp;
    if (!isAllowed) {
      throw const SecurityViolation('رابط الصورة غير صالح.');
    }
    if (RegExp(r'\.(exe|apk|bat|cmd|sh|php)$', caseSensitive: false).hasMatch(cleaned)) {
      throw const SecurityViolation('نوع الملف المرفوع غير مسموح.');
    }
  }

  void validatePrice(double value, {required String fieldName}) {
    if (value.isNaN || value.isInfinite || value < 0) {
      throw SecurityViolation('$fieldName غير صالح.');
    }
    if (value > 1000000000) {
      throw SecurityViolation('$fieldName أعلى من الحد المسموح.');
    }
  }
}
