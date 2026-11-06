import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/homeassist_action_dialog.dart';

class ProviderNotificationsPage extends StatelessWidget {
  const ProviderNotificationsPage({super.key});

  String _formatTime(DateTime? createdAt) {
    if (createdAt == null) return 'Just now';

    final difference = DateTime.now().difference(createdAt);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays == 1) return 'Yesterday';

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  IconData _notificationIcon(NotificationModel notification) {
    final message = '${notification.title} ${notification.message}'.toLowerCase();

    if (message.contains('completed')) {
      return Icons.check_circle_outline;
    }

    if (message.contains('appointment') || message.contains('schedule')) {
      return Icons.schedule_outlined;
    }

    if (message.contains('booking') || message.contains('request')) {
      return Icons.add_alert_outlined;
    }

    return Icons.notifications_outlined;
  }

  Future<void> _markNotificationRead(
      BuildContext context,
      NotificationModel notification,
      ) async {
    if (notification.read) return;

    try {
      await AppServices.notifications.markRead(notification.id);
    } catch (error, stackTrace) {
      debugPrint('Unable to mark notification ${notification.id} as read: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Update Notification',
        message: 'Unable to mark this notification as read. Please try again.',
        type: HomeAssistMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = AppServices.auth.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: userId == null
          ? const Center(
        child: Text('Please sign in to view notifications.'),
      )
          : StreamBuilder<List<NotificationModel>>(
        stream: AppServices.notifications.watchForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load notifications.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'New booking requests and business updates '
                          'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationCard(
                icon: _notificationIcon(notification),
                title: notification.title,
                message: notification.message,
                time: _formatTime(notification.createdAt),
                unread: !notification.read,
                onTap: () => _markNotificationRead(
                  context,
                  notification,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool unread;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.onTap,
    this.unread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
                    child: Icon(
                      icon,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (unread)
                    const Positioned(
                      right: -1,
                      top: -1,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: AppTheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                        unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
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
}
