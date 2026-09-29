import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class CustomerShell extends StatelessWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.obsidian,
        unselectedItemColor: AppColors.steel,
        backgroundColor: AppColors.snow,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'Khám phá'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Lịch đặt'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.menu), label: 'Khác'),
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
