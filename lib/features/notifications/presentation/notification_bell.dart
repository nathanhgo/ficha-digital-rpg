import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/notification_repository.dart';
import 'notifications_tab.dart';
import '../../../core/theme/theme.dart';

class NotificationBell extends StatelessWidget {
  final String userId;
  final VoidCallback? onTap;

  const NotificationBell({super.key, required this.userId, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: NotificationRepository().streamNotifications(userId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => n['is_read'] != true).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: onTap ?? () {
                showNotificationsBottomSheet(context, userId);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: SteampunkTheme.bloodRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

void showNotificationsBottomSheet(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: SteampunkTheme.leatherBark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'NOTIFICAÇÕES',
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              color: SteampunkTheme.copper,
              fontSize: 18,
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(child: NotificationsTab(userId: userId)),
        ],
      ),
    ),
  );
}
