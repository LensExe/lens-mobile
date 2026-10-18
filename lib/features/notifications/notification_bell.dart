import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'notification_repository.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.routePath});

  final String routePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref
            .watch(notificationInboxProvider)
            .asData
            ?.value
            .where((notification) => !notification.isRead)
            .length ??
        0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: unreadCount == 0
              ? 'Thông báo'
              : 'Thông báo, $unreadCount chưa đọc',
          onPressed: () => context.push(routePath),
          icon: const Icon(Icons.notifications_outlined),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5A00),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
