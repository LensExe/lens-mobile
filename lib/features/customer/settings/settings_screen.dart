import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/lens_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/customer_avatar.dart';
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
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  bool _isSavingProfile = false;
  bool _isSavingAvatar = false;

  Future<void> _pickAvatar() async {
    if (_isSavingAvatar) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;
      setState(() => _isSavingAvatar = true);
      await ref.read(authUserProvider.notifier).updateAvatar(image.path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh đại diện')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật ảnh đại diện')),
      );
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final address = _addressController.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên hợp lệ')),
      );
      return;
    }
    if (!RegExp(r'^(0|\+84)\d{8,10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại Việt Nam không hợp lệ')),
      );
      return;
    }
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tỉnh hoặc thành phố')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await ref
          .read(authUserProvider.notifier)
          .updateProfile(
            name: name,
            phone: phone,
            city: city,
            address: address,
            saveAsDefault: true,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hồ sơ cá nhân thành công!'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu thay đổi, vui lòng thử lại'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.section) {
      SettingsSection.profile => 'Hồ sơ cá nhân & Địa chỉ',
      SettingsSection.account => 'Tài khoản & Bảo mật',
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
        title: Text(title, style: AppTypography.headlineSm(fontSize: 18)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
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

  // FLOW 16: Profile & Default Address
  Widget _buildProfile(BuildContext context) {
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
                      width: 80,
                      height: 80,
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
                      child: CustomerAvatar(
                        url: user?.avatarUrl ?? '',
                        initials: initials,
                        size: 80,
                        fallbackStyle: AppTypography.headlineSm(
                          color: AppColors.ember,
                          fontSize: 26,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isSavingAvatar ? null : _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.obsidian,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.snow, width: 2),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            size: 14,
                            color: AppColors.snow,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Họ và tên',
                style: AppTypography.bodyMd(color: AppColors.obsidian)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LensTextField(
                controller: _nameController,
                hintText: 'Nhập họ và tên đầy đủ',
              ),
              const SizedBox(height: 16),
              Text(
                'Số điện thoại liên hệ',
                style: AppTypography.bodyMd(color: AppColors.obsidian)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LensTextField(
                controller: _phoneController,
                hintText: '090 123 4567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Text(
                'Tỉnh / Thành phố mặc định',
                style: AppTypography.bodyMd(color: AppColors.obsidian)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LensTextField(
                controller: _cityController,
                hintText: 'TP. Hồ Chí Minh, Hà Nội, Đà Nẵng...',
              ),
              const SizedBox(height: 16),
              Text(
                'Địa chỉ chi tiết mặc định',
                style: AppTypography.bodyMd(color: AppColors.obsidian)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LensTextField(
                controller: _addressController,
                hintText: 'Số nhà, tên đường, phường/xã, quận/huyện',
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Lưu thay đổi hồ sơ',
                height: 52,
                isLoading: _isSavingProfile,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fog,
            borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
            border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 18, color: AppColors.steel),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thông tin và địa chỉ mặc định này sẽ được tự động điền vào Bước 2 của Quy trình đặt lịch chụp (Booking Wizard).',
                  style: AppTypography.bodySm(color: AppColors.steel)
                      .copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // FLOW 17: Account & Security
  Widget _buildAccount(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);

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
                label: 'Email tài khoản',
                value: user?.email ?? 'customer@lens.com',
                icon: LucideIcons.mail,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppColors.pebble),
              ),
              const _SettingValue(
                label: 'Loại tài khoản',
                value: 'Khách hàng (Client)',
                icon: LucideIcons.badgeCheck,
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => _openChangePasswordDialog(context),
                icon: const Icon(LucideIcons.keyRound, size: 16),
                label: Text(
                  'Đổi mật khẩu bảo vệ',
                  style: AppTypography.bodyMd(color: AppColors.obsidian)
                      .copyWith(fontWeight: FontWeight.w600),
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
        const SizedBox(height: 18),

        // Active Sessions List
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppColors.pebble),
            boxShadow: const [AppTokens.surfaceShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phiên đăng nhập đang hoạt động',
                    style: AppTypography.titleMd(color: AppColors.obsidian),
                  ),
                  TextButton(
                    onPressed: () => _revokeAllOther(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: Text(
                      'Đăng xuất các thiết bị khác',
                      style: AppTypography.labelSm(color: AppColors.crimson),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              sessionsAsync.when(
                data: (sessions) => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16, color: AppColors.pebble),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: session.isCurrent
                                ? AppColors.emerald.withValues(alpha: 0.12)
                                : AppColors.fog,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            session.isCurrent
                                ? LucideIcons.smartphone
                                : LucideIcons.laptop,
                            size: 16,
                            color: session.isCurrent
                                ? AppColors.emerald
                                : AppColors.steel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      session.deviceName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMd(
                                        fontSize: 13,
                                        color: AppColors.obsidian,
                                      ),
                                    ),
                                  ),
                                  if (session.isCurrent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          9999,
                                        ),
                                      ),
                                      child: Text(
                                        'Thiết bị này',
                                        style: AppTypography.labelSm(
                                          fontSize: 9.5,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${session.location} · ${session.lastActive}',
                                style: AppTypography.labelSm(
                                  fontSize: 11,
                                  color: AppColors.steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!session.isCurrent)
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppColors.steel,
                            ),
                            onPressed: () =>
                                _revokeSession(context, session.id),
                            tooltip: 'Đăng xuất',
                          ),
                      ],
                    );
                  },
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: AppColors.ember),
                  ),
                ),
                error: (e, _) => Text('Không thể tải phiên: $e'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // FLOW 18: Notification Preferences
  Widget _buildNotifications(BuildContext context) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return Container(
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
            title: 'Thông báo đặt lịch qua Email',
            description: 'Nhận thông báo khi thợ chụp nhận lịch hoặc cập nhật tiến độ hợp đồng',
            value: prefs.emailBooking,
            onChanged: (value) {
              notifier.update(emailBooking: value);
              _notifySaved('Đã cập nhật tuỳ chọn email đặt lịch');
            },
          ),
          const Divider(height: 1, color: AppColors.pebble),
          _SwitchRow(
            title: 'Thông báo tin nhắn mới qua Email',
            description:
                'Gửi bản tóm tắt qua email khi có tin nhắn chưa đọc từ thợ ảnh',
            value: prefs.emailMessage,
            onChanged: (value) {
              notifier.update(emailMessage: value);
              _notifySaved('Đã cập nhật tuỳ chọn email tin nhắn');
            },
          ),
          const Divider(height: 1, color: AppColors.pebble),
          _SwitchRow(
            title: 'Thông báo nhắc lịch qua SMS',
            description:
                'Nhận tin nhắn SMS nhắc trước 24 giờ diễn ra buổi chụp thực tế',
            value: prefs.smsReminder,
            onChanged: (value) {
              notifier.update(smsReminder: value);
              _notifySaved('Đã cập nhật tuỳ chọn SMS nhắc lịch');
            },
          ),
          const Divider(height: 1, color: AppColors.pebble),
          _SwitchRow(
            title: 'Cập nhật tin khuyến mãi & hoàn Lens Xu',
            description: 'Nhận thông báo khi có ưu đãi hoàn xu 5% và chiến dịch voucher mới',
            value: prefs.promoCashback,
            onChanged: (value) {
              notifier.update(promoCashback: value);
              _notifySaved('Đã cập nhật tuỳ chọn khuyến mãi');
            },
          ),
        ],
      ),
    );
  }

  void _notifySaved(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  void _openChangePasswordDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  Future<void> _revokeSession(BuildContext context, String sessionId) async {
    await ref.read(activeSessionsProvider.notifier).revokeSession(sessionId);
    if (!mounted || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã đăng xuất phiên này')));
  }

  Future<void> _revokeAllOther(BuildContext context) async {
    await ref.read(activeSessionsProvider.notifier).revokeAllOther();
    if (!mounted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất khỏi tất cả các thiết bị khác'),
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu hiện tại');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _error = 'Mật khẩu mới phải có tối thiểu 8 ký tự');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Xác nhận mật khẩu mới không trùng khớp');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      await ref
          .read(authUserProvider.notifier)
          .changePassword(currentPassword: current, newPassword: newPass);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đổi mật khẩu thành công!'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Đổi mật khẩu tài khoản',
        style: AppTypography.titleMd(color: AppColors.obsidian, fontSize: 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: AppTypography.bodySm(
                    color: AppColors.crimson,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text('Mật khẩu hiện tại', style: AppTypography.labelSm()),
            const SizedBox(height: 6),
            LensTextField(
              controller: _currentController,
              hintText: 'Nhập mật khẩu hiện tại',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            Text(
              'Mật khẩu mới (tối thiểu 8 ký tự)',
              style: AppTypography.labelSm(),
            ),
            const SizedBox(height: 6),
            LensTextField(
              controller: _newController,
              hintText: 'Tối thiểu 8 ký tự',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            Text('Xác nhận mật khẩu mới', style: AppTypography.labelSm()),
            const SizedBox(height: 6),
            LensTextField(
              controller: _confirmController,
              hintText: 'Nhập lại mật khẩu mới',
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Huỷ',
            style: AppTypography.labelMd(color: AppColors.steel),
          ),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ember,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu mật khẩu mới'),
        ),
      ],
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.steel),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSm(color: AppColors.steel)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd(color: AppColors.obsidian)
                  .copyWith(fontWeight: FontWeight.w600),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMd(color: AppColors.obsidian)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySm(color: AppColors.steel)
                      .copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeTrackColor: AppColors.ember,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
