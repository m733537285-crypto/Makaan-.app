import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/order_models.dart';
import '../../../../shared/models/provider_models.dart';
import '../../../../shared/utils/date_time_formatter.dart';
import '../../../../shared/widgets/app_buttons.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Set<String> _busyOrders = <String>{};

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final bool isProvider = controller.currentUser?.isProvider ?? false;

    return AppScaffold(
      title: 'الطلبات',
      currentNavIndex: 2,
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'الإشعارات',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
          icon: Badge.count(
            isLabelVisible: controller.unreadNotificationsCount > 0,
            count: controller.unreadNotificationsCount,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
      floatingActionButton: isProvider
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createRequest),
              icon: const Icon(Icons.add_rounded),
              label: const Text('طلب جديد'),
            ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isProvider
              ? _ProviderOrdersView(
                  controller: controller,
                  busyOrders: _busyOrders,
                  onAccept: _acceptOrder,
                  onReject: _rejectOrder,
                  onStatusUpdate: _updateStatus,
                  onShowDetails: _showDetails,
                )
              : _ClientOrdersView(
                  controller: controller,
                  busyOrders: _busyOrders,
                  onCancel: _cancelOrder,
                  onShowDetails: _showDetails,
                ),
        ),
      ),
    );
  }

  Future<void> _acceptOrder(AppController controller, ServiceOrder order) async {
    await _runOrderTask(
      order.orderId,
      () => controller.acceptProviderOrder(order.orderId),
      successMessage: 'تم قبول الطلب بنجاح.',
    );
  }

  Future<void> _rejectOrder(AppController controller, ServiceOrder order) async {
    final ServiceOrder? updated = await _runOrderTask(
      order.orderId,
      () => controller.rejectProviderOrder(order.orderId),
      successMessage: 'تم رفض الطلب.',
      returnOrder: true,
    );
    if (!mounted || updated == null) {
      return;
    }
    if (updated.status == OrderStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحويل الطلب لمقدم خدمة آخر مناسب.')),
      );
    }
  }

  Future<void> _cancelOrder(AppController controller, ServiceOrder order) async {
    await _runOrderTask(
      order.orderId,
      () => controller.cancelClientOrder(order.orderId),
      successMessage: 'تم إلغاء الطلب.',
    );
  }

  Future<void> _updateStatus(
    AppController controller,
    ServiceOrder order,
    OrderStatus status,
  ) async {
    await _runOrderTask(
      order.orderId,
      () => controller.updateProviderOrderStatus(orderId: order.orderId, status: status),
      successMessage: status == OrderStatus.onTheWay
          ? 'تم تحديث الطلب إلى في الطريق.'
          : 'تم إنهاء الطلب بنجاح.',
    );
  }

  Future<ServiceOrder?> _runOrderTask(
    String orderId,
    Future<ServiceOrder> Function() task, {
    required String successMessage,
    bool returnOrder = false,
  }) async {
    setState(() => _busyOrders.add(orderId));
    try {
      final ServiceOrder order = await task();
      if (!mounted) {
        return returnOrder ? order : null;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      return returnOrder ? order : null;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _busyOrders.remove(orderId));
      }
    }
  }

  Future<void> _showDetails(AppController controller, ServiceOrder order) async {
    final user = controller.findUserById(order.userId);
    final ProviderDetails? provider = order.acceptedProviderId == null
        ? null
        : controller.findProviderById(order.acceptedProviderId!);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('تفاصيل الطلب', style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      _StatusPill(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(label: 'رقم الطلب', value: order.orderId),
                  _DetailRow(label: 'نوع الخدمة', value: order.serviceType),
                  _DetailRow(label: 'العميل', value: user?.displayName ?? 'عميل مكان'),
                  _DetailRow(label: 'الهاتف', value: order.phoneNumber),
                  _DetailRow(label: 'الموقع', value: order.locationText),
                  _DetailRow(label: 'وقت الإنشاء', value: DateTimeFormatter.shortDateTime(order.createdAt)),
                  if (provider != null)
                    _DetailRow(label: 'مقدم الخدمة المقبول', value: provider.profile.businessName),
                  _DetailRow(
                    label: 'آخر تحديث',
                    value: DateTimeFormatter.shortDateTime(order.updatedAt),
                  ),
                  const SizedBox(height: 14),
                  Text('وصف الطلب', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(order.description, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClientOrdersView extends StatelessWidget {
  const _ClientOrdersView({
    required this.controller,
    required this.busyOrders,
    required this.onCancel,
    required this.onShowDetails,
  });

  final AppController controller;
  final Set<String> busyOrders;
  final Future<void> Function(AppController controller, ServiceOrder order) onCancel;
  final Future<void> Function(AppController controller, ServiceOrder order) onShowDetails;

  @override
  Widget build(BuildContext context) {
    final List<ServiceOrder> allOrders = controller.clientOrders;
    final List<ServiceOrder> openOrders = allOrders
        .where((ServiceOrder item) =>
            item.status == OrderStatus.pending ||
            item.status == OrderStatus.accepted ||
            item.status == OrderStatus.onTheWay)
        .toList(growable: false);
    final List<ServiceOrder> completedOrders = allOrders
        .where((ServiceOrder item) => item.status == OrderStatus.completed)
        .toList(growable: false);
    final List<ServiceOrder> closedOrders = allOrders
        .where((ServiceOrder item) =>
            item.status == OrderStatus.cancelled || item.status == OrderStatus.rejected)
        .toList(growable: false);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('سجل طلباتك', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'تابع حالة كل طلب، وافتح التفاصيل الكاملة، وألغِ الطلب قبل القبول فقط.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _MetricCard(title: 'الإجمالي', value: '${allOrders.length}', icon: Icons.receipt_long_rounded),
                        _MetricCard(title: 'مفتوحة', value: '${openOrders.length}', icon: Icons.timelapse_rounded),
                        _MetricCard(title: 'منجزة', value: '${completedOrders.length}', icon: Icons.task_alt_rounded),
                        _MetricCard(title: 'مغلقة', value: '${closedOrders.length}', icon: Icons.cancel_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(text: 'الكل'),
                Tab(text: 'المفتوحة'),
                Tab(text: 'تم الإنجاز'),
                Tab(text: 'المغلقة'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _OrderList(
                  orders: allOrders,
                  emptyTitle: 'لا توجد طلبات بعد',
                  emptySubtitle: 'ابدأ بإنشاء أول طلب خدمة من الزر العائم.',
                  itemBuilder: (ServiceOrder order) => _ClientOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onCancel: onCancel,
                    onShowDetails: onShowDetails,
                  ),
                ),
                _OrderList(
                  orders: openOrders,
                  emptyTitle: 'لا توجد طلبات مفتوحة',
                  emptySubtitle: 'الطلبات الجديدة أو المقبولة ستظهر هنا.',
                  itemBuilder: (ServiceOrder order) => _ClientOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onCancel: onCancel,
                    onShowDetails: onShowDetails,
                  ),
                ),
                _OrderList(
                  orders: completedOrders,
                  emptyTitle: 'لا توجد طلبات منجزة',
                  emptySubtitle: 'عند اكتمال تنفيذ أي خدمة ستظهر هنا.',
                  itemBuilder: (ServiceOrder order) => _ClientOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onCancel: onCancel,
                    onShowDetails: onShowDetails,
                  ),
                ),
                _OrderList(
                  orders: closedOrders,
                  emptyTitle: 'لا توجد طلبات مغلقة',
                  emptySubtitle: 'الطلبات الملغاة أو المرفوضة ستظهر هنا.',
                  itemBuilder: (ServiceOrder order) => _ClientOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onCancel: onCancel,
                    onShowDetails: onShowDetails,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderOrdersView extends StatelessWidget {
  const _ProviderOrdersView({
    required this.controller,
    required this.busyOrders,
    required this.onAccept,
    required this.onReject,
    required this.onStatusUpdate,
    required this.onShowDetails,
  });

  final AppController controller;
  final Set<String> busyOrders;
  final Future<void> Function(AppController controller, ServiceOrder order) onAccept;
  final Future<void> Function(AppController controller, ServiceOrder order) onReject;
  final Future<void> Function(
    AppController controller,
    ServiceOrder order,
    OrderStatus status,
  ) onStatusUpdate;
  final Future<void> Function(AppController controller, ServiceOrder order) onShowDetails;

  @override
  Widget build(BuildContext context) {
    final List<ServiceOrder> inboxOrders = controller.providerInboxOrders;
    final List<ServiceOrder> activeOrders = controller.providerActiveOrders;
    final List<ServiceOrder> completedOrders = controller.providerCompletedOrders;
    final List<ServiceOrder> rejectedOrders = controller.providerRejectedOrders;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('صندوق الطلبات', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'الطلبات تظهر لك فقط عند مطابقة الخدمة والمنطقة مع اشتراك فعال. يمكنك القبول أو الرفض أو تحديث الحالة حتى الإنجاز.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _MetricCard(title: 'الواردة', value: '${inboxOrders.length}', icon: Icons.inbox_outlined),
                        _MetricCard(title: 'قيد التنفيذ', value: '${activeOrders.length}', icon: Icons.directions_car_filled_outlined),
                        _MetricCard(title: 'مكتملة', value: '${completedOrders.length}', icon: Icons.task_alt_rounded),
                        _MetricCard(title: 'مرفوضة', value: '${rejectedOrders.length}', icon: Icons.close_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(text: 'الواردة'),
                Tab(text: 'قيد التنفيذ'),
                Tab(text: 'مكتملة'),
                Tab(text: 'مرفوضة'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _OrderList(
                  orders: inboxOrders,
                  emptyTitle: 'صندوق الوارد فارغ',
                  emptySubtitle: 'ستظهر الطلبات الجديدة عند مطابقة نوع خدمتك ومنطقتك.',
                  itemBuilder: (ServiceOrder order) => _ProviderOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onAccept: onAccept,
                    onReject: onReject,
                    onStatusUpdate: onStatusUpdate,
                    onShowDetails: onShowDetails,
                  ),
                ),
                _OrderList(
                  orders: activeOrders,
                  emptyTitle: 'لا توجد طلبات قيد التنفيذ',
                  emptySubtitle: 'بعد قبول الطلبات ستظهر هنا.',
                  itemBuilder: (ServiceOrder order) => _ProviderOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onAccept: onAccept,
                    onReject: onReject,
                    onStatusUpdate: onStatusUpdate,
                    onShowDetails: onShowDetails,
                  ),
                ),
                _OrderList(
                  orders: completedOrders,
                  emptyTitle: 'لا توجد طلبات مكتملة',
                  emptySubtitle: 'الطلبات المنتهية ستظهر هنا.',
                  itemBuilder: (ServiceOrder order) => _ProviderOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onAccept: onAccept,
                    onReject: onReject,
                    onStatusUpdate: onStatusUpdate,
                    onShowDetails: onShowDetails,
                  ),
                ),
                _OrderList(
                  orders: rejectedOrders,
                  emptyTitle: 'لا توجد طلبات مرفوضة',
                  emptySubtitle: 'الطلبات التي اعتذرت عنها ستظهر هنا.',
                  itemBuilder: (ServiceOrder order) => _ProviderOrderCard(
                    controller: controller,
                    order: order,
                    isBusy: busyOrders.contains(order.orderId),
                    onAccept: onAccept,
                    onReject: onReject,
                    onStatusUpdate: onStatusUpdate,
                    onShowDetails: onShowDetails,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.itemBuilder,
  });

  final List<ServiceOrder> orders;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(ServiceOrder order) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(emptyTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(emptySubtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (BuildContext context, int index) => itemBuilder(orders[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: orders.length,
    );
  }
}

class _ClientOrderCard extends StatelessWidget {
  const _ClientOrderCard({
    required this.controller,
    required this.order,
    required this.isBusy,
    required this.onCancel,
    required this.onShowDetails,
  });

  final AppController controller;
  final ServiceOrder order;
  final bool isBusy;
  final Future<void> Function(AppController controller, ServiceOrder order) onCancel;
  final Future<void> Function(AppController controller, ServiceOrder order) onShowDetails;

  @override
  Widget build(BuildContext context) {
    final ProviderDetails? assignedProvider = order.acceptedProviderId == null
        ? null
        : controller.findProviderById(order.acceptedProviderId!);
    final String providerName = assignedProvider?.profile.businessName ??
        (order.status == OrderStatus.pending ? 'بانتظار قبول مقدم الخدمة' : 'غير متاح');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(order.serviceType, style: Theme.of(context).textTheme.titleLarge),
                ),
                _StatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(order.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoTag(icon: Icons.storefront_outlined, text: providerName),
                _InfoTag(icon: Icons.place_outlined, text: order.locationText),
                _InfoTag(icon: Icons.schedule_outlined, text: DateTimeFormatter.shortDateTime(order.createdAt)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                AppSecondaryButton(
                  label: 'التفاصيل',
                  icon: Icons.visibility_outlined,
                  onPressed: () => onShowDetails(controller, order),
                ),
                if (order.canClientCancel)
                  AppPrimaryButton(
                    label: isBusy ? 'جاري الإلغاء...' : 'إلغاء الطلب',
                    icon: Icons.close_rounded,
                    onPressed: isBusy ? null : () => onCancel(controller, order),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderOrderCard extends StatelessWidget {
  const _ProviderOrderCard({
    required this.controller,
    required this.order,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onStatusUpdate,
    required this.onShowDetails,
  });

  final AppController controller;
  final ServiceOrder order;
  final bool isBusy;
  final Future<void> Function(AppController controller, ServiceOrder order) onAccept;
  final Future<void> Function(AppController controller, ServiceOrder order) onReject;
  final Future<void> Function(
    AppController controller,
    ServiceOrder order,
    OrderStatus status,
  ) onStatusUpdate;
  final Future<void> Function(AppController controller, ServiceOrder order) onShowDetails;

  @override
  Widget build(BuildContext context) {
    final client = controller.findUserById(order.userId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(order.serviceType, style: Theme.of(context).textTheme.titleLarge),
                ),
                _StatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoTag(icon: Icons.person_outline_rounded, text: client?.displayName ?? 'عميل مكان'),
                _InfoTag(icon: Icons.phone_outlined, text: order.phoneNumber),
                _InfoTag(icon: Icons.place_outlined, text: order.locationText),
                _InfoTag(icon: Icons.schedule_outlined, text: DateTimeFormatter.shortDateTime(order.createdAt)),
              ],
            ),
            const SizedBox(height: 12),
            Text(order.description, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                AppSecondaryButton(
                  label: 'التفاصيل',
                  icon: Icons.visibility_outlined,
                  onPressed: () => onShowDetails(controller, order),
                ),
                if (order.status == OrderStatus.pending) ...<Widget>[
                  AppSecondaryButton(
                    label: isBusy ? 'جاري الرفض...' : 'رفض',
                    icon: Icons.close_rounded,
                    onPressed: isBusy ? null : () => onReject(controller, order),
                  ),
                  AppPrimaryButton(
                    label: isBusy ? 'جاري القبول...' : 'قبول',
                    icon: Icons.check_rounded,
                    onPressed: isBusy ? null : () => onAccept(controller, order),
                  ),
                ],
                if (order.status == OrderStatus.accepted)
                  AppPrimaryButton(
                    label: isBusy ? 'جاري التحديث...' : 'في الطريق',
                    icon: Icons.directions_car_filled_outlined,
                    onPressed: isBusy
                        ? null
                        : () => onStatusUpdate(controller, order, OrderStatus.onTheWay),
                  ),
                if (order.status == OrderStatus.onTheWay)
                  AppPrimaryButton(
                    label: isBusy ? 'جاري التحديث...' : 'تم الإنجاز',
                    icon: Icons.task_alt_rounded,
                    onPressed: isBusy
                        ? null
                        : () => onStatusUpdate(controller, order, OrderStatus.completed),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    IconData icon;
    switch (status) {
      case OrderStatus.pending:
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        icon = Icons.schedule_rounded;
        break;
      case OrderStatus.accepted:
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
        icon = Icons.check_circle_outline_rounded;
        break;
      case OrderStatus.rejected:
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
        icon = Icons.block_rounded;
        break;
      case OrderStatus.onTheWay:
        background = scheme.tertiaryContainer;
        foreground = scheme.onTertiaryContainer;
        icon = Icons.directions_car_filled_outlined;
        break;
      case OrderStatus.completed:
        background = scheme.primary.withValues(alpha: 0.15);
        foreground = scheme.primary;
        icon = Icons.task_alt_rounded;
        break;
      case OrderStatus.cancelled:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
        icon = Icons.close_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 6),
          Text(
            status.arabicLabel,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
