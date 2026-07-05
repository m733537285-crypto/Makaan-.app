class BackendException implements Exception {
  const BackendException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  String get userMessage {
    if (statusCode == 401 || statusCode == 403) {
      return 'لا تملك صلاحية تنفيذ هذه العملية.';
    }
    if (statusCode == 404) {
      return 'تعذر العثور على البيانات المطلوبة.';
    }
    if (statusCode == 408 || statusCode == 429) {
      return 'تم تنفيذ الطلبات بسرعة عالية. انتظر قليلاً ثم حاول مرة أخرى.';
    }
    if (statusCode != null && statusCode! >= 500) {
      return 'حدث خطأ في الخادم. حاول مرة أخرى.';
    }
    return message;
  }

  @override
  String toString() => userMessage;
}

class BackendTimeoutException extends BackendException {
  const BackendTimeoutException()
      : super('انتهت مهلة الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.');
}

class BackendNetworkException extends BackendException {
  const BackendNetworkException()
      : super('تعذر الاتصال بالإنترنت أو بالخادم. تحقق من الشبكة وحاول مرة أخرى.');
}
