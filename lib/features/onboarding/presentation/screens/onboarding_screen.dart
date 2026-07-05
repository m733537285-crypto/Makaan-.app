import 'package:flutter/material.dart';

import 'package:makaan/core/app_controller.dart';
import 'package:makaan/core/router/app_routes.dart';
import 'package:makaan/core/widgets/app_logo.dart';
import 'package:makaan/shared/widgets/app_buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_OnboardingItem> _items = <_OnboardingItem>[
    _OnboardingItem(
      Icons.travel_explore_rounded,
      'ابحث عن الخدمة المناسبة بسرعة',
      'Discover the right service quickly',
    ),
    _OnboardingItem(
      Icons.dashboard_customize_outlined,
      'تنقّل بين الطلبات والإعلانات بسهولة',
      'Manage requests and ads with ease',
    ),
    _OnboardingItem(
      Icons.shield_outlined,
      'واجهات جاهزة للتوسّع مع هوية بصرية موحدة',
      'Scalable UI foundation with a cohesive brand',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    AppScope.of(context).completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          TextButton(onPressed: _finish, child: const Text('تخطي')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const AppBrandLockup(compact: true),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (int value) => setState(() => _page = value),
                  itemBuilder: (BuildContext context, int index) {
                    final _OnboardingItem item = _items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 46,
                              child: Icon(item.icon, size: 44),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              item.ar,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.en,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _items.length,
                  (int index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _page == index ? 30 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _page == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                expand: true,
                label: _page == _items.length - 1 ? 'ابدأ الآن' : 'متابعة',
                onPressed: () {
                  if (_page == _items.length - 1) {
                    _finish();
                    return;
                  }
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem(this.icon, this.ar, this.en);

  final IconData icon;
  final String ar;
  final String en;
}
