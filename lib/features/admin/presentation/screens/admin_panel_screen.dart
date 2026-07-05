import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/ad_models.dart';
import '../../../../shared/models/admin_models.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/order_models.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/services/runtime_diagnostics_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _sectionId = 'dashboard';
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<_AdminSection> visibleSections = _sections
        .where((_AdminSection item) => controller.visibleAdminSectionIds.contains(item.id))
        .toList(growable: false);
    if (!visibleSections.any((_AdminSection item) => item.id == _sectionId)) {
      _sectionId = visibleSections.first.id;
    }

    return AppScaffold(
      title: 'لوحة الإدارة',
      appBarActions: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AdminRole>(
              value: controller.activeAdminRole,
              items: AdminRole.values
                  .map((AdminRole role) => DropdownMenuItem<AdminRole>(value: role, child: Text(role.arabicLabel)))
                  .toList(growable: false),
              onChanged: (AdminRole? role) {
                if (role != null) {
                  controller.setActiveAdminRole(role);
                  setState(() => _sectionId = 'dashboard');
                }
              },
            ),
          ),
        ),
      ],
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 900;
          final Widget navigation = _AdminNavigation(
            sections: visibleSections,
            selectedId: _sectionId,
            onSelected: (String id) => setState(() {
              _sectionId = id;
              _query = '';
              _filter = 'all';
            }),
          );
          final Widget content = _buildContent(controller, wide);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 280, child: navigation),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          }
          return Column(
            children: <Widget>[
              SizedBox(height: 88, child: navigation),
              const Divider(height: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(AppController controller, bool wide) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _AdminHeader(
          title: _sections.firstWhere((_AdminSection item) => item.id == _sectionId).title,
          subtitle: _sections.firstWhere((_AdminSection item) => item.id == _sectionId).subtitle,
          role: controller.activeAdminRole,
        ),
        const SizedBox(height: 16),
        _buildSection(controller),
      ],
    );
  }

  Widget _buildSection(AppController controller) {
    switch (_sectionId) {
      case 'users':
        return _buildUsers(controller);
      case 'providers':
        return _buildProviders(controller);
      case 'subscriptions':
        return _buildSubscriptions(controller);
      case 'ads':
        return _buildAds(controller);
      case 'orders':
        return _buildOrders(controller);
      case 'reports':
        return _buildReports(controller);
      case 'reviews':
        return _buildReviews(controller);
      case 'taxonomy':
        return _buildTaxonomy(controller);
      case 'logs':
        return _buildLogs(controller);
      case 'permissions':
        return _buildPermissions(controller);
      case 'dashboard':
      default:
        return _buildDashboard(controller);
    }
  }

  Widget _buildDashboard(AppController controller) {
    final AdminDashboardMetrics metrics = controller.adminDashboardMetrics;
    final List<_MetricSpec> cards = <_MetricSpec>[
      _MetricSpec('إجمالي المستخدمين', '${metrics.totalUsers}', Icons.people_outline),
      _MetricSpec('مقدمو الخدمات', '${metrics.totalProviders}', Icons.storefront_outlined),
      _MetricSpec('إجمالي الطلبات', '${metrics.totalOrders}', Icons.receipt_long_outlined),
      _MetricSpec('طلبات مكتملة', '${metrics.completedOrders}', Icons.task_alt_outlined),
      _MetricSpec('طلبات ملغاة', '${metrics.cancelledOrders}', Icons.cancel_outlined),
      _MetricSpec('إعلانات نشطة', '${metrics.activeAds}', Icons.campaign_outlined),
      _MetricSpec('إعلانات منتهية', '${metrics.expiredAds}', Icons.timer_off_outlined),
      _MetricSpec('اشتراكات نشطة', '${metrics.activeSubscriptions}', Icons.workspace_premium_outlined),
      _MetricSpec('اشتراكات منتهية', '${metrics.expiredSubscriptions}', Icons.warning_amber_outlined),
      _MetricSpec('البلاغات', '${metrics.reportsCount}', Icons.flag_outlined),
      _MetricSpec('التقييمات', '${metrics.reviewsCount}', Icons.reviews_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((_MetricSpec item) => _MetricCard(spec: item)).toList(growable: false),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('أكثر الخدمات طلبًا', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (metrics.mostRequestedServices.isEmpty)
                  const Text('لا توجد طلبات كافية لاحتساب الخدمات الأكثر طلبًا.')
                else
                  ...metrics.mostRequestedServices.map((String item) => _ProgressLine(label: item, value: 0.72)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('مؤشرات تشغيلية', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _ProgressLine(label: 'نسبة الطلبات المكتملة', value: metrics.totalOrders == 0 ? 0 : metrics.completedOrders / metrics.totalOrders),
                _ProgressLine(label: 'نسبة الإعلانات النشطة', value: (metrics.activeAds + metrics.expiredAds) == 0 ? 0 : metrics.activeAds / (metrics.activeAds + metrics.expiredAds)),
                _ProgressLine(label: 'نسبة الاشتراكات النشطة', value: (metrics.activeSubscriptions + metrics.expiredSubscriptions) == 0 ? 0 : metrics.activeSubscriptions / (metrics.activeSubscriptions + metrics.expiredSubscriptions)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('مراقبة الأداء والأخطاء', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _StatusChip(label: 'عينات الأداء: ${controller.performanceSamples.length}'),
                    _StatusChip(label: 'الأخطاء الحديثة: ${controller.runtimeErrors.length}', danger: controller.runtimeErrors.isNotEmpty),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.performanceSamples.isEmpty)
                  const Text('لا توجد قياسات أداء حديثة بعد.')
                else
                  ...controller.performanceSamples.take(4).map(
                        (PerformanceSample item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.speed_rounded),
                          title: Text(item.name.toString()),
                          trailing: Text(item.summary.toString()),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsers(AppController controller) {
    final List<AppUser> users = controller.adminUsers.where((AppUser item) {
      final String haystack = '${item.displayName} ${item.phoneNumber} ${item.governorate ?? ''} ${item.district ?? ''}'.toLowerCase();
      final bool queryMatch = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' ||
          (_filter == 'blocked' && item.isBlocked) ||
          (_filter == 'active' && !item.isBlocked) ||
          (_filter == 'providers' && item.isProvider) ||
          (_filter == 'clients' && item.userType == UserType.client);
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Toolbar(
            query: _query,
            hint: 'بحث بالاسم أو رقم الهاتف أو الموقع',
            filter: _filter,
            filters: const <String, String>{'all': 'الكل', 'active': 'نشط', 'blocked': 'موقوف', 'providers': 'مقدمو خدمات', 'clients': 'عملاء'},
            onQueryChanged: (String value) => setState(() => _query = value),
            onFilterChanged: (String value) => setState(() => _filter = value),
            onExport: () => _copyExport(controller, 'users'),
          ),
          const SizedBox(height: 12),
          _HorizontalTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('المستخدم')),
              DataColumn(label: Text('الهاتف')),
              DataColumn(label: Text('النوع')),
              DataColumn(label: Text('الموقع')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: users.map((AppUser item) => DataRow(cells: <DataCell>[
              DataCell(Text(item.displayName)),
              DataCell(Text(item.phoneNumber)),
              DataCell(Text(item.userType?.arabicLabel ?? 'غير محدد')),
              DataCell(Text('${item.governorate ?? '--'} - ${item.district ?? '--'}')),
              DataCell(_StatusChip(label: item.isBlocked ? 'موقوف' : 'نشط', danger: item.isBlocked)),
              DataCell(Wrap(spacing: 6, children: <Widget>[
                TextButton(onPressed: () => _editUser(controller, item), child: const Text('تعديل')),
                TextButton(onPressed: () => controller.adminSaveUser(item.copyWith(isBlocked: !item.isBlocked)), child: Text(item.isBlocked ? 'تفعيل' : 'إيقاف')),
                TextButton(onPressed: () => _confirmDeleteUser(controller, item), child: const Text('حذف')),
              ])),
            ])).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildProviders(AppController controller) {
    final List<ProviderDetails> providers = controller.adminProviders.where((ProviderDetails item) {
      final String haystack = '${item.profile.businessName} ${item.profile.mainServiceType} ${item.profile.governorate} ${item.profile.district}'.toLowerCase();
      final bool queryMatch = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' || item.profile.status.value == _filter;
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث باسم النشاط أو الخدمة أو المحافظة',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل', 'active': 'نشط', 'pending': 'بانتظار التفعيل', 'suspended': 'موقوف', 'expired': 'منتهي'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
          onExport: () => _copyExport(controller, 'providers'),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('النشاط')),
            DataColumn(label: Text('الخدمة')),
            DataColumn(label: Text('الموقع')),
            DataColumn(label: Text('الصور/المناطق')),
            DataColumn(label: Text('التقييم')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: providers.map((ProviderDetails item) => DataRow(cells: <DataCell>[
            DataCell(Text(item.profile.businessName)),
            DataCell(Text(item.profile.mainServiceType)),
            DataCell(Text('${item.profile.governorate} - ${item.profile.district}')),
            DataCell(Text('${item.gallery.length} صور / ${item.serviceAreas.length} مناطق')),
            DataCell(Text('${item.averageRating.toStringAsFixed(1)} (${item.reviewCount})')),
            DataCell(_StatusChip(label: item.profile.status.arabicLabel, danger: item.profile.status == ProviderAccountStatus.suspended)),
            DataCell(Wrap(spacing: 6, children: <Widget>[
              TextButton(onPressed: () => _showProviderDetails(item), child: const Text('عرض')),
              TextButton(onPressed: () => controller.adminUpdateProviderStatus(item.profile.providerId, ProviderAccountStatus.active), child: const Text('تفعيل')),
              TextButton(onPressed: () => controller.adminUpdateProviderStatus(item.profile.providerId, ProviderAccountStatus.suspended), child: const Text('إيقاف')),
            ])),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildSubscriptions(AppController controller) {
    final List<ProviderSubscription> subscriptions = controller.adminSubscriptions.where((ProviderSubscription item) {
      final bool queryMatch = _query.trim().isEmpty || '${item.providerId} ${item.planType}'.toLowerCase().contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' || item.status.value == _filter || (_filter == 'expired_by_date' && item.endDate.isBefore(DateTime.now()));
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث برقم مقدم الخدمة أو الخطة',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل', 'active': 'نشط', 'pending': 'قيد المراجعة', 'expired': 'منتهي', 'expired_by_date': 'منتهي بالتاريخ'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
          onExport: () => _copyExport(controller, 'providers'),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('مقدم الخدمة')),
            DataColumn(label: Text('الخطة')),
            DataColumn(label: Text('البداية')),
            DataColumn(label: Text('النهاية')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('الدفع')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: subscriptions.map((ProviderSubscription item) => DataRow(cells: <DataCell>[
            DataCell(Text(item.providerId)),
            DataCell(Text(item.planType)),
            DataCell(Text(_formatDate(item.startDate))),
            DataCell(Text(_formatDate(item.endDate))),
            DataCell(Text(item.status.arabicLabel)),
            DataCell(Text(item.paymentStatus.arabicLabel)),
            DataCell(Wrap(spacing: 6, children: <Widget>[
              TextButton(onPressed: () => controller.adminSaveSubscription(ProviderSubscription(subscriptionId: item.subscriptionId, providerId: item.providerId, planType: item.planType, startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 30)), status: SubscriptionStatus.active, paymentStatus: PaymentStatus.paid)), child: const Text('تفعيل')),
              TextButton(onPressed: () => controller.adminSaveSubscription(ProviderSubscription(subscriptionId: item.subscriptionId, providerId: item.providerId, planType: item.planType, startDate: item.startDate, endDate: item.endDate, status: SubscriptionStatus.expired, paymentStatus: item.paymentStatus)), child: const Text('إيقاف')),
              TextButton(onPressed: () => controller.adminSaveSubscription(ProviderSubscription(subscriptionId: item.subscriptionId, providerId: item.providerId, planType: item.planType, startDate: item.startDate, endDate: item.endDate.add(const Duration(days: 30)), status: SubscriptionStatus.active, paymentStatus: PaymentStatus.paid)), child: const Text('+30 يوم')),
            ])),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildAds(AppController controller) {
    final List<AdListing> ads = controller.adminAds.where((AdListing item) {
      final String haystack = '${item.title} ${item.description} ${item.locationText} ${item.category.arabicLabel}'.toLowerCase();
      final bool queryMatch = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' || item.effectiveStatus.value == _filter || (_filter == 'banner' && item.isBanner) || (_filter == 'featured' && item.isFeatured);
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث في الإعلانات بالعنوان أو الوصف أو الموقع',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل', 'active': 'نشط', 'pending': 'بانتظار المراجعة', 'expired': 'منتهي', 'rejected': 'مرفوض', 'banner': 'مثبت أعلى', 'featured': 'مميز'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
          onExport: () => _copyExport(controller, 'ads'),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('الإعلان')),
            DataColumn(label: Text('التصنيف')),
            DataColumn(label: Text('السعر')),
            DataColumn(label: Text('الموقع')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('الشريط')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: ads.map((AdListing item) => DataRow(cells: <DataCell>[
            DataCell(SizedBox(width: 220, child: Text(item.title, overflow: TextOverflow.ellipsis))),
            DataCell(Text(item.category.arabicLabel)),
            DataCell(Text('${item.priceAfter.round()}')),
            DataCell(Text(item.locationText)),
            DataCell(Text(item.effectiveStatus.arabicLabel)),
            DataCell(Text(item.isBanner ? 'مثبت' : '--')),
            DataCell(Wrap(spacing: 6, children: <Widget>[
              TextButton(onPressed: () => controller.adminUpdateAd(item.copyWith(status: AdStatus.active)), child: const Text('قبول')),
              TextButton(onPressed: () => controller.adminUpdateAd(item.copyWith(status: AdStatus.rejected)), child: const Text('رفض')),
              TextButton(onPressed: () => controller.adminUpdateAd(item.copyWith(isBanner: !item.isBanner, isFeatured: true)), child: Text(item.isBanner ? 'إلغاء تثبيت' : 'تثبيت')),
              TextButton(onPressed: () => controller.adminUpdateAd(item.copyWith(expiresAt: DateTime.now().add(const Duration(days: 7)), status: AdStatus.active)), child: const Text('7 أيام')),
              TextButton(onPressed: () => controller.adminDeleteAd(item.adId), child: const Text('حذف')),
            ])),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildOrders(AppController controller) {
    final List<ServiceOrder> orders = controller.adminOrders.where((ServiceOrder item) {
      final String haystack = '${item.orderId} ${item.serviceType} ${item.description} ${item.locationText} ${item.phoneNumber}'.toLowerCase();
      final bool queryMatch = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' || item.status.value == _filter;
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث في الطلبات بالخدمة أو الموقع أو الهاتف',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل', 'pending': 'قيد الانتظار', 'accepted': 'تم القبول', 'on_the_way': 'في الطريق', 'completed': 'مكتمل', 'cancelled': 'ملغى', 'rejected': 'مرفوض'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
          onExport: () => _copyExport(controller, 'orders'),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('الخدمة')),
            DataColumn(label: Text('الموقع')),
            DataColumn(label: Text('الهاتف')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('تاريخ الإنشاء')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: orders.map((ServiceOrder item) => DataRow(cells: <DataCell>[
            DataCell(Text(item.serviceType)),
            DataCell(Text(item.locationText)),
            DataCell(Text(item.phoneNumber)),
            DataCell(Text(item.status.arabicLabel)),
            DataCell(Text(_formatDate(item.createdAt))),
            DataCell(Wrap(spacing: 6, children: <Widget>[
              TextButton(onPressed: () => _showOrderDetails(item), child: const Text('تفاصيل')),
              TextButton(onPressed: () => controller.adminUpdateOrder(item.copyWith(status: OrderStatus.onTheWay)), child: const Text('متابعة')),
              TextButton(onPressed: () => controller.adminUpdateOrder(item.copyWith(status: OrderStatus.cancelled)), child: const Text('إلغاء')),
              TextButton(onPressed: () => controller.adminUpdateOrder(item.copyWith(status: OrderStatus.completed)), child: const Text('إنجاز')),
            ])),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildReports(AppController controller) {
    final List<AdminReportTicket> reports = controller.adminReports.where((AdminReportTicket item) {
      final String haystack = '${item.reporterName} ${item.reportedName} ${item.reason} ${item.targetType}'.toLowerCase();
      final bool queryMatch = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' || item.status.value == _filter;
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث في البلاغات',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل', 'pending': 'قيد المراجعة', 'accepted': 'مقبول', 'rejected': 'مرفوض'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('المبلّغ')),
            DataColumn(label: Text('المبلّغ عليه')),
            DataColumn(label: Text('النوع')),
            DataColumn(label: Text('السبب')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: reports.map((AdminReportTicket item) => DataRow(cells: <DataCell>[
            DataCell(Text(item.reporterName)),
            DataCell(Text(item.reportedName)),
            DataCell(Text(item.targetType)),
            DataCell(SizedBox(width: 280, child: Text(item.reason, overflow: TextOverflow.ellipsis))),
            DataCell(Text(item.status.arabicLabel)),
            DataCell(Wrap(spacing: 6, children: <Widget>[
              TextButton(onPressed: () => controller.adminResolveReport(item.reportId, AdminReportStatus.accepted, note: 'تم قبول البلاغ واتخاذ الإجراء المناسب.'), child: const Text('قبول')),
              TextButton(onPressed: () => controller.adminResolveReport(item.reportId, AdminReportStatus.rejected, note: 'تم رفض البلاغ لعدم كفاية الأدلة.'), child: const Text('رفض')),
              TextButton(onPressed: () => _showReportDetails(item), child: const Text('عرض')),
            ])),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildReviews(AppController controller) {
    final List<ProviderReview> reviews = controller.adminReviews.where((ProviderReview item) {
      final String haystack = '${item.customerName} ${item.comment} ${item.rating}'.toLowerCase();
      final bool queryMatch = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
      final bool filterMatch = _filter == 'all' || (_filter == 'low' && item.rating <= 2) || (_filter == 'high' && item.rating >= 4);
      return queryMatch && filterMatch;
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث باسم العميل أو التعليق',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل', 'low': 'منخفضة', 'high': 'مرتفعة'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('العميل')),
            DataColumn(label: Text('التقييم')),
            DataColumn(label: Text('التعليق')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: reviews.map((ProviderReview item) => DataRow(cells: <DataCell>[
            DataCell(Text(item.customerName)),
            DataCell(Text('${item.rating} ⭐')),
            DataCell(SizedBox(width: 320, child: Text(item.comment, overflow: TextOverflow.ellipsis))),
            DataCell(Text(_formatDate(item.createdAt))),
            DataCell(TextButton(onPressed: () => controller.adminDeleteReview(item.reviewId), child: const Text('حذف/إخفاء'))),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildTaxonomy(AppController controller) {
    final List<AdminManagedLocation> locations = controller.adminManagedLocations;
    final List<AdminManagedCategory> categories = controller.adminManagedCategories;
    return Column(
      children: <Widget>[
        _SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('المحافظات والمديريات', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: locations.map((AdminManagedLocation item) => Chip(label: Text('${item.governorate} (${item.districts.length})'))).toList(growable: false),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => _addLocation(controller, locations), icon: const Icon(Icons.add_location_alt_outlined), label: const Text('إضافة محافظة/مديرية')),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('التصنيفات والخدمات', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _HorizontalTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('التصنيف')),
                DataColumn(label: Text('الخدمات')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('إجراءات')),
              ],
              rows: categories.map((AdminManagedCategory item) => DataRow(cells: <DataCell>[
                DataCell(Text('${item.emoji} ${item.title}')),
                DataCell(SizedBox(width: 360, child: Text(item.services.join('، '), overflow: TextOverflow.ellipsis))),
                DataCell(Text(item.isActive ? 'نشط' : 'مخفي')),
                DataCell(Wrap(spacing: 6, children: <Widget>[
                  TextButton(onPressed: () => _toggleCategory(controller, categories, item), child: Text(item.isActive ? 'إخفاء' : 'تفعيل')),
                  TextButton(onPressed: () => _deleteCategory(controller, categories, item), child: const Text('حذف')),
                ])),
              ])).toList(growable: false),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => _addCategory(controller, categories), icon: const Icon(Icons.add_rounded), label: const Text('إضافة تصنيف/خدمة')),
          ]),
        ),
      ],
    );
  }

  Widget _buildLogs(AppController controller) {
    final List<AdminSystemLog> logs = controller.adminLogs.where((AdminSystemLog item) {
      final String haystack = '${item.actorName} ${item.action} ${item.targetType} ${item.details}'.toLowerCase();
      return _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
    }).toList(growable: false);
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _Toolbar(
          query: _query,
          hint: 'بحث في سجل النظام',
          filter: _filter,
          filters: const <String, String>{'all': 'الكل'},
          onQueryChanged: (String value) => setState(() => _query = value),
          onFilterChanged: (String value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        _HorizontalTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('المدير')),
            DataColumn(label: Text('الصلاحية')),
            DataColumn(label: Text('العملية')),
            DataColumn(label: Text('الهدف')),
            DataColumn(label: Text('التفاصيل')),
          ],
          rows: logs.map((AdminSystemLog item) => DataRow(cells: <DataCell>[
            DataCell(Text(_formatDateTime(item.createdAt))),
            DataCell(Text(item.actorName)),
            DataCell(Text(item.role.arabicLabel)),
            DataCell(Text(item.action)),
            DataCell(Text('${item.targetType} / ${item.targetId}')),
            DataCell(SizedBox(width: 360, child: Text(item.details, overflow: TextOverflow.ellipsis))),
          ])).toList(growable: false),
        ),
      ]),
    );
  }

  Widget _buildPermissions(AppController controller) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AdminRole.values.map((AdminRole role) {
        final List<String> sections = _visibleSectionsFor(role);
        return SizedBox(
          width: 330,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(role.arabicLabel, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(role == controller.activeAdminRole ? 'الصلاحية النشطة حاليًا' : 'صلاحية قابلة للاختيار من أعلى اللوحة'),
                  const SizedBox(height: 12),
                  ...sections.map((String id) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: <Widget>[
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_sections.firstWhere((_AdminSection item) => item.id == id).title)),
                    ]),
                  )),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Future<void> _editUser(AppController controller, AppUser user) async {
    final TextEditingController name = TextEditingController(text: user.name ?? '');
    final TextEditingController phone = TextEditingController(text: user.phoneNumber);
    final TextEditingController governorate = TextEditingController(text: user.governorate ?? '');
    final TextEditingController district = TextEditingController(text: user.district ?? '');
    UserType? type = user.userType;
    final AppUser? result = await showDialog<AppUser>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: const Text('تعديل بيانات المستخدم'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
                DropdownButtonFormField<UserType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  items: UserType.values.map((UserType item) => DropdownMenuItem<UserType>(value: item, child: Text(item.arabicLabel))).toList(growable: false),
                  onChanged: (UserType? value) => setDialogState(() => type = value),
                ),
                TextField(controller: governorate, decoration: const InputDecoration(labelText: 'المحافظة')),
                TextField(controller: district, decoration: const InputDecoration(labelText: 'المديرية')),
              ]),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(user.copyWith(
                name: name.text.trim().isEmpty ? null : name.text.trim(),
                clearName: name.text.trim().isEmpty,
                phoneNumber: phone.text.trim(),
                userType: type,
                clearUserType: type == null,
                governorate: governorate.text.trim().isEmpty ? null : governorate.text.trim(),
                clearGovernorate: governorate.text.trim().isEmpty,
                district: district.text.trim().isEmpty ? null : district.text.trim(),
                clearDistrict: district.text.trim().isEmpty,
              )),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    governorate.dispose();
    district.dispose();
    if (result != null) {
      await controller.adminSaveUser(result);
      if (mounted) {
        AppDialogs.showSuccessSnackBar(context, 'تم حفظ بيانات المستخدم.');
      }
    }
  }

  Future<void> _confirmDeleteUser(AppController controller, AppUser user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text('هل تريد حذف حساب ${user.displayName}؟'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.adminDeleteUser(user.userId);
    }
  }

  void _showProviderDetails(ProviderDetails provider) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(provider.profile.businessName),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
              _InfoLine('الوصف', provider.profile.description),
              _InfoLine('مناطق الخدمة', provider.serviceAreas.map((ProviderServiceArea item) => '${item.governorate}-${item.district}').join('، ')),
              _InfoLine('معرض الصور', '${provider.gallery.length} صورة'),
              _InfoLine('التقييمات', '${provider.reviewCount} تقييم - متوسط ${provider.averageRating.toStringAsFixed(1)}'),
              _InfoLine('الاشتراك', provider.subscription == null ? 'لا يوجد' : '${provider.subscription!.planType} / ${provider.subscription!.status.arabicLabel}'),
            ]),
          ),
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
      ),
    );
  }

  void _showOrderDetails(ServiceOrder order) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('طلب ${order.serviceType}'),
        content: SizedBox(
          width: 520,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
            _InfoLine('الوصف', order.description),
            _InfoLine('الموقع', order.locationText),
            _InfoLine('الهاتف', order.phoneNumber),
            _InfoLine('مقدمو الخدمة المستهدفون', order.targetedProviderIds.join('، ')),
            _InfoLine('الحالة', order.status.arabicLabel),
          ]),
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
      ),
    );
  }

  void _showReportDetails(AdminReportTicket report) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('بلاغ ${report.reportId}'),
        content: SizedBox(
          width: 520,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
            _InfoLine('المبلّغ', report.reporterName),
            _InfoLine('المبلّغ عليه', report.reportedName),
            _InfoLine('الهدف', '${report.targetType} / ${report.targetId}'),
            _InfoLine('السبب', report.reason),
            _InfoLine('الحالة', report.status.arabicLabel),
            if (report.actionNote != null) _InfoLine('الإجراء', report.actionNote!),
          ]),
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
      ),
    );
  }

  Future<void> _addLocation(AppController controller, List<AdminManagedLocation> current) async {
    final TextEditingController governorate = TextEditingController();
    final TextEditingController district = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('إضافة محافظة/مديرية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(controller: governorate, decoration: const InputDecoration(labelText: 'المحافظة')),
          TextField(controller: district, decoration: const InputDecoration(labelText: 'المديرية')),
        ]),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حفظ')),
        ],
      ),
    );
    if (saved == true && governorate.text.trim().isNotEmpty) {
      final List<AdminManagedLocation> next = List<AdminManagedLocation>.from(current);
      final int index = next.indexWhere((AdminManagedLocation item) => item.governorate == governorate.text.trim());
      if (index == -1) {
        next.add(AdminManagedLocation(governorate: governorate.text.trim(), districts: district.text.trim().isEmpty ? const <String>[] : <String>[district.text.trim()]));
      } else if (district.text.trim().isNotEmpty && !next[index].districts.contains(district.text.trim())) {
        next[index] = next[index].copyWith(districts: <String>[...next[index].districts, district.text.trim()]);
      }
      await controller.adminSaveLocations(next);
    }
    governorate.dispose();
    district.dispose();
  }

  Future<void> _addCategory(AppController controller, List<AdminManagedCategory> current) async {
    final TextEditingController title = TextEditingController();
    final TextEditingController emoji = TextEditingController(text: '📦');
    final TextEditingController services = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('إضافة تصنيف'),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم التصنيف')),
          TextField(controller: emoji, decoration: const InputDecoration(labelText: 'الأيقونة/الرمز')),
          TextField(controller: services, decoration: const InputDecoration(labelText: 'الخدمات مفصولة بفواصل')),
        ]),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حفظ')),
        ],
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      final List<AdminManagedCategory> next = List<AdminManagedCategory>.from(current)
        ..add(AdminManagedCategory(
          categoryId: 'category_${DateTime.now().millisecondsSinceEpoch}',
          title: title.text.trim(),
          emoji: emoji.text.trim().isEmpty ? '📦' : emoji.text.trim(),
          services: services.text.split(',').map((String item) => item.trim()).where((String item) => item.isNotEmpty).toList(growable: false),
        ));
      await controller.adminSaveCategories(next);
    }
    title.dispose();
    emoji.dispose();
    services.dispose();
  }

  Future<void> _toggleCategory(AppController controller, List<AdminManagedCategory> categories, AdminManagedCategory category) async {
    final List<AdminManagedCategory> next = categories.map((AdminManagedCategory item) => item.categoryId == category.categoryId ? item.copyWith(isActive: !item.isActive) : item).toList(growable: false);
    await controller.adminSaveCategories(next);
  }

  Future<void> _deleteCategory(AppController controller, List<AdminManagedCategory> categories, AdminManagedCategory category) async {
    await controller.adminSaveCategories(categories.where((AdminManagedCategory item) => item.categoryId != category.categoryId).toList(growable: false));
  }

  Future<void> _copyExport(AppController controller, String section) async {
    final AdminExportBundle bundle = controller.adminExportCsv(section);
    await Clipboard.setData(ClipboardData(text: bundle.csvContent));
    if (mounted) {
      AppDialogs.showSuccessSnackBar(context, 'تم تجهيز ${bundle.fileName} ونسخ محتوى CSV للحافظة.');
    }
  }

  List<String> _visibleSectionsFor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return const <String>['dashboard', 'users', 'providers', 'subscriptions', 'ads', 'orders', 'reports', 'reviews', 'taxonomy', 'logs', 'permissions'];
      case AdminRole.contentManager:
        return const <String>['dashboard', 'providers', 'ads', 'reports', 'reviews', 'taxonomy', 'logs'];
      case AdminRole.subscriptionsManager:
        return const <String>['dashboard', 'providers', 'subscriptions', 'logs'];
      case AdminRole.supportManager:
        return const <String>['dashboard', 'users', 'orders', 'reports', 'reviews', 'logs'];
    }
  }
}

class _AdminSection {
  const _AdminSection(this.id, this.title, this.subtitle, this.icon);
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

const List<_AdminSection> _sections = <_AdminSection>[
  _AdminSection('dashboard', 'لوحة التحكم الرئيسية', 'إحصائيات مباشرة ومؤشرات تشغيلية للمنصة.', Icons.space_dashboard_outlined),
  _AdminSection('users', 'إدارة المستخدمين', 'عرض وبحث وتعديل وإيقاف وحذف حسابات المستخدمين.', Icons.people_outline),
  _AdminSection('providers', 'إدارة مقدمي الخدمات', 'مراجعة البيانات والمعارض والمناطق والتقييمات وحالة الحساب.', Icons.storefront_outlined),
  _AdminSection('subscriptions', 'إدارة الاشتراكات', 'تفعيل وإيقاف وتمديد الاشتراكات ومراقبة المنتهي منها.', Icons.workspace_premium_outlined),
  _AdminSection('ads', 'إدارة الإعلانات', 'قبول ورفض وتعديل وتثبيت وتحديد مدة الإعلانات.', Icons.campaign_outlined),
  _AdminSection('orders', 'إدارة الطلبات', 'بحث وتصفية ومتابعة وإلغاء الطلبات من لوحة الإدارة.', Icons.receipt_long_outlined),
  _AdminSection('reports', 'إدارة البلاغات', 'مراجعة البلاغات وقبولها أو رفضها وتسجيل الإجراءات.', Icons.flag_outlined),
  _AdminSection('reviews', 'إدارة التقييمات', 'مراجعة وحذف التعليقات المخالفة أو غير اللائقة.', Icons.reviews_outlined),
  _AdminSection('taxonomy', 'المحافظات والتصنيفات', 'إضافة المحافظات والمديريات والتصنيفات والخدمات.', Icons.account_tree_outlined),
  _AdminSection('logs', 'سجل النظام', 'تتبع عمليات تسجيل الدخول والحذف والتفعيل وكل إجراءات المدير.', Icons.manage_search_outlined),
  _AdminSection('permissions', 'الصلاحيات', 'أدوار المديرين ونطاق ظهور كل قسم.', Icons.admin_panel_settings_outlined),
];

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({required this.sections, required this.selectedId, required this.onSelected});
  final List<_AdminSection> sections;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      final bool horizontal = constraints.maxHeight < 160;
      if (horizontal) {
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          scrollDirection: Axis.horizontal,
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) => ChoiceChip(
            avatar: Icon(sections[index].icon, size: 18),
            label: Text(sections[index].title),
            selected: selectedId == sections[index].id,
            onSelected: (_) => onSelected(sections[index].id),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (BuildContext context, int index) {
          final _AdminSection item = sections[index];
          return ListTile(
            selected: selectedId == item.id,
            leading: Icon(item.icon),
            title: Text(item.title),
            subtitle: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () => onSelected(item.id),
          );
        },
      );
    });
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title, required this.subtitle, required this.role});
  final String title;
  final String subtitle;
  final AdminRole role;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            CircleAvatar(radius: 28, child: Icon(Icons.admin_panel_settings_outlined, size: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(subtitle),
              ]),
            ),
            Chip(label: Text(role.arabicLabel)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: child));
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.query, required this.hint, required this.filter, required this.filters, required this.onQueryChanged, required this.onFilterChanged, this.onExport});
  final String query;
  final String hint;
  final String filter;
  final Map<String, String> filters;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 360,
          child: TextField(
            controller: TextEditingController(text: query)..selection = TextSelection.collapsed(offset: query.length),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: hint),
            onChanged: onQueryChanged,
          ),
        ),
        DropdownButton<String>(
          value: filters.containsKey(filter) ? filter : filters.keys.first,
          items: filters.entries.map((MapEntry<String, String> item) => DropdownMenuItem<String>(value: item.key, child: Text(item.value))).toList(growable: false),
          onChanged: (String? value) {
            if (value != null) {
              onFilterChanged(value);
            }
          },
        ),
        OutlinedButton.icon(onPressed: () { onQueryChanged(''); onFilterChanged('all'); }, icon: const Icon(Icons.refresh_outlined), label: const Text('إعادة تعيين')),
        if (onExport != null) OutlinedButton.icon(onPressed: onExport, icon: const Icon(Icons.download_outlined), label: const Text('تصدير CSV/Excel')),
      ],
    );
  }
}

class _HorizontalTable extends StatelessWidget {
  const _HorizontalTable({required this.columns, required this.rows});
  final List<DataColumn> columns;
  final List<DataRow> rows;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد بيانات مطابقة.')));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: columns, rows: rows),
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.spec});
  final _MetricSpec spec;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Icon(spec.icon),
            const SizedBox(height: 10),
            Text(spec.value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(spec.label),
          ]),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    final double safeValue = value.clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[Expanded(child: Text(label)), Text('${(safeValue * 100).round()}%')]),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: safeValue),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.danger = false});
  final String label;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: Icon(danger ? Icons.block_outlined : Icons.check_circle_outline_rounded, size: 18),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        Expanded(child: Text(value.isEmpty ? '--' : value)),
      ]),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
