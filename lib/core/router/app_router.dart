import 'package:flutter/material.dart';

import 'package:makaan/core/app_controller.dart';
import 'package:makaan/core/router/app_routes.dart';
import 'package:makaan/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:makaan/features/ads/presentation/screens/ad_details_screen.dart';
import 'package:makaan/features/ads/presentation/screens/add_ad_screen.dart';
import 'package:makaan/features/ads/presentation/screens/ads_screen.dart';
import 'package:makaan/features/ads/presentation/screens/gallery_screen.dart';
import 'package:makaan/features/auth/presentation/screens/account_type_screen.dart';
import 'package:makaan/features/auth/presentation/screens/login_screen.dart';
import 'package:makaan/features/categories/presentation/screens/categories_screen.dart';
import 'package:makaan/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:makaan/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:makaan/features/home/presentation/screens/home_screen.dart';
import 'package:makaan/features/home/presentation/screens/not_found_screen.dart';
import 'package:makaan/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:makaan/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:makaan/features/orders/presentation/screens/orders_screen.dart';
import 'package:makaan/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:makaan/features/profile/presentation/screens/profile_screen.dart';
import 'package:makaan/features/providers/presentation/screens/provider_profile_screen.dart';
import 'package:makaan/features/providers/presentation/screens/provider_setup_screen.dart';
import 'package:makaan/features/requests/presentation/screens/create_request_screen.dart';
import 'package:makaan/features/requests/presentation/screens/location_picker_screen.dart';
import 'package:makaan/features/reports/presentation/screens/reports_screen.dart';
import 'package:makaan/features/reviews/presentation/screens/reviews_screen.dart';
import 'package:makaan/features/search/presentation/screens/search_screen.dart';
import 'package:makaan/features/settings/presentation/screens/settings_screen.dart';
import 'package:makaan/features/splash/presentation/screens/splash_screen.dart';
import 'package:makaan/features/subscriptions/presentation/screens/subscription_screen.dart';
import 'package:makaan/features/support/presentation/screens/help_screen.dart';
import 'package:makaan/features/support/presentation/screens/support_screen.dart';

class AppRouter {
  const AppRouter(this.controller);

  final AppController controller;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = _guardRoute(settings.name ?? AppRoutes.splash);

    switch (routeName) {
      case AppRoutes.splash:
        return _build(const SplashScreen(), settings);
      case AppRoutes.onboarding:
        return _build(const OnboardingScreen(), settings);
      case AppRoutes.login:
      case AppRoutes.signup:
        return _build(const LoginScreen(), settings);
      case AppRoutes.otp:
        final OtpScreenArgs args = settings.arguments is OtpScreenArgs
            ? settings.arguments as OtpScreenArgs
            : const OtpScreenArgs(phoneNumber: '', debugCode: '');
        return _build(OtpScreen(args: args), settings);
      case AppRoutes.accountType:
        return _build(const AccountTypeScreen(), settings);
      case AppRoutes.home:
        return _build(const HomeScreen(), settings);
      case AppRoutes.categories:
        return _build(const CategoriesScreen(), settings);
      case AppRoutes.search:
        final SearchScreenArgs args = settings.arguments is SearchScreenArgs
            ? settings.arguments as SearchScreenArgs
            : const SearchScreenArgs();
        return _build(SearchScreen(args: args), settings);
      case AppRoutes.favorites:
        return _build(const FavoritesScreen(), settings);
      case AppRoutes.providerProfile:
        final ProviderProfileScreenArgs? args = settings.arguments is ProviderProfileScreenArgs
            ? settings.arguments as ProviderProfileScreenArgs
            : null;
        return _build(ProviderProfileScreen(args: args), settings);
      case AppRoutes.providerSetup:
        return _build(const ProviderSetupScreen(), settings);
      case AppRoutes.createRequest:
        return _build(const CreateRequestScreen(), settings);
      case AppRoutes.orders:
        return _build(const OrdersScreen(), settings);
      case AppRoutes.notifications:
        return _build(const NotificationsScreen(), settings);
      case AppRoutes.ads:
        return _build(const AdsScreen(), settings);
      case AppRoutes.addAd:
        return _build(const AddAdScreen(), settings);
      case AppRoutes.adDetails:
        final AdDetailsScreenArgs? args = settings.arguments is AdDetailsScreenArgs
            ? settings.arguments as AdDetailsScreenArgs
            : null;
        return _build(AdDetailsScreen(args: args), settings);
      case AppRoutes.profile:
        return _build(const ProfileScreen(), settings);
      case AppRoutes.editProfile:
        final EditProfileScreenArgs args = settings.arguments is EditProfileScreenArgs
            ? settings.arguments as EditProfileScreenArgs
            : const EditProfileScreenArgs();
        return _build(EditProfileScreen(args: args), settings);
      case AppRoutes.subscription:
        return _build(const SubscriptionScreen(), settings);
      case AppRoutes.settings:
        return _build(const SettingsScreen(), settings);
      case AppRoutes.support:
        return _build(const SupportScreen(), settings);
      case AppRoutes.help:
        return _build(const HelpScreen(), settings);
      case AppRoutes.reports:
        return _build(const ReportsScreen(), settings);
      case AppRoutes.reviews:
        return _build(const ReviewsScreen(), settings);
      case AppRoutes.dashboard:
        return _build(const DashboardScreen(), settings);
      case AppRoutes.adminPanel:
        return _build(const AdminPanelScreen(), settings);
      case AppRoutes.locationPicker:
        return _build(const LocationPickerScreen(), settings);
      case AppRoutes.gallery:
        return _build(const GalleryScreen(), settings);
      default:
        return _build(const NotFoundScreen(), settings);
    }
  }

  String _guardRoute(String routeName) {
    const Set<String> publicRoutes = <String>{
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.otp,
    };

    if (!controller.onboardingCompleted &&
        routeName != AppRoutes.splash &&
        routeName != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    if (!controller.isAuthenticated) {
      return publicRoutes.contains(routeName) ? routeName : AppRoutes.login;
    }

    if (controller.needsUserTypeSelection && routeName != AppRoutes.accountType) {
      return AppRoutes.accountType;
    }

    if (controller.needsProfileCompletion && routeName != AppRoutes.editProfile) {
      return AppRoutes.editProfile;
    }

    if (controller.needsProviderSetup && routeName != AppRoutes.providerSetup) {
      return AppRoutes.providerSetup;
    }

    if (routeName == AppRoutes.adminPanel && !controller.canAccessAdminPanel) {
      return controller.resolveAuthenticatedHomeRoute();
    }

    if (publicRoutes.contains(routeName) || routeName == AppRoutes.accountType) {
      return controller.resolveAuthenticatedHomeRoute();
    }

    return routeName;
  }

  Route<dynamic> _build(Widget child, RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) => child,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
