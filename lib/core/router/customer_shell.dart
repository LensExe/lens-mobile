import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_container.dart';

class CustomerShell extends ConsumerWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(conversationsProvider)
        .fold<int>(0, (sum, conversation) => sum + conversation.unreadCount);
    final selectedIndex = _calculateSelectedIndex(context);
    const destinations = [
      _NavDestination(LucideIcons.search, 'Khám phá'),
      _NavDestination(LucideIcons.house, 'Tổng quan'),
      _NavDestination(LucideIcons.calendarDays, 'Lịch đặt'),
      _NavDestination(LucideIcons.messageCircle, 'Tin nhắn'),
      _NavDestination(LucideIcons.menu, 'Khác'),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: GlassContainer.translucentBar(
        isTop: true,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
            child: Row(
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    child: _CustomerNavItem(
                      destination: destinations[index],
                      selected: selectedIndex == index,
                      unreadCount: index == 3 ? unread : 0,
                      onTap: () => _onItemTapped(index, context),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
    return 0;
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

class _NavDestination {
  final IconData icon;
  final String label;

  const _NavDestination(this.icon, this.label);
}

class _CustomerNavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  const _CustomerNavItem({
    required this.destination,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.obsidian : AppColors.steel;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 36,
                    height: 27,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.fog : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    ),
                    alignment: Alignment.center,
                    child: Icon(destination.icon, size: 19, color: iconColor),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.ember,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: AppTypography.numeric(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.snow,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSm(
                  color: iconColor,
                  fontSize: 10,
                ).copyWith(fontWeight: selected ? FontWeight.w700 : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
