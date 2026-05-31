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
            : Badge(
                label: Text('$unread', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                backgroundColor: SteampunkTheme.bloodRed,
                child: const Icon(Icons.notifications),
              );

        return IconButton(
          icon: iconWidget,
          onPressed: () => context.push('/notifications'),
        );
      },
    );
  }
}
