import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/notifications/widgets/notification_bell.dart';
import 'lens_logo.dart';

typedef CustomerAppBar = LensTabAppBar;

/// Shared top header for primary customer tabs mirroring the creator workspace header,
/// featuring the brand accent pill, LENS logo, notification bell, and user avatar.
class LensTabAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const LensTabAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.actions = const [],
    this.showNotification = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> actions;
  final bool showNotification;

  static const double height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'Khách hàng';
    final avatarUrl = user?.avatarUrl;

    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: const Color(0xFFF8F8F9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 12,
      automaticallyImplyLeading: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0x0D1A1C1D)),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3.5,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5A00),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const LensLogo(width: 44, height: 26),
        ],
      ),
      actions: [
        ?trailing,
        ...actions,
        if (showNotification)
          const NotificationBell(routePath: '/customer_home/notifications'),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 2),
          child: GestureDetector(
            onTap: () {
              if (user != null) {
                context.push('/customer_home/settings/profile');
              } else {
                context.push('/login');
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _HeaderAvatar(
                  name: displayName,
                  imageUrl: avatarUrl,
                  size: 32,
                ),
                if (user != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF8F8F9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.name,
    this.imageUrl,
    this.size = 32,
  });

  final String name;
  final String? imageUrl;
  final double size;

  ImageProvider? _resolveImage(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return null;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }
    return FileImage(File(clean));
  }

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initial = name.trim().isEmpty
        ? '?'
        : words.length == 1
        ? words.first.characters.first.toUpperCase()
        : '${words.first.characters.first}${words.last.characters.first}'
              .toUpperCase();
    final url = imageUrl?.trim() ?? '';
    final imageProvider = _resolveImage(url);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFFFF0EB),
      foregroundImage: imageProvider,
      onForegroundImageError: imageProvider == null ? null : (_, _) {},
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFFFF5A00),
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
