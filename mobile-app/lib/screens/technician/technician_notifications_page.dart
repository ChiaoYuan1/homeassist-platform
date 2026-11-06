import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/homeassist_action_dialog.dart';
import 'technician_job_detail_page.dart';

class TechnicianNotificationsPage extends StatefulWidget {
  const TechnicianNotificationsPage({super.key});

  @override
  State<TechnicianNotificationsPage> createState() =>
      _TechnicianNotificationsPageState();
}

class _TechnicianNotificationsPageState
    extends State<TechnicianNotificationsPage> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  Future<void> _openNotification(NotificationModel notification) async {
    try {
      if (!notification.read) {
        await _notificationService.markRead(notification.id);
      }
      if (!mounted) return;

      final bookingId = notification.bookingId?.trim();
      if (bookingId != null && bookingId.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianJobDetailPage(bookingId: bookingId),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to open notification ${notification.id}: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Open Notification',
        message: 'This notification could not be opened. Please try again.',
        type: HomeAssistMessageType.error,
      );
    }
  }

  String _formatTime(DateTime? createdAt) {
    if (createdAt == null) return '';
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  IconData _notificationIcon(NotificationModel notification) {
    final text = '${notification.title} ${notification.message}'.toLowerCase();
    if (text.contains('assigned') || text.contains('booking')) {
      return Icons.assignment_outlined;
    }
    if (text.contains('appointment') || text.contains('upcoming')) {
      return Icons.schedule_outlined;
    }
    if (text.contains('completed')) return Icons.check_circle_outline;
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUserId;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: uid == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No authenticated technician account was found.',
              textAlign: TextAlign.center),
        ),
      )
          : StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.watchForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Unable to load notifications.',
                    textAlign: TextAlign.center),
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
                    Icon(Icons.notifications_none_rounded,
                        size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 14),
                    Text('No notifications yet', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Job assignments and service updates will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary)),
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
                notification: notification,
                time: _formatTime(notification.createdAt),
                icon: _notificationIcon(notification),
                onTap: () => _openNotification(notification),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.time,
    required this.icon,
    required this.onTap,
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
                    child: Icon(icon, color: AppTheme.primary),
                  ),
                  if (!notification.read)
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
                    Text(notification.title, style: TextStyle(
                      fontWeight: notification.read
                          ? FontWeight.w600 : FontWeight.w800,
                    )),
                    const SizedBox(height: 5),
                    Text(notification.message, style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    )),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(time, style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      )),
                    ],
                  ],
                ),
              ),
              if (notification.bookingId?.trim().isNotEmpty == true)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
