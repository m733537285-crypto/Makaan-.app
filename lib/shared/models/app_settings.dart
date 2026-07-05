import 'package:flutter/material.dart';

enum AppLanguage { arabic, english }

extension AppLanguageX on AppLanguage {
  String get value {
    switch (this) {
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
        return 'en';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.english:
        return 'English';
    }
  }

  Locale get locale => Locale(value);
}

AppLanguage appLanguageFromValue(String? value) {
  switch (value) {
    case 'en':
      return AppLanguage.english;
    case 'ar':
    default:
      return AppLanguage.arabic;
  }
}

ThemeMode themeModeFromValue(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

extension ThemeModeX on ThemeMode {
  String get storageValue {
    switch (this) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  String get arabicLabel {
    switch (this) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'تلقائي';
    }
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.pushNotificationsEnabled,
    required this.marketingNotificationsEnabled,
    required this.performanceDiagnosticsEnabled,
    required this.updatedAt,
  });

  final ThemeMode themeMode;
  final AppLanguage language;
  final bool pushNotificationsEnabled;
  final bool marketingNotificationsEnabled;
  final bool performanceDiagnosticsEnabled;
  final DateTime updatedAt;

  Locale get locale => language.locale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? pushNotificationsEnabled,
    bool? marketingNotificationsEnabled,
    bool? performanceDiagnosticsEnabled,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      marketingNotificationsEnabled: marketingNotificationsEnabled ?? this.marketingNotificationsEnabled,
      performanceDiagnosticsEnabled: performanceDiagnosticsEnabled ?? this.performanceDiagnosticsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeMode': themeMode.storageValue,
      'language': language.value,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'marketingNotificationsEnabled': marketingNotificationsEnabled,
      'performanceDiagnosticsEnabled': performanceDiagnosticsEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final DateTime parsedUpdatedAt = DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? DateTime.now();
    return AppSettings(
      themeMode: themeModeFromValue(json['themeMode'] as String?),
      language: appLanguageFromValue(json['language'] as String?),
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      marketingNotificationsEnabled: json['marketingNotificationsEnabled'] as bool? ?? false,
      performanceDiagnosticsEnabled: json['performanceDiagnosticsEnabled'] as bool? ?? true,
      updatedAt: parsedUpdatedAt,
    );
  }

  static AppSettings defaults() {
    return AppSettings(
      themeMode: ThemeMode.system,
      language: AppLanguage.arabic,
      pushNotificationsEnabled: true,
      marketingNotificationsEnabled: false,
      performanceDiagnosticsEnabled: true,
      updatedAt: DateTime.now(),
    );
  }
}
