import 'dart:async';

import 'package:flutter/material.dart';

import 'package:makaan/core/app_controller.dart';
import 'package:makaan/core/router/app_routes.dart';
import 'package:makaan/core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) {
      return;
    }
    final AppController controller = AppScope.of(context);
    if (!controller.onboardingCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      controller.isAuthenticated
          ? controller.resolveAuthenticatedHomeRoute()
          : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              scheme.primary,
              scheme.primary.withValues(alpha: 0.86),
              scheme.tertiary,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const AppRoundLogo(size: 104),
                ),
                const SizedBox(height: 24),
                Text(
                  'مكان',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'كل خدماتك في مكان واحد',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
