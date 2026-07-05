import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_controller.dart';
import '../constants/app_assets.dart';
import '../localization/localized_text.dart';
import '../router/app_routes.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.currentNavIndex,
    this.showDrawer = true,
    this.floatingActionButton,
    this.appBarActions,
    super.key,
  });

  final String title;
  final Widget body;
  final int? currentNavIndex;
  final bool showDrawer;
  final Widget? floatingActionButton;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: appBarActions),
      drawer: showDrawer ? const _MakaanDrawer() : null,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: currentNavIndex == null
          ? null
          : NavigationBar(
              selectedIndex: currentNavIndex!,
              onDestinationSelected: (int index) {
                final String route = _NavItem.items[index].route;
                final RouteSettings? currentSettings = ModalRoute.of(context)?.settings;
                final String? currentRoute = currentSettings?.name;
                if (currentRoute == route) {
                  return;
                }
                Navigator.of(context).pushReplacementNamed(route);
              },
              destinations: _NavItem.items
                  .map(
                    (_NavItem item) => NavigationDestination(
                      icon: _NavIcon(assetPath: item.assetPath),
                      selectedIcon: _NavIcon(
                        assetPath: item.assetPath,
                        selected: true,
                      ),
                      label: item.label.resolve(context),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _MakaanDrawer extends StatelessWidget {
  const _MakaanDrawer();

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final bool isProvider = controller.currentUser?.isProvider ?? false;
    final List<_DrawerItem> items = <_DrawerItem>[
      const _DrawerItem('الرئيسية', 'Home', AppRoutes.home, Icons.home_rounded),
      const _DrawerItem(
        'التصنيفات',
        'Categories',
        AppRoutes.categories,
        Icons.grid_view_rounded,
      ),
      const _DrawerItem(
        'البحث',
        'Search',
        AppRoutes.search,
        Icons.search_rounded,
      ),
      const _DrawerItem(
        'الطلبات',
        'Orders',
        AppRoutes.orders,
        Icons.receipt_long_rounded,
      ),
      const _DrawerItem(
        'الإشعارات',
        'Notifications',
        AppRoutes.notifications,
        Icons.notifications_none_rounded,
      ),
      const _DrawerItem(
        'الإعلانات',
        'Ads',
        AppRoutes.ads,
        Icons.campaign_outlined,
      ),
      const _DrawerItem(
        'المفضلة',
        'Favorites',
        AppRoutes.favorites,
        Icons.favorite_border_rounded,
      ),
      if (isProvider)
        const _DrawerItem(
          'الملف التجاري',
          'Business Profile',
          AppRoutes.providerProfile,
          Icons.storefront_outlined,
        ),
      const _DrawerItem(
        'إضافة إعلان',
        'Add ad',
        AppRoutes.addAd,
        Icons.add_box_outlined,
      ),
      const _DrawerItem(
        'الملف الشخصي',
        'Profile',
        AppRoutes.profile,
        Icons.person_outline_rounded,
      ),
      const _DrawerItem(
        'الاشتراك',
        'Subscription',
        AppRoutes.subscription,
        Icons.workspace_premium_outlined,
      ),
      const _DrawerItem(
        'الإعدادات',
        'Settings',
        AppRoutes.settings,
        Icons.settings_outlined,
      ),
      const _DrawerItem(
        'الدعم',
        'Support',
        AppRoutes.support,
        Icons.headset_mic_outlined,
      ),
      const _DrawerItem(
        'المساعدة',
        'Help',
        AppRoutes.help,
        Icons.help_outline_rounded,
      ),
      const _DrawerItem(
        'البلاغات',
        'Reports',
        AppRoutes.reports,
        Icons.flag_outlined,
      ),
      const _DrawerItem(
        'التقييمات',
        'Reviews',
        AppRoutes.reviews,
        Icons.reviews_outlined,
      ),
      if (isProvider)
        const _DrawerItem(
          'لوحة مقدم الخدمة',
          'Provider Dashboard',
          AppRoutes.dashboard,
          Icons.space_dashboard_outlined,
        ),
      if (controller.canAccessAdminPanel)
        const _DrawerItem(
          'لوحة الإدارة',
          'Admin Panel',
          AppRoutes.adminPanel,
          Icons.admin_panel_settings_outlined,
        ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const Padding(padding: EdgeInsets.all(20), child: _DrawerBrand()),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (BuildContext context, int index) {
                  final _DrawerItem item = items[index];
                  return ListTile(
                    leading: Icon(item.icon),
                    title: Text(
                      LocalizedText(item.ar, item.en).resolve(context),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(item.route);
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 4),
                itemCount: items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerBrand extends StatelessWidget {
  const _DrawerBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: SvgPicture.asset(AppAssets.appIcon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('مكان', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Makaan • App Foundation',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.assetPath, this.selected = false});

  final String assetPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(
        selected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.assetPath);

  final LocalizedText label;
  final String route;
  final String assetPath;

  static const List<_NavItem> items = <_NavItem>[
    _NavItem(
      LocalizedText('الرئيسية', 'Home'),
      AppRoutes.home,
      AppAssets.homeIcon,
    ),
    _NavItem(
      LocalizedText('التصنيفات', 'Categories'),
      AppRoutes.categories,
      AppAssets.categoriesIcon,
    ),
    _NavItem(
      LocalizedText('الطلبات', 'Orders'),
      AppRoutes.orders,
      AppAssets.ordersIcon,
    ),
    _NavItem(
      LocalizedText('الإعلانات', 'Ads'),
      AppRoutes.ads,
      AppAssets.adsIcon,
    ),
    _NavItem(
      LocalizedText('الحساب', 'Profile'),
      AppRoutes.profile,
      AppAssets.profileIcon,
    ),
  ];
}

class _DrawerItem {
  const _DrawerItem(this.ar, this.en, this.route, this.icon);

  final String ar;
  final String en;
  final String route;
  final IconData icon;
}
