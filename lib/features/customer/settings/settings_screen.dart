import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
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
      SettingsSection.notifications => 'Thông báo',
    };
    return LensPage(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          32,
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

  Widget _buildProfile(BuildContext context) => Column(
    children: [
      LensSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.fog,
                child: Icon(
                  LucideIcons.userRound,
                  size: 30,
                  color: AppColors.steel,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Họ và tên',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            LensTextField(
              controller: _nameController,
              hintText: 'Nguyễn Văn A',
            ),
            const SizedBox(height: 15),
            const Text(
              'Số điện thoại',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            LensTextField(
              controller: _phoneController,
              hintText: '090 123 4567',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              text: 'Lưu thay đổi',
              expand: false,
              onPressed: () => _saved(context),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      LensSectionCard(
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, size: 17, color: AppColors.steel),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Thông tin này sẽ được dùng để điền nhanh vào biểu mẫu đặt lịch. API hồ sơ thật sẽ được kết nối ở bước backend.',
                style: TextStyle(
                  color: AppColors.steel,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _buildAccount(BuildContext context) => Column(
    children: [
      LensSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SettingValue(
              label: 'Email đăng nhập',
              value: 'customer@lens.com',
            ),
            const Divider(height: 24),
            const _SettingValue(label: 'Vai trò', value: 'Khách hàng'),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () =>
                  _saved(context, 'Tính năng đổi mật khẩu sẽ sớm khả dụng.'),
              icon: const Icon(LucideIcons.keyRound, size: 16),
              label: const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      LensSectionCard(
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: true,
          onChanged: (_) {},
          title: const Text(
            'Bảo vệ tài khoản',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: const Text(
            'Phiên đăng nhập demo được bảo vệ.',
            style: TextStyle(color: AppColors.steel, fontSize: 11),
          ),
          activeThumbColor: AppColors.lagoon,
        ),
      ),
    ],
  );
  Widget _buildNotifications(BuildContext context) => LensSectionCard(
    child: Column(
      children: [
        _SwitchRow(
          title: 'Cập nhật lịch đặt',
          value: bookingUpdates,
          onChanged: (value) => setState(() => bookingUpdates = value),
        ),
        _SwitchRow(
          title: 'Tin nhắn mới',
          value: messages,
          onChanged: (value) => setState(() => messages = value),
        ),
        _SwitchRow(
          title: 'Ưu đãi từ Lens',
          value: promotions,
          onChanged: (value) => setState(() => promotions = value),
        ),
        _SwitchRow(
          title: 'Tóm tắt qua email',
          value: emailDigest,
          onChanged: (value) => setState(() => emailDigest = value),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          text: 'Lưu tuỳ chọn',
          expand: false,
          onPressed: () => _saved(context),
        ),
      ],
    ),
  );
  void _saved(BuildContext context, [String message = 'Đã lưu thay đổi.']) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _SettingValue extends StatelessWidget {
  final String label;
  final String value;
  const _SettingValue({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.steel, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ],
  );
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: onChanged,
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    activeThumbColor: AppColors.lagoon,
  );
}
