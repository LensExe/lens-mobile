import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/lens_page.dart';
import '../../core/widgets/customer_avatar.dart';
import '../../providers/data_providers.dart';

class MoreTabScreen extends ConsumerWidget {
  const MoreTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final initials = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'KH';

    return LensPage(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Tài khoản & Thiết lập',
          style: AppTypography.headlineSm(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          40,
        ),
        children: [
          // User Profile Card
          InkWell(
            onTap: () => context.push('/customer_home/settings/profile'),
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                border: Border.all(color: AppColors.pebble),
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.ember.withValues(alpha: 0.15),
                          AppColors.ember.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ember.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: CustomerAvatar(
                      url: user?.avatarUrl ?? '',
                      initials: initials,
                      size: 56,
                      fallbackStyle: AppTypography.headlineSm(
                        color: AppColors.ember,
                        fontSize: 20,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'Khách hàng',
                                style: AppTypography.titleMd(
                                  color: AppColors.obsidian,
                                  fontSize: 17,
                                ).copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.check,
                                size: 10,
                                color: AppColors.snow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? 'customer@lens.com',
                          style: AppTypography.labelSm(color: AppColors.steel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.fog,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Không gian của tôi
          _MenuSection(
            title: 'KHÔNG GIAN CỦA TÔI',
            items: [
              _MenuItem(
                icon: LucideIcons.walletCards,
                iconColor: AppColors.ember,
                title: 'Ví của tôi',
                subtitle: 'Quản lý số dư LENS Xu & Nạp tiền',
                onTap: () => context.push('/customer_home/wallet'),
              ),
              _MenuItem(
                icon: LucideIcons.star,
                iconColor: AppColors.warning,
                title: 'Đánh giá đã gửi',
                subtitle: 'Xem lại feedback và trải nghiệm chụp',
                onTap: () => context.push('/customer_home/reviews'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 2: Cài đặt tài khoản
          _MenuSection(
            title: 'CÀI ĐẶT TÀI KHOẢN',
            items: [
              _MenuItem(
                icon: LucideIcons.userRound,
                title: 'Hồ sơ cá nhân',
                subtitle: 'Họ tên, số điện thoại dùng cho đặt lịch',
                onTap: () => context.push('/customer_home/settings/profile'),
              ),
              _MenuItem(
                icon: LucideIcons.shieldCheck,
                title: 'Tài khoản & bảo mật',
                subtitle: 'Mật khẩu bảo vệ và xác thực 2FA',
                onTap: () => context.push('/customer_home/settings/account'),
              ),
              _MenuItem(
                icon: LucideIcons.bell,
                title: 'Tuỳ chọn thông báo',
                subtitle: 'Cập nhật tiến độ lịch chụp & ưu đãi',
                onTap: () =>
                    context.push('/customer_home/settings/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 3: Hỗ trợ & Chính sách
          _MenuSection(
            title: 'HỖ TRỢ & BẢO MẬT',
            items: [
              _MenuItem(
                icon: LucideIcons.headphones,
                title: 'Trung tâm trợ giúp Lens Care',
                subtitle: 'Hỗ trợ khách hàng 24/7 và giải quyết khiếu nại',
                onTap: () => _showMessage(
                  context,
                  'Tổng đài Lens Care sẽ kết nối trong giây lát.',
                ),
              ),
              _MenuItem(
                icon: LucideIcons.fileText,
                title: 'Chính sách bảo vệ quyền lợi Escrow',
                subtitle: 'Quy trình giải ngân an toàn cho khách hàng',
                onTap: () => _showMessage(
                  context,
                  'Chính sách bảo vệ Escrow đã được cập nhật phiên bản mới nhất.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Logout Action
          InkWell(
            onTap: () => _confirmLogout(context, ref),
            borderRadius: BorderRadius.circular(AppTokens.pillRadius),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.logOut,
                    size: 18,
                    color: AppColors.crimson,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đăng xuất tài khoản',
                    style: AppTypography.bodyMd(color: AppColors.crimson)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Version Footer
          Center(
            child: Text(
              'LENS Mobile Marketplace · Phiên bản 1.0.0',
              style: AppTypography.numeric(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.steel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodySm(color: AppColors.snow),
          ),
          backgroundColor: AppColors.obsidian,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.nestedBadgeRadius),
          ),
        ),
      );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.snow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        ),
        title: Text(
          'Đăng xuất tài khoản?',
          style: AppTypography.titleMd(fontSize: 18)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục quản lý lịch chụp và số dư ví.',
          style: AppTypography.bodySm(color: AppColors.steel),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ctx.pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.obsidian,
                    side: const BorderSide(color: AppColors.pebble),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    'Huỷ',
                    style: AppTypography.labelMd(color: AppColors.obsidian)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ctx.pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: AppColors.snow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    'Đăng xuất',
                    style: AppTypography.labelMd(color: AppColors.snow)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      await ref.read(authUserProvider.notifier).logout();
      if (context.mounted) {
        context.go('/customer_home/discovery');
      }
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
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: AppTypography.labelMd(
            color: AppColors.steel,
            fontSize: 11,
          ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 58,
                    endIndent: 16,
                    color: AppColors.pebble,
                  ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor != null
                  ? iconColor!.withValues(alpha: 0.1)
                  : AppColors.fog,
              borderRadius: BorderRadius.circular(AppTokens.nestedBadgeRadius),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.obsidian),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMd(color: AppColors.obsidian)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelSm(
                    color: AppColors.steel,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: AppColors.steel,
          ),
        ],
      ),
    ),
  );
}
