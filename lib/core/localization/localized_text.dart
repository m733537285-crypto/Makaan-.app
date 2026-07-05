import 'package:flutter/material.dart';

class LocalizedText {
  const LocalizedText(this.ar, this.en);

  final String ar;
  final String en;

  String resolve(BuildContext context) {
    final String code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? en : ar;
  }
}
