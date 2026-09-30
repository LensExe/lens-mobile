import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/lens_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/data_providers.dart';

enum SettingsSection { profile, account, notifications }

class SettingsScreen extends ConsumerStatefulWidget {
  final SettingsSection section;
  const SettingsScreen({super.key, required this.section});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool bookingUpdates = true;
  bool messages = true;
  bool promotions = false;
  bool emailDigest = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: '090 123 4567');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.section) {
      SettingsSection.profile => 'Hồ sơ cá nhân',
      SettingsSection.account => 'Tài khoản & bảo mật',
      SettingsSection.notifications => 'Tuỳ chọn thông báo',
    };

    return LensPage(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(AppTokens.pillRadius),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  size: 18,
                  color: AppColors.obsidian,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: AppTypography.headlineSm(fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          12,
          AppTokens.pageHorizontal,
          40,
        ),
        children: [
          if (widget.section == SettingsSection.profile) _buildProfile(context),
          if (widget.section == SettingsSection.account) _buildAccount(context),
          if (widget.section == SettingsSection.notifications)
            _buildNotifications(context),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final initials = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'KH';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppColors.pebble),
            boxShadow: const [AppTokens.surfaceShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
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
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: AppTypography.headlineSm(
                          color: AppColors.ember,
                          fontSize: 24,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.obsidian,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.snow, width: 2),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 13,
                          color: AppColors.snow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Họ và tên',
                style: AppTypography.bodyMd(color: AppColors.obsidian).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LensTextField(
                controller: _nameController,
                hintText: 'Nhập họ và tên đầy đủ',
              ),
              const SizedBox(height: 18),
              Text(
                'Số điện thoại',
                style: AppTypography.bodyMd(color: AppColors.obsidian).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LensTextField(
                controller: _phoneController,
                hintText: '090 123 4567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Lưu thay đổi',
                height: 52,
                onPressed: () => _saved(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fog.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
            border: Border.all(color: AppColors.pebble),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 18, color: AppColors.steel),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thông tin này sẽ được điền tự động vào hợp đồng và biểu mẫu đặt lịch khi bạn liên hệ với nhiếp ảnh gia.',
                  style: AppTypography.bodySm(color: AppColors.steel).copyWith(
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccount(BuildContext context) {
    final user = ref.watch(authUserProvider);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppColors.pebble),
            boxShadow: const [AppTokens.surfaceShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingValue(
                label: 'Email đăng nhập',
                value: user?.email ?? 'customer@lens.com',
                icon: LucideIcons.mail,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppColors.pebble),
              ),
              const _SettingValue(
                label: 'Vai trò tài khoản',
                value: 'Khách hàng (Customer)',
                icon: LucideIcons.badgeCheck,
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () =>
                    _saved(context, 'Tính năng đổi mật khẩu sẽ sớm khả dụng.'),
                icon: const Icon(LucideIcons.keyRound, size: 16),
                label: Text(
                  'Đổi mật khẩu bảo vệ',
                  style: AppTypography.bodyMd(color: AppColors.obsidian).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.obsidian,
                  side: const BorderSide(color: AppColors.pebble),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppColors.pebble),
            boxShadow: const [AppTokens.surfaceShadow],
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: true,
            onChanged: (_) {},
            title: Text(
              'Xác thực 2 yếu tố (2FA)',
              style: AppTypography.bodyMd(color: AppColors.obsidian).copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Bảo vệ tài khoản với mã OTP khi đăng nhập từ thiết bị lạ.',
              style: AppTypography.labelSm(color: AppColors.steel),
            ),
            activeThumbColor: AppColors.snow,
            activeTrackColor: AppColors.emerald,
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      children: [
        _SwitchRow(
          title: 'Cập nhật lịch chụp',
          description: 'Nhận thông báo khi nhiếp ảnh gia xác nhận hoặc thay đổi trạng thái',
          value: bookingUpdates,
          onChanged: (value) => setState(() => bookingUpdates = value),
        ),
        const Divider(height: 1, color: AppColors.pebble),
        _SwitchRow(
          title: 'Tin nhắn trò chuyện',
          description: 'Thông báo tin nhắn mới từ nhiếp ảnh gia',
          value: messages,
          onChanged: (value) => setState(() => messages = value),
        ),
        const Divider(height: 1, color: AppColors.pebble),
        _SwitchRow(
          title: 'Ưu đãi & Chương trình quà tặng',
          description: 'Cập nhật voucher giảm giá và sự kiện chụp ảnh',
          value: promotions,
          onChanged: (value) => setState(() => promotions = value),
        ),
        const Divider(height: 1, color: AppColors.pebble),
        _SwitchRow(
          title: 'Bản tin tóm tắt qua Email',
          description: 'Tóm tắt các bộ ảnh hoàn thành và hoá đơn qua hòm thư',
          value: emailDigest,
          onChanged: (value) => setState(() => emailDigest = value),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Lưu cấu hình thông báo',
          height: 52,
          onPressed: () => _saved(context),
        ),
      ],
    ),
  );

  void _saved(BuildContext context, [String message = 'Đã lưu thay đổi thành công.']) {
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
  }
}

class _SettingValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SettingValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(AppTokens.nestedBadgeRadius),
        ),
        child: Icon(icon, size: 18, color: AppColors.obsidian),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSm(color: AppColors.steel),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.bodyMd(color: AppColors.obsidian).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMd(color: AppColors.obsidian).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: AppTypography.labelSm(color: AppColors.steel).copyWith(height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.snow,
          activeTrackColor: AppColors.ember,
          inactiveThumbColor: AppColors.snow,
          inactiveTrackColor: AppColors.pebble,
        ),
      ],
    ),
  );
}

