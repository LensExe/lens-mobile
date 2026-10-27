import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/lens_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/customer_avatar.dart';
import '../../../providers/data_providers.dart';
import '../../../domain/models/customer_notification_preferences.dart';

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
  String _gender = '';
  String _dateOfBirth = '';
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isLoadingProfile = false;
  String? _profileLoadError;
  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _gender = user?.gender ?? '';
    _dateOfBirth = user?.dateOfBirth ?? '';
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
      _gender = user.gender;
      _dateOfBirth = user.dateOfBirth;
      setState(() => _profileLoadError = null);
    } catch (error) {
      if (mounted) setState(() => _profileLoadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2400,
      );
      if (image == null || !mounted) return;
      setState(() => _isUploadingAvatar = true);
      await ref.read(authUserProvider.notifier).updateAvatar(image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện.'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không cập nhật được ảnh đại diện: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
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
    if (phone.isNotEmpty && !RegExp(r'^(0|\+84)\d{8,10}$').hasMatch(phone)) {
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
            gender: _gender,
            dateOfBirth: _dateOfBirth,
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

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final storedDate = DateTime.tryParse(_dateOfBirth);
    final initialDate = storedDate != null && !storedDate.isAfter(today)
        ? storedDate
        : DateTime(now.year - 18, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Chọn ngày sinh',
    );
    if (selected == null || !mounted) return;
    setState(() => _dateOfBirth = DateFormat('yyyy-MM-dd').format(selected));
  }

  String _dateOfBirthLabel() {
    final date = DateTime.tryParse(_dateOfBirth);
    return date == null
        ? 'Chọn ngày sinh'
        : DateFormat('dd/MM/yyyy').format(date);
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
                child: Stack(
                  clipBehavior: Clip.none,
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
                      child: _isUploadingAvatar
                          ? const SizedBox.square(
                              dimension: 26,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : CustomerAvatar(
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
                      right: -4,
                      bottom: -2,
                      child: Material(
                        color: AppColors.obsidian,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _isUploadingAvatar ? null : _changeAvatar,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              LucideIcons.camera,
                              color: AppColors.snow,
                              size: 15,
                            ),
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
                'Ngày sinh',
                style: AppTypography.bodyMd(color: AppColors.obsidian)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectDateOfBirth,
                icon: const Icon(LucideIcons.calendarDays, size: 17),
                label: Text(_dateOfBirthLabel()),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.obsidian,
                  side: const BorderSide(color: AppColors.pebble),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppTokens.inputFieldRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Giới tính',
                style: AppTypography.bodyMd(color: AppColors.obsidian)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTokens.inputFieldRadius,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Chưa chọn')),
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? ''),
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
  Widget _buildNotifications(BuildContext context) {
    final preferences = ref.watch(customerNotificationPreferencesProvider);
    return preferences.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        children: [
          _backendCapabilityNote('Không tải được tùy chọn thông báo: $error'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.invalidate(customerNotificationPreferencesProvider),
            child: const Text('Thử tải lại'),
          ),
        ],
      ),
      data: (value) => _NotificationPreferencesSettings(preferences: value),
    );
  }

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

class _NotificationPreferencesSettings extends ConsumerStatefulWidget {
  const _NotificationPreferencesSettings({required this.preferences});

  final CustomerNotificationPreferences preferences;

  @override
  ConsumerState<_NotificationPreferencesSettings> createState() =>
      _NotificationPreferencesSettingsState();
}

class _NotificationPreferencesSettingsState
    extends ConsumerState<_NotificationPreferencesSettings> {
  bool _isSaving = false;

  Future<void> _save(CustomerNotificationPreferences updated) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(customerNotificationPreferencesProvider.notifier)
          .updatePreferences(updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được tùy chọn thông báo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      children: [
        _preference(
          title: 'Cập nhật lịch đặt',
          subtitle: 'Xác nhận, thay đổi và trạng thái booking.',
          value: widget.preferences.bookingUpdates,
          onChanged: (value) =>
              _save(widget.preferences.copyWith(bookingUpdates: value)),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _preference(
          title: 'Tin nhắn',
          subtitle: 'Báo khi có tin nhắn mới trong cuộc hội thoại.',
          value: widget.preferences.messages,
          onChanged: (value) =>
              _save(widget.preferences.copyWith(messages: value)),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _preference(
          title: 'Ưu đãi và tin sản phẩm',
          subtitle: 'Thông tin chương trình và tính năng mới.',
          value: widget.preferences.promotions,
          onChanged: (value) =>
              _save(widget.preferences.copyWith(promotions: value)),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _preference(
          title: 'Tóm tắt qua email',
          subtitle: 'Email tổng hợp hoạt động định kỳ.',
          value: widget.preferences.emailDigest,
          onChanged: (value) =>
              _save(widget.preferences.copyWith(emailDigest: value)),
        ),
        if (_isSaving) const LinearProgressIndicator(minHeight: 2),
      ],
    ),
  );

  Widget _preference({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    title: Text(
      title,
      style: AppTypography.bodyMd(color: AppColors.obsidian)
          .copyWith(fontWeight: FontWeight.w600),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        subtitle,
        style: AppTypography.bodySm(color: AppColors.steel),
      ),
    ),
    value: value,
    activeThumbColor: AppColors.ember,
    onChanged: _isSaving ? null : onChanged,
  );
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
