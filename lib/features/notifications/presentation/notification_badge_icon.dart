import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../data/notification_repository.dart';

class NotificationBadgeIcon extends ConsumerWidget {
  final String userId;
  const NotificationBadgeIcon({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () => context.push('/notifications'),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: NotificationRepository().streamNotifications(userId),
      builder: (context, snapshot) {
        final unread = (snapshot.data ?? []).where((n) => n['is_read'] != true).length;
        
        final iconWidget = unread == 0 
            ? const Icon(Icons.notifications)
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: SteampunkTheme.bloodRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );

        return IconButton(
          icon: iconWidget,
          onPressed: () => context.push('/notifications'),
        );
      },
    );
  }
}
