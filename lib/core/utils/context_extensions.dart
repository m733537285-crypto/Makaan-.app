import 'package:flutter/material.dart';

import '../app_controller.dart';

extension BuildContextX on BuildContext {
  AppController get appController => AppScope.of(this);
  bool get isArabic => Localizations.localeOf(this).languageCode != 'en';
}
