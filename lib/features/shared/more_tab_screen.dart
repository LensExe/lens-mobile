import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/lens_page.dart';
import '../../providers/data_providers.dart';

class MoreTabScreen extends ConsumerWidget {
  const MoreTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    return LensPage(
      appBar: AppBar(title: const Text('Tùy chọn khác')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          12,
          AppTokens.pageHorizontal,
          32,
        ),
        children: [
          LensSectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.fog,
                  child: const Icon(
                    LucideIcons.userRound,
                    color: AppColors.steel,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Khách hàng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? 'Đăng nhập để đồng bộ lịch chụp',
                        style: const TextStyle(
                          color: AppColors.steel,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.steel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MenuSection(
            title: 'Không gian của tôi',
            items: [
              _MenuItem(
                icon: LucideIcons.walletCards,
                title: 'Ví của tôi',
                subtitle: 'Quản lý Lens Xu',
                onTap: () => context.push('/customer_home/wallet'),
              ),
              _MenuItem(
                icon: LucideIcons.star,
                title: 'Đánh giá của tôi',
                subtitle: 'Chia sẻ trải nghiệm sau buổi chụp',
                onTap: () => context.push('/customer_home/reviews'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MenuSection(
            title: 'Cài đặt tài khoản',
            items: [
              _MenuItem(
                icon: LucideIcons.userRound,
                title: 'Hồ sơ cá nhân',
                subtitle: 'Thông tin dùng cho đặt lịch',
                onTap: () => context.push('/customer_home/settings/profile'),
              ),
              _MenuItem(
                icon: LucideIcons.shieldCheck,
                title: 'Tài khoản & bảo mật',
                subtitle: 'Mật khẩu và thiết bị đăng nhập',
                onTap: () => context.push('/customer_home/settings/account'),
              ),
              _MenuItem(
                icon: LucideIcons.bell,
                title: 'Thông báo',
                subtitle: 'Tuỳ chỉnh thông báo lịch đặt',
                onTap: () =>
                    context.push('/customer_home/settings/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MenuSection(
            title: 'Hỗ trợ',
            items: [
              _MenuItem(
                icon: LucideIcons.circleHelp,
                title: 'Trung tâm trợ giúp',
                subtitle: 'Lens Care sẽ hỗ trợ bạn sớm nhất',
                onTap: () =>
                    _showMessage(context, 'Lens Care sẽ hỗ trợ bạn sớm nhất.'),
              ),
              _MenuItem(
                icon: LucideIcons.shield,
                title: 'Chính sách bảo mật',
                subtitle: 'Tìm hiểu cách Lens bảo vệ dữ liệu',
                onTap: () => _showMessage(
                  context,
                  'Chính sách bảo mật sẽ sớm khả dụng.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(LucideIcons.logOut, size: 17),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              side: const BorderSide(color: AppColors.destructive),
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Lens · phiên bản 1.0.0',
              style: TextStyle(color: AppColors.steel, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      ref.read(authUserProvider.notifier).setUser(null);
      context.go('/login');
    }
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.steel,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      LensSectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              items[i],
              if (i < items.length - 1)
                const Divider(height: 1, indent: 54, endIndent: 16),
            ],
          ],
        ),
      ),
    ],
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: AppColors.obsidian),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: AppColors.steel, fontSize: 11),
    ),
    trailing: const Icon(
      LucideIcons.chevronRight,
      size: 17,
      color: AppColors.steel,
    ),
  );
}
