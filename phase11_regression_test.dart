import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makaan/core/constants/app_assets.dart';
import 'package:makaan/core/router/app_routes.dart';
import 'package:makaan/shared/models/app_settings.dart';

void main() {
  group('Phase 11 QA contracts', () {
    test('all registered route names stay unique', () {
      const List<String> routes = <String>[
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.otp,
        AppRoutes.accountType,
        AppRoutes.home,
        AppRoutes.categories,
        AppRoutes.search,
        AppRoutes.favorites,
        AppRoutes.providerProfile,
        AppRoutes.providerSetup,
        AppRoutes.createRequest,
        AppRoutes.orders,
        AppRoutes.notifications,
        AppRoutes.ads,
        AppRoutes.addAd,
        AppRoutes.adDetails,
        AppRoutes.profile,
        AppRoutes.editProfile,
        AppRoutes.subscription,
        AppRoutes.settings,
        AppRoutes.support,
        AppRoutes.help,
        AppRoutes.reports,
        AppRoutes.reviews,
        AppRoutes.dashboard,
        AppRoutes.adminPanel,
        AppRoutes.locationPicker,
        AppRoutes.gallery,
      ];

      expect(routes.toSet().length, routes.length);
      expect(routes.every((String route) => route.startsWith('/')), isTrue);
    });

    test('core SVG asset references exist', () {
      const List<String> assets = <String>[
        AppAssets.appIcon,
        AppAssets.logoPrimary,
        AppAssets.splashArtwork,
        AppAssets.homeIcon,
        AppAssets.categoriesIcon,
        AppAssets.ordersIcon,
        AppAssets.adsIcon,
        AppAssets.profileIcon,
        AppAssets.notificationsIcon,
        AppAssets.searchIcon,
        AppAssets.supportIcon,
        AppAssets.dashboardIcon,
      ];

      for (final String asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: 'Missing asset: $asset');
      }
    });

    test('settings deserialization tolerates invalid update dates', () {
      final AppSettings settings = AppSettings.fromJson(<String, dynamic>{
        'themeMode': 'dark',
        'language': 'ar',
        'pushNotificationsEnabled': true,
        'marketingNotificationsEnabled': false,
        'performanceDiagnosticsEnabled': true,
        'updatedAt': 'not-a-date',
      });

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.language, AppLanguage.arabic);
      expect(settings.updatedAt, isA<DateTime>());
    });
  });
}
