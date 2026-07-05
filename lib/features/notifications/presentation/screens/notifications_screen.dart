import 'package:flutter/material.dart';

import '../../../../core/app_controller.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/models/order_models.dart';
import '../../../../shared/utils/date_time_formatter.dart';
import '../../../../shared/widgets/app_buttons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAll = false;
  final Set<String> _busyNotifications = <String>{};

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<InAppNotification> notifications = controller.currentNotifications;
    final int unreadCount = notifications.where((InAppNotification item) => !item.isRead).length;

    return AppScaffold(
      title: 'الإشعارات',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('مركز الإشعارات', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'استقبل كل تحديثات الطلبات بشكل فوري: إنشاء، قبول، رفض، وتغيير الحالة.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _NotificationMetric(title: 'الإجمالي', value: '${notifications.length}'),
                          _NotificationMetric(title: 'غير المقروءة', value: '$unreadCount'),
                          AppSecondaryButton(
                            label: _isMarkingAll ? 'جاري التحديث...' : 'تحديد الكل كمقروء',
                            icon: Icons.done_all_rounded,
                            onPressed: unreadCount == 0 || _isMarkingAll ? null : () => _markAll(controller),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (notifications.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text('لا توجد إشعارات بعد', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'عند إنشاء طلب أو تحديث حالته ستظهر الإشعارات هنا مباشرة.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...notifications.map(
                  (InAppNotification item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _NotificationCard(
                      notification: item,
                      isBusy: _busyNotifications.contains(item.notificationId),
                      onTap: () => _markOne(controller, item.notificationId),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAll(AppController controller) async {
    setState(() => _isMarkingAll = true);
    try {
      await controller.markAllNotificationsAsRead();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعليم كل الإشعارات كمقروءة.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Future<void> _markOne(AppController controller, String notificationId) async {
    if (_busyNotifications.contains(notificationId)) {
      return;
    }
    setState(() => _busyNotifications.add(notificationId));
    try {
      await controller.markNotificationAsRead(notificationId);
    } finally {
      if (mounted) {
        setState(() => _busyNotifications.remove(notificationId));
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isBusy,
    required this.onTap,
  });

  final InAppNotification notification;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool unread = !notification.isRead;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: unread && !isBusy ? onTap : null,
      child: Card(
        color: unread
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.32)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _typeColor(context, notification.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_typeIcon(notification.type), color: _typeColor(context, notification.type)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notification.body, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          text: DateTimeFormatter.relativeArabic(notification.createdAt),
                        ),
                        _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          text: DateTimeFormatter.shortDateTime(notification.createdAt),
                        ),
                        if (notification.orderId != null)
                          _MetaChip(
                            icon: Icons.receipt_long_rounded,
                            text: notification.orderId!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
        return Icons.add_alert_outlined;
      case NotificationType.orderAccepted:
        return Icons.check_circle_outline_rounded;
      case NotificationType.orderRejected:
        return Icons.report_gmailerrorred_rounded;
      case NotificationType.orderStatusChanged:
        return Icons.sync_alt_rounded;
      case NotificationType.orderCancelled:
        return Icons.cancel_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(BuildContext context, NotificationType type) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (type) {
      case NotificationType.orderCreated:
        return scheme.primary;
      case NotificationType.orderAccepted:
        return const Color(0xFF059669);
      case NotificationType.orderRejected:
        return scheme.error;
      case NotificationType.orderStatusChanged:
        return scheme.tertiary;
      case NotificationType.orderCancelled:
        return scheme.onSurfaceVariant;
      case NotificationType.general:
        return scheme.primary;
    }
  }
}

class _NotificationMetric extends StatelessWidget {
  const _NotificationMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}
