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
  bool _isSavingProfile = false;
  bool _isLoadingProfile = false;
  String? _profileLoadError;
  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    if (widget.section == SettingsSection.profile) {
      _isLoadingProfile = true;
      Future<void>.microtask(_refreshCurrentProfile);
    }
  }

  Future<void> _refreshCurrentProfile() async {
    try {
      final user = await ref.read(authUserProvider.notifier).refreshProfile();
      if (!mounted) return;
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _cityController.text = user.city;
      setState(() => _profileLoadError = null);
    } catch (error) {
      if (mounted) setState(() => _profileLoadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isLoadingProfile) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) return;

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
            address: currentUser.address,
            saveAsDefault: currentUser.saveAsDefault,
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
        if (_profileLoadError != null) ...[
          _backendCapabilityNote(
            'Không tải được hồ sơ hiện tại từ Backend: $_profileLoadError',
          ),
          const SizedBox(height: 14),
        ],
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
                child: Container(
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fog,
                  borderRadius: BorderRadius.circular(
                    AppTokens.inputFieldRadius,
                  ),
                ),
                child: Text(
                  'Backend hiện chưa hỗ trợ lưu địa chỉ chi tiết mặc định. '
                  'Bạn có thể nhập địa chỉ riêng ở bước đặt lịch.',
                  style: AppTypography.bodySm(color: AppColors.steel)
                      .copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Lưu thay đổi hồ sơ',
                height: 52,
                isLoading: _isSavingProfile,
                onPressed: _isLoadingProfile ? null : _saveProfile,
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
                  'Họ tên, số điện thoại và tỉnh/thành phố được lưu với Backend '
                  'và tự động điền vào bước đặt lịch. Địa chỉ chi tiết được nhập '
                  'riêng cho từng booking.',
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
                value: user?.email ?? '—',
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
                onPressed: () =>
                    context.push('/customer_home/settings/email-verification'),
                icon: const Icon(LucideIcons.mailCheck, size: 16),
                label: Text(
                  'Xác minh email',
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
              const SizedBox(height: 10),
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

        _backendCapabilityNote(
          'Backend hiện chưa cung cấp API xem hoặc thu hồi các phiên đăng nhập khác.',
        ),
      ],
    );
  }

  // FLOW 18: Notification Preferences
  Widget _buildNotifications(BuildContext context) => _backendCapabilityNote(
    'Backend hiện chưa có API đọc hoặc cập nhật tùy chọn thông báo. Các lựa chọn chưa được lưu đã được ẩn.',
  );

  Widget _backendCapabilityNote(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.info, size: 18, color: AppColors.steel),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm(color: AppColors.steel)
                .copyWith(height: 1.45),
          ),
        ),
      ],
    ),
  );

  void _openChangePasswordDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
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
