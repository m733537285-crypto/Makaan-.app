class DateTimeFormatter {
  const DateTimeFormatter._();

  static String shortDateTime(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year} • ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  static String relativeArabic(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'الآن';
    }
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    }
    if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    }
    return 'منذ ${difference.inDays} يوم';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
