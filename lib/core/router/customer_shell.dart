import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';

class CustomerShell extends ConsumerWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(conversationsProvider)
        .fold<int>(0, (sum, conversation) => sum + conversation.unreadCount);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.search),
            label: 'Khám phá',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Tổng quan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendar),
            label: 'Lịch đặt',
          ),
          BottomNavigationBarItem(
            icon: _UnreadIcon(count: unread),
            label: 'Tin nhắn',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.menu),
            label: 'Khác',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/customer_home/discovery')) return 0;
    if (location.startsWith('/customer_home/overview')) return 1;
    if (location.startsWith('/customer_home/bookings')) return 2;
    if (location.startsWith('/customer_home/messages')) return 3;
    if (location.startsWith('/customer_home/more')) return 4;
    return 0; // Default to Discovery
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/customer_home/discovery');
        break;
      case 1:
        context.go('/customer_home/overview');
        break;
      case 2:
        context.go('/customer_home/bookings');
        break;
      case 3:
        context.go('/customer_home/messages');
        break;
      case 4:
        context.go('/customer_home/more');
        break;
    }
  }
}

class _UnreadIcon extends StatelessWidget {
  final int count;
  const _UnreadIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(LucideIcons.messageSquare),
        if (count > 0)
          Positioned(
            top: -5,
            right: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5A00),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
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
